from datetime import timedelta

from django.contrib.auth.models import User
from django.db.models import F
from django.utils import timezone

from .models import (
    Alert,
    ChildProfile,
    Conversation,
    ConversationUtterance,
    DailyUsageStats,
    Device,
    LegalDocument,
    ParentProfile,
    SafetySettings,
    UsageSettings,
)
from .ai_client import generate_deepseek_chat_result
from .serializers import default_weekly_plan


def ensure_demo_family(account="demo_parent", password="123456"):
    user, created = User.objects.get_or_create(username=account, defaults={"email": "demo@example.com"})
    if created:
        user.set_password(password)
        user.save(update_fields=["password"])

    parent, _ = ParentProfile.objects.get_or_create(
        user=user,
        defaults={"name": "林女士", "phone": "138****2468", "relation": "妈妈"},
    )
    child, _ = ChildProfile.objects.get_or_create(
        parent=parent,
        nickname="小满",
        defaults={
            "age": 5,
            "gender": "女",
            "interests": ["恐龙", "绘本", "英语", "宇宙", "动物"],
            "focus_areas": ["语言表达", "情绪陪伴", "科普启蒙"],
        },
    )
    serial_number = "YD-AI-2026-0629" if account == "demo_parent" else f"YD-AI-DEMO-{user.id:04d}"
    device, _ = Device.objects.get_or_create(
        serial_number=serial_number,
        defaults={
            "child": child,
            "name": "暖暖的小黄鸭",
            "is_online": True,
            "battery_level": 82,
            "network_name": "Home-Kids-5G",
            "firmware_version": "v1.8.2",
            "volume": 0.58,
            "voice_name": "软萌小鸭音",
        },
    )
    SafetySettings.objects.get_or_create(
        device=device,
        defaults={
            "blocked_keywords": ["暴力", "恐怖", "金钱", "陌生人联系方式"],
            "reply_style": "gentle_companion",
        },
    )
    UsageSettings.objects.get_or_create(
        device=device,
        defaults={
            "max_daily_minutes": 60,
            "sleep_start": "21:00",
            "sleep_end": "07:00",
            "nap_do_not_disturb": True,
            "weekly_plan": default_weekly_plan(),
            "paused": False,
        },
    )
    DailyUsageStats.objects.get_or_create(
        child=child,
        date=timezone.localdate(),
        defaults={
            "conversation_count": 0,
            "companion_minutes": 0,
            "story_count": 0,
            "learning_interactions": 0,
        },
    )
    ensure_legal_documents()
    return parent, child, device


def ensure_legal_documents():
    LegalDocument.objects.get_or_create(
        type="privacy",
        version="2026-06-30",
        defaults={
            "title": "隐私政策",
            "content": "我们非常重视儿童语音数据与家庭信息的保护。当前为原型占位文案，正式版本需法务审核。",
            "is_latest": True,
        },
    )
    LegalDocument.objects.get_or_create(
        type="terms",
        version="2026-06-30",
        defaults={
            "title": "用户协议",
            "content": "小黄鸭家长端用于管理 AI 语音对话玩具。当前为原型占位文案，正式版本需法务审核。",
            "is_latest": True,
        },
    )


def parse_public_id(value, prefix):
    if value is None:
        return None
    text = str(value)
    if text.startswith(prefix):
        text = text[len(prefix) :]
    try:
        return int(text)
    except ValueError:
        return None


def generate_duck_reply(text: str):
    ai_result = generate_deepseek_chat_result(text)
    if ai_result:
        return (
            ai_result["duck_reply"],
            ai_result["emotion"],
            ai_result["risk"],
            ai_result["tags"],
            ai_result["emotion_analysis"],
            ai_result["safety_judgement"],
        )

    return generate_rule_based_reply(text)


def generate_rule_based_reply(text: str):
    lowered = text.lower()
    severe_keywords = ["不想活", "想死", "自杀", "不要我了", "伤害自己"]
    risk_keywords = ["地址", "电话", "联系方式", "陌生人", "钱", "暴力", "恐怖", "打人"]
    sad_keywords = [
        "不开心",
        "难过",
        "伤心",
        "失落",
        "沮丧",
        "委屈",
        "想哭",
        "哭了",
        "输了",
        "失败",
        "没拿到",
        "没有拿到",
        "比赛没有",
        "被批评",
    ]
    science_keywords = ["月亮", "恐龙", "星星", "宇宙", "为什么", "怎么"]
    story_keywords = ["故事", "睡觉", "晚安"]
    english_keywords = ["英语", "hello", "apple"]

    risk = "normal"
    emotion = "curious"
    tags = []

    if any(keyword in text for keyword in severe_keywords):
        risk = "high_risk"
        emotion = "sad"
        tags.append("高风险")
        reply = "小黄鸭听到你很难受，我会认真陪着你。现在请马上去找爸爸妈妈、老师或身边的大人，好吗？"
        judgement = "命中高风险情绪表达，建议家长立即查看并线下陪伴沟通。"
    elif any(keyword in text for keyword in risk_keywords):
        risk = "attention"
        emotion = "scared" if any(keyword in text for keyword in ["害怕", "恐怖", "陌生人"]) else "calm"
        tags.append("安全")
        reply = "这个问题很重要。遇到不确定的人或事情，先不要透露家里的信息，可以马上告诉爸爸妈妈或老师。"
        judgement = "命中安全相关话题，建议家长关注并进行温和沟通。"
    elif any(keyword in text for keyword in sad_keywords):
        emotion = "sad"
        tags.append("情绪")
        reply = "听起来你有一点失落，小黄鸭抱抱你。没拿到第一名也没关系，我们可以一起想想下次想怎么努力。"
        judgement = "内容属于普通挫败或低落情绪，暂无明显安全风险，建议家长温和关注。"
    elif any(keyword in text for keyword in science_keywords):
        tags.append("科普")
        reply = "这是个很棒的问题！我们可以像小侦探一样观察它，再一起找找背后的原因。"
        judgement = "内容健康，属于科普探索话题。"
    elif any(keyword in text for keyword in story_keywords):
        emotion = "calm"
        tags.append("故事")
        reply = "好呀，小黄鸭给你讲一个暖暖的小故事。故事里有一颗会发光的小星星，陪着小朋友慢慢进入甜甜的梦。"
        judgement = "内容健康，适合睡前陪伴。"
    elif any(keyword in lowered for keyword in english_keywords):
        tags.append("英语")
        reply = "我们一起用英语说一遍吧：Hello! 你也可以教小黄鸭一个今天新学的单词。"
        judgement = "内容健康，属于英语启蒙互动。"
    else:
        emotion = "happy"
        reply = "小黄鸭听见啦！你愿意多告诉我一点吗？我很想知道你今天最开心的一件事。"
        judgement = "内容正常，适合继续陪伴式追问。"

    analysis = {
        "happy": "孩子表达积极，适合继续鼓励分享。",
        "curious": "孩子展现出探索兴趣，可以延伸为科普或观察任务。",
        "sad": "孩子表达了低落或挫败感，适合先共情，再鼓励表达原因。",
        "scared": "孩子可能有担心或不安全感，需要家长留意触发原因。",
        "calm": "孩子状态平稳，适合温和陪伴。",
    }.get(emotion, "孩子状态稳定。")
    return reply, emotion, risk, tags, analysis, judgement


def create_chat_conversation(child: ChildProfile, device: Device, text: str):
    reply, emotion, risk, tags, analysis, judgement = generate_duck_reply(text)
    now = timezone.now()
    conversation = Conversation.objects.create(
        child=child,
        device=device,
        started_at=now,
        ended_at=now + timedelta(seconds=16),
        child_speech=text,
        duck_reply=reply,
        emotion=emotion,
        risk_level=risk,
        full_conversation=f"孩子：{text}\n小黄鸭：{reply}",
        emotion_analysis=analysis,
        safety_judgement=judgement,
        flagged=risk != "normal",
        tags=tags,
    )
    ConversationUtterance.objects.create(conversation=conversation, speaker="child", content=text, created_at=now)
    ConversationUtterance.objects.create(
        conversation=conversation,
        speaker="duck",
        content=reply,
        created_at=now + timedelta(seconds=3),
    )

    stats, _ = DailyUsageStats.objects.get_or_create(child=child, date=timezone.localdate())
    DailyUsageStats.objects.filter(pk=stats.pk).update(
        conversation_count=F("conversation_count") + 1,
        companion_minutes=F("companion_minutes") + 2,
        learning_interactions=F("learning_interactions") + (1 if "科普" in tags or "英语" in tags else 0),
        story_count=F("story_count") + (1 if "故事" in tags else 0),
    )

    if risk != "normal":
        Alert.objects.create(
            child=child,
            conversation=conversation,
            type="safety_attention",
            title="对话需关注",
            content="孩子提到了可能需要家长关注的话题，建议查看对话详情。",
        )
    return conversation


def today_summary(child: ChildProfile):
    today = timezone.localdate()
    conversations = Conversation.objects.filter(child=child, started_at__date=today).order_by("-started_at")[:5]
    if not conversations:
        return "今天还没有新的对话记录。小黄鸭准备好陪孩子聊聊有趣的发现。"
    topics = []
    attention_count = 0
    for conversation in conversations:
        topics.extend(conversation.tags or [])
        if conversation.risk_level != "normal":
            attention_count += 1
    topic_text = "、".join(dict.fromkeys(topics)) or "日常分享"
    if attention_count:
        return f"今天孩子主要聊了{topic_text}，其中有 {attention_count} 条内容建议家长关注。"
    return f"今天孩子主要聊了{topic_text}，整体互动积极、稳定。"
