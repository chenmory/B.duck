from django.contrib.auth.models import User
from django.db import models
from django.utils import timezone


class TimeStampedModel(models.Model):
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class ParentProfile(TimeStampedModel):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="parent_profile")
    name = models.CharField(max_length=64)
    phone = models.CharField(max_length=32, blank=True)
    relation = models.CharField(max_length=32, default="家长")
    avatar_url = models.URLField(blank=True)

    def __str__(self):
        return f"{self.name}({self.relation})"


class ChildProfile(TimeStampedModel):
    parent = models.ForeignKey(ParentProfile, on_delete=models.CASCADE, related_name="children")
    nickname = models.CharField(max_length=64)
    age = models.PositiveSmallIntegerField(default=5)
    gender = models.CharField(max_length=16, blank=True)
    interests = models.JSONField(default=list, blank=True)
    focus_areas = models.JSONField(default=list, blank=True)

    def __str__(self):
        return self.nickname


class Device(TimeStampedModel):
    child = models.ForeignKey(ChildProfile, on_delete=models.CASCADE, related_name="devices")
    name = models.CharField(max_length=128)
    serial_number = models.CharField(max_length=64, unique=True)
    is_online = models.BooleanField(default=True)
    battery_level = models.PositiveSmallIntegerField(default=80)
    network_name = models.CharField(max_length=128, blank=True)
    firmware_version = models.CharField(max_length=32, default="v1.0.0")
    volume = models.FloatField(default=0.6)
    voice_name = models.CharField(max_length=64, default="软萌小鸭音")
    last_online_at = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return f"{self.name} / {self.serial_number}"


class DeviceStatusLog(models.Model):
    device = models.ForeignKey(Device, on_delete=models.CASCADE, related_name="status_logs")
    is_online = models.BooleanField()
    battery_level = models.PositiveSmallIntegerField()
    network_name = models.CharField(max_length=128, blank=True)
    recorded_at = models.DateTimeField(default=timezone.now)

    class Meta:
        indexes = [models.Index(fields=["device", "-recorded_at"])]


class SafetySettings(TimeStampedModel):
    REPLY_STYLE_CHOICES = [
        ("gentle_companion", "温柔陪伴"),
        ("knowledge", "知识启蒙"),
        ("story", "故事模式"),
        ("short", "简短回答"),
    ]

    device = models.OneToOneField(Device, on_delete=models.CASCADE, related_name="safety_settings")
    sensitive_topic_filter = models.BooleanField(default=True)
    stranger_info_alert = models.BooleanField(default=True)
    negative_emotion_alert = models.BooleanField(default=True)
    night_usage_alert = models.BooleanField(default=True)
    blocked_keywords = models.JSONField(default=list, blank=True)
    reply_style = models.CharField(max_length=32, choices=REPLY_STYLE_CHOICES, default="gentle_companion")

    def __str__(self):
        return f"SafetySettings({self.device_id})"


class UsageSettings(TimeStampedModel):
    device = models.OneToOneField(Device, on_delete=models.CASCADE, related_name="usage_settings")
    max_daily_minutes = models.PositiveSmallIntegerField(default=60)
    sleep_start = models.CharField(max_length=5, default="21:00")
    sleep_end = models.CharField(max_length=5, default="07:00")
    nap_do_not_disturb = models.BooleanField(default=True)
    weekly_plan = models.JSONField(default=dict, blank=True)
    paused = models.BooleanField(default=False)

    def __str__(self):
        return f"UsageSettings({self.device_id})"


class DailyUsageStats(TimeStampedModel):
    child = models.ForeignKey(ChildProfile, on_delete=models.CASCADE, related_name="daily_usage_stats")
    date = models.DateField()
    conversation_count = models.PositiveIntegerField(default=0)
    companion_minutes = models.PositiveIntegerField(default=0)
    story_count = models.PositiveIntegerField(default=0)
    learning_interactions = models.PositiveIntegerField(default=0)

    class Meta:
        unique_together = ("child", "date")
        indexes = [models.Index(fields=["child", "-date"])]

    def __str__(self):
        return f"{self.child.nickname} {self.date}"


class Conversation(TimeStampedModel):
    EMOTION_CHOICES = [
        ("happy", "开心"),
        ("curious", "好奇"),
        ("sad", "低落"),
        ("scared", "害怕"),
        ("calm", "平静"),
    ]
    RISK_CHOICES = [
        ("normal", "正常"),
        ("attention", "需关注"),
        ("high_risk", "高风险"),
    ]

    child = models.ForeignKey(ChildProfile, on_delete=models.CASCADE, related_name="conversations")
    device = models.ForeignKey(Device, on_delete=models.SET_NULL, null=True, blank=True, related_name="conversations")
    started_at = models.DateTimeField(default=timezone.now)
    ended_at = models.DateTimeField(null=True, blank=True)
    child_speech = models.TextField()
    duck_reply = models.TextField()
    emotion = models.CharField(max_length=24, choices=EMOTION_CHOICES, default="curious")
    risk_level = models.CharField(max_length=24, choices=RISK_CHOICES, default="normal")
    full_conversation = models.TextField(blank=True)
    emotion_analysis = models.TextField(blank=True)
    safety_judgement = models.TextField(blank=True)
    parent_note = models.TextField(blank=True)
    flagged = models.BooleanField(default=False)
    tags = models.JSONField(default=list, blank=True)

    class Meta:
        indexes = [
            models.Index(fields=["child", "-started_at"]),
            models.Index(fields=["risk_level", "-started_at"]),
        ]

    def __str__(self):
        return f"{self.child.nickname}: {self.child_speech[:24]}"


class ConversationUtterance(models.Model):
    SPEAKER_CHOICES = [
        ("child", "孩子"),
        ("duck", "小黄鸭"),
    ]

    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name="utterances")
    speaker = models.CharField(max_length=16, choices=SPEAKER_CHOICES)
    content = models.TextField()
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        indexes = [models.Index(fields=["conversation", "created_at"])]


class Alert(TimeStampedModel):
    STATUS_CHOICES = [
        ("unread", "未读"),
        ("read", "已读"),
    ]

    child = models.ForeignKey(ChildProfile, on_delete=models.CASCADE, related_name="alerts")
    conversation = models.ForeignKey(Conversation, on_delete=models.SET_NULL, null=True, blank=True, related_name="alerts")
    type = models.CharField(max_length=48)
    title = models.CharField(max_length=128)
    content = models.TextField()
    status = models.CharField(max_length=16, choices=STATUS_CHOICES, default="unread")

    class Meta:
        indexes = [models.Index(fields=["child", "status", "-created_at"])]


class Feedback(TimeStampedModel):
    TYPE_CHOICES = [
        ("feature", "功能建议"),
        ("device", "设备问题"),
        ("conversation", "对话内容"),
        ("safety", "安全提醒"),
        ("other", "其他"),
    ]

    parent = models.ForeignKey(ParentProfile, on_delete=models.SET_NULL, null=True, blank=True, related_name="feedbacks")
    type = models.CharField(max_length=32, choices=TYPE_CHOICES)
    content = models.TextField()
    contact = models.CharField(max_length=128, blank=True)
    client_info = models.JSONField(default=dict, blank=True)


class LegalDocument(TimeStampedModel):
    TYPE_CHOICES = [
        ("privacy", "隐私政策"),
        ("terms", "用户协议"),
    ]

    type = models.CharField(max_length=16, choices=TYPE_CHOICES)
    version = models.CharField(max_length=32)
    title = models.CharField(max_length=128)
    content = models.TextField()
    effective_at = models.DateTimeField(default=timezone.now)
    is_latest = models.BooleanField(default=True)

    class Meta:
        unique_together = ("type", "version")
        indexes = [models.Index(fields=["type", "is_latest"])]

    def __str__(self):
        return f"{self.title} {self.version}"
