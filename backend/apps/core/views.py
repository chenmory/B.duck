import json
from functools import wraps

from django.conf import settings
from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.core import signing
from django.core.paginator import Paginator
from django.http import JsonResponse
from django.shortcuts import get_object_or_404, render
from django.utils import timezone
from django.views.decorators.csrf import csrf_exempt

from .models import (
    Alert,
    ChildProfile,
    Conversation,
    DailyUsageStats,
    Device,
    Feedback,
    LegalDocument,
    ParentProfile,
    SafetySettings,
    UsageSettings,
)
from .serializers import (
    alert_to_dict,
    child_to_dict,
    conversation_to_dict,
    device_to_dict,
    feedback_to_dict,
    legal_to_dict,
    parent_to_dict,
    safety_to_dict,
    usage_stats_to_dict,
    usage_to_dict,
)
from .services import create_chat_conversation, ensure_demo_family, parse_public_id, today_summary


def ok(data=None, request_id="req_ok"):
    return JsonResponse({"code": 0, "message": "ok", "data": data, "requestId": request_id}, json_dumps_params={"ensure_ascii": False})


def fail(message, code=40001, status=400, request_id="req_error"):
    return JsonResponse({"code": code, "message": message, "data": None, "requestId": request_id}, status=status, json_dumps_params={"ensure_ascii": False})


def body_json(request):
    if not request.body:
        return {}
    try:
        return json.loads(request.body.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        return {}


def make_token(parent_id, token_type):
    return signing.dumps({"parent_id": parent_id, "type": token_type, "iat": timezone.now().timestamp()}, salt="yellow-duck-auth")


def read_token(request):
    header = request.headers.get("Authorization", "")
    if not header.startswith("Bearer "):
        return None
    return header.replace("Bearer ", "", 1).strip()


def get_parent_from_token(token, token_type="access", max_age=None):
    if not token:
        return None
    max_age = max_age or settings.API_TOKEN_MAX_AGE_SECONDS
    try:
        payload = signing.loads(token, salt="yellow-duck-auth", max_age=max_age)
    except signing.BadSignature:
        return None
    if payload.get("type") != token_type:
        return None
    return ParentProfile.objects.filter(pk=payload.get("parent_id")).first()


def require_auth(view_func):
    @wraps(view_func)
    def wrapper(request, *args, **kwargs):
        parent = get_parent_from_token(read_token(request))
        if not parent:
            return fail("未登录或 Token 已失效", code=40100, status=401)
        request.parent_profile = parent
        return view_func(request, *args, **kwargs)

    return wrapper


def parse_date(value):
    if not value:
        return timezone.localdate()
    try:
        return timezone.datetime.strptime(value, "%Y-%m-%d").date()
    except ValueError:
        return timezone.localdate()


def first_child(parent):
    return parent.children.order_by("id").first()


def first_device(child):
    return child.devices.order_by("id").first()


def public_chat_page(request):
    return render(request, "chat/index.html")


@csrf_exempt
def login(request):
    if request.method != "POST":
        return fail("Method not allowed", status=405)
    payload = body_json(request)
    account = payload.get("account", "").strip()
    password = payload.get("password", "").strip()
    if not account or not password:
        return fail("账号和密码不能为空")

    if not User.objects.filter(username=account).exists():
        ensure_demo_family(account=account, password=password)

    user = authenticate(username=account, password=password)
    if not user:
        return fail("账号或密码错误", code=40100, status=401)

    parent, _, _ = ensure_demo_family(account=account, password=password)
    access_token = make_token(parent.id, "access")
    refresh_token = make_token(parent.id, "refresh")
    return ok(
        {
            "accessToken": access_token,
            "refreshToken": refresh_token,
            "expiresIn": settings.API_TOKEN_MAX_AGE_SECONDS,
            "user": parent_to_dict(parent),
        },
        "req_login",
    )


@csrf_exempt
def refresh_token(request):
    payload = body_json(request)
    parent = get_parent_from_token(payload.get("refreshToken"), token_type="refresh", max_age=60 * 60 * 24 * 30)
    if not parent:
        return fail("Refresh Token 无效", code=40100, status=401)
    return ok(
        {
            "accessToken": make_token(parent.id, "access"),
            "refreshToken": make_token(parent.id, "refresh"),
            "expiresIn": settings.API_TOKEN_MAX_AGE_SECONDS,
        },
        "req_refresh",
    )


@csrf_exempt
@require_auth
def logout(request):
    return ok(None, "req_logout")


@require_auth
def me(request):
    return ok(parent_to_dict(request.parent_profile), "req_me")


@require_auth
def dashboard_today(request):
    parent = request.parent_profile
    child = first_child(parent)
    if not child:
        return fail("当前账号未绑定孩子", code=40400, status=404)
    device = first_device(child)
    if not device:
        return fail("当前孩子未绑定设备", code=40400, status=404)
    date = parse_date(request.GET.get("date"))
    stats, _ = DailyUsageStats.objects.get_or_create(child=child, date=date)
    return ok(
        {
            "greeting": "晚上好" if timezone.localtime().hour >= 18 else "你好",
            "todaySummary": today_summary(child),
            "device": device_to_dict(device, brief=True),
            "usage": usage_stats_to_dict(stats),
            "attentionCount": Conversation.objects.filter(child=child, started_at__date=date).exclude(risk_level="normal").count(),
        },
        "req_dashboard",
    )


@csrf_exempt
@require_auth
def children(request):
    parent = request.parent_profile
    if request.method == "GET":
        return ok([child_to_dict(child) for child in parent.children.order_by("id")], "req_children")
    return fail("Method not allowed", status=405)


@csrf_exempt
@require_auth
def child_detail(request, child_id):
    child_pk = parse_public_id(child_id, "child_")
    child = get_object_or_404(ChildProfile, pk=child_pk, parent=request.parent_profile)
    if request.method == "GET":
        return ok(child_to_dict(child), "req_child_detail")
    if request.method == "PUT":
        payload = body_json(request)
        child.nickname = payload.get("nickname", child.nickname)
        child.age = payload.get("age", child.age)
        child.gender = payload.get("gender", child.gender)
        child.interests = payload.get("interests", child.interests)
        child.focus_areas = payload.get("focusAreas", child.focus_areas)
        child.save()
        return ok(child_to_dict(child), "req_child_update")
    return fail("Method not allowed", status=405)


@csrf_exempt
@require_auth
def devices(request):
    parent = request.parent_profile
    child_id = parse_public_id(request.GET.get("childId"), "child_")
    children_qs = parent.children.all()
    if child_id:
        children_qs = children_qs.filter(pk=child_id)
    devices_qs = Device.objects.filter(child__in=children_qs).order_by("id")
    return ok([device_to_dict(device) for device in devices_qs], "req_devices")


@csrf_exempt
@require_auth
def device_detail(request, device_id):
    device_pk = parse_public_id(device_id, "duck_")
    device = get_object_or_404(Device, pk=device_pk, child__parent=request.parent_profile)
    if request.method == "GET":
        return ok(device_to_dict(device), "req_device_detail")
    if request.method == "PATCH":
        payload = body_json(request)
        for field, attr in [("name", "name"), ("volume", "volume"), ("voiceName", "voice_name")]:
            if field in payload:
                setattr(device, attr, payload[field])
        device.save()
        return ok(device_to_dict(device), "req_device_update")
    if request.method == "DELETE":
        device.delete()
        return ok(None, "req_device_unbind")
    return fail("Method not allowed", status=405)


@csrf_exempt
@require_auth
def bind_device(request):
    payload = body_json(request)
    child_id = parse_public_id(payload.get("childId"), "child_")
    child = get_object_or_404(ChildProfile, pk=child_id, parent=request.parent_profile)
    serial_number = payload.get("bindCode") or payload.get("serialNumber")
    if not serial_number:
        return fail("绑定码不能为空")
    device, created = Device.objects.get_or_create(
        serial_number=serial_number,
        defaults={"child": child, "name": payload.get("deviceName", "小黄鸭")},
    )
    if not created and device.child.parent_id != request.parent_profile.id:
        return fail("设备已被其他账号绑定", code=40900, status=409)
    device.child = child
    device.name = payload.get("deviceName", device.name)
    device.save()
    SafetySettings.objects.get_or_create(device=device)
    UsageSettings.objects.get_or_create(device=device)
    return ok(device_to_dict(device), "req_device_bind")


@csrf_exempt
@require_auth
def firmware_check(request, device_id):
    device_pk = parse_public_id(device_id, "duck_")
    device = get_object_or_404(Device, pk=device_pk, child__parent=request.parent_profile)
    return ok(
        {
            "hasUpdate": device.firmware_version != "v1.9.0",
            "currentVersion": device.firmware_version,
            "latestVersion": "v1.9.0",
            "releaseNotes": "优化夜间提醒与语音识别稳定性。",
        },
        "req_firmware",
    )


@csrf_exempt
@require_auth
def conversations(request):
    parent = request.parent_profile
    child_id = parse_public_id(request.GET.get("childId"), "child_")
    device_id = parse_public_id(request.GET.get("deviceId"), "duck_")
    qs = Conversation.objects.filter(child__parent=parent).order_by("-started_at")
    if child_id:
        qs = qs.filter(child_id=child_id)
    if device_id:
        qs = qs.filter(device_id=device_id)
    if request.GET.get("dateFrom"):
        qs = qs.filter(started_at__date__gte=parse_date(request.GET.get("dateFrom")))
    if request.GET.get("dateTo"):
        qs = qs.filter(started_at__date__lte=parse_date(request.GET.get("dateTo")))
    if request.GET.get("riskLevel"):
        qs = qs.filter(risk_level=request.GET["riskLevel"])
    page = int(request.GET.get("page", 1))
    page_size = int(request.GET.get("pageSize", 20))
    paginator = Paginator(qs, page_size)
    page_obj = paginator.get_page(page)
    return ok(
        {
            "items": [conversation_to_dict(item) for item in page_obj.object_list],
            "page": page_obj.number,
            "pageSize": page_size,
            "total": paginator.count,
            "hasMore": page_obj.has_next(),
        },
        "req_conversations",
    )


@csrf_exempt
@require_auth
def conversation_detail(request, conversation_id):
    conversation_pk = parse_public_id(conversation_id, "c_")
    conversation = get_object_or_404(Conversation, pk=conversation_pk, child__parent=request.parent_profile)
    if request.method == "GET":
        return ok(conversation_to_dict(conversation, detail=True), "req_conversation_detail")
    if request.method == "PATCH":
        payload = body_json(request)
        if "parentNote" in payload:
            conversation.parent_note = payload["parentNote"]
        if "flagged" in payload:
            conversation.flagged = bool(payload["flagged"])
            conversation.risk_level = "attention" if conversation.flagged else "normal"
        conversation.save()
        return ok(conversation_to_dict(conversation, detail=True), "req_conversation_update")
    return fail("Method not allowed", status=405)


@csrf_exempt
def chat_message(request):
    if request.method != "POST":
        return fail("Method not allowed", status=405)
    parent = get_parent_from_token(read_token(request))
    if not parent and settings.CHAT_WEB_ALLOW_ANONYMOUS_DEMO:
        parent, _, _ = ensure_demo_family()
    if not parent:
        return fail("未登录", code=40100, status=401)
    payload = body_json(request)
    text = payload.get("text", "").strip()
    if not text:
        return fail("对话内容不能为空")
    child_id = parse_public_id(payload.get("childId"), "child_")
    device_id = parse_public_id(payload.get("deviceId"), "duck_")
    child = ChildProfile.objects.filter(parent=parent, pk=child_id).first() if child_id else first_child(parent)
    if not child:
        return fail("未找到孩子", code=40400, status=404)
    device = Device.objects.filter(child=child, pk=device_id).first() if device_id else first_device(child)
    if not device:
        return fail("未找到设备", code=40400, status=404)
    conversation = create_chat_conversation(child, device, text)
    return ok(conversation_to_dict(conversation, detail=True), "req_chat_message")


@csrf_exempt
@require_auth
def safety_settings(request, device_id):
    device_pk = parse_public_id(device_id, "duck_")
    device = get_object_or_404(Device, pk=device_pk, child__parent=request.parent_profile)
    settings_obj, _ = SafetySettings.objects.get_or_create(device=device)
    if request.method == "GET":
        return ok(safety_to_dict(settings_obj), "req_safety_get")
    if request.method == "PUT":
        payload = body_json(request)
        settings_obj.sensitive_topic_filter = payload.get("sensitiveTopicFilter", settings_obj.sensitive_topic_filter)
        settings_obj.stranger_info_alert = payload.get("strangerInfoAlert", settings_obj.stranger_info_alert)
        settings_obj.negative_emotion_alert = payload.get("negativeEmotionAlert", settings_obj.negative_emotion_alert)
        settings_obj.night_usage_alert = payload.get("nightUsageAlert", settings_obj.night_usage_alert)
        settings_obj.blocked_keywords = payload.get("blockedKeywords", settings_obj.blocked_keywords)
        settings_obj.reply_style = payload.get("replyStyle", settings_obj.reply_style)
        settings_obj.save()
        return ok(safety_to_dict(settings_obj), "req_safety_update")
    return fail("Method not allowed", status=405)


@csrf_exempt
@require_auth
def blocked_keywords(request, device_id, keyword=None):
    device_pk = parse_public_id(device_id, "duck_")
    device = get_object_or_404(Device, pk=device_pk, child__parent=request.parent_profile)
    settings_obj, _ = SafetySettings.objects.get_or_create(device=device)
    words = list(settings_obj.blocked_keywords or [])
    if request.method == "POST":
        word = body_json(request).get("keyword", "").strip()
        if word and word not in words:
            words.append(word)
    elif request.method == "DELETE" and keyword:
        words = [word for word in words if word != keyword]
    else:
        return fail("Method not allowed", status=405)
    settings_obj.blocked_keywords = words
    settings_obj.save(update_fields=["blocked_keywords", "updated_at"])
    return ok(words, "req_blocked_keywords")


@require_auth
def usage_today(request, child_id):
    child_pk = parse_public_id(child_id, "child_")
    child = get_object_or_404(ChildProfile, pk=child_pk, parent=request.parent_profile)
    stats, _ = DailyUsageStats.objects.get_or_create(child=child, date=parse_date(request.GET.get("date")))
    return ok(usage_stats_to_dict(stats), "req_usage_today")


@csrf_exempt
@require_auth
def usage_settings(request, device_id):
    device_pk = parse_public_id(device_id, "duck_")
    device = get_object_or_404(Device, pk=device_pk, child__parent=request.parent_profile)
    settings_obj, _ = UsageSettings.objects.get_or_create(device=device)
    if request.method == "GET":
        stats, _ = DailyUsageStats.objects.get_or_create(child=device.child, date=timezone.localdate())
        return ok(usage_to_dict(settings_obj, stats), "req_usage_settings")
    if request.method == "PUT":
        payload = body_json(request)
        settings_obj.max_daily_minutes = payload.get("maxDailyMinutes", settings_obj.max_daily_minutes)
        settings_obj.sleep_start = payload.get("sleepStart", settings_obj.sleep_start)
        settings_obj.sleep_end = payload.get("sleepEnd", settings_obj.sleep_end)
        settings_obj.nap_do_not_disturb = payload.get("napDoNotDisturb", settings_obj.nap_do_not_disturb)
        settings_obj.weekly_plan = payload.get("weeklyPlan", settings_obj.weekly_plan)
        settings_obj.paused = payload.get("paused", settings_obj.paused)
        settings_obj.save()
        stats, _ = DailyUsageStats.objects.get_or_create(child=device.child, date=timezone.localdate())
        return ok(usage_to_dict(settings_obj, stats), "req_usage_update")
    return fail("Method not allowed", status=405)


@csrf_exempt
@require_auth
def pause_device(request, device_id):
    device_pk = parse_public_id(device_id, "duck_")
    device = get_object_or_404(Device, pk=device_pk, child__parent=request.parent_profile)
    settings_obj, _ = UsageSettings.objects.get_or_create(device=device)
    settings_obj.paused = bool(body_json(request).get("paused", True))
    settings_obj.save(update_fields=["paused", "updated_at"])
    return ok({"paused": settings_obj.paused}, "req_pause")


def legal_document(request, doc_type):
    document = LegalDocument.objects.filter(type=doc_type, is_latest=True).order_by("-effective_at").first()
    if not document:
        ensure_demo_family()
        document = LegalDocument.objects.filter(type=doc_type, is_latest=True).order_by("-effective_at").first()
    if not document:
        return fail("协议文档不存在", code=40400, status=404)
    return ok(legal_to_dict(document), "req_legal")


@csrf_exempt
def feedback(request):
    if request.method != "POST":
        return fail("Method not allowed", status=405)
    parent = get_parent_from_token(read_token(request))
    payload = body_json(request)
    if not payload.get("content"):
        return fail("反馈内容不能为空")
    item = Feedback.objects.create(
        parent=parent,
        type=payload.get("type", "other"),
        content=payload["content"],
        contact=payload.get("contact", ""),
        client_info=payload.get("clientInfo", {}),
    )
    return ok(feedback_to_dict(item), "req_feedback")


@csrf_exempt
@require_auth
def alerts(request):
    qs = Alert.objects.filter(child__parent=request.parent_profile).order_by("-created_at")
    if request.GET.get("childId"):
        qs = qs.filter(child_id=parse_public_id(request.GET.get("childId"), "child_"))
    if request.GET.get("status"):
        qs = qs.filter(status=request.GET["status"])
    page = int(request.GET.get("page", 1))
    page_size = int(request.GET.get("pageSize", 20))
    paginator = Paginator(qs, page_size)
    page_obj = paginator.get_page(page)
    return ok(
        {
            "items": [alert_to_dict(item) for item in page_obj.object_list],
            "page": page_obj.number,
            "pageSize": page_size,
            "total": paginator.count,
            "hasMore": page_obj.has_next(),
        },
        "req_alerts",
    )


@csrf_exempt
@require_auth
def alert_detail(request, alert_id):
    alert_pk = parse_public_id(alert_id, "alert_")
    alert = get_object_or_404(Alert, pk=alert_pk, child__parent=request.parent_profile)
    if request.method == "PATCH":
        alert.status = body_json(request).get("status", alert.status)
        alert.save(update_fields=["status", "updated_at"])
        return ok(alert_to_dict(alert), "req_alert_update")
    return fail("Method not allowed", status=405)
