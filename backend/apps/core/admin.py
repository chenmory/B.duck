from django.contrib import admin

from .models import (
    Alert,
    ChildProfile,
    Conversation,
    ConversationUtterance,
    DailyUsageStats,
    Device,
    DeviceStatusLog,
    Feedback,
    LegalDocument,
    ParentProfile,
    SafetySettings,
    UsageSettings,
)


@admin.register(ParentProfile)
class ParentProfileAdmin(admin.ModelAdmin):
    list_display = ("id", "name", "phone", "relation", "created_at")
    search_fields = ("name", "phone", "user__username")


@admin.register(ChildProfile)
class ChildProfileAdmin(admin.ModelAdmin):
    list_display = ("id", "nickname", "age", "gender", "parent")
    search_fields = ("nickname",)


@admin.register(Device)
class DeviceAdmin(admin.ModelAdmin):
    list_display = ("id", "name", "serial_number", "child", "is_online", "battery_level", "firmware_version")
    search_fields = ("name", "serial_number")
    list_filter = ("is_online",)


admin.site.register(DeviceStatusLog)
admin.site.register(SafetySettings)
admin.site.register(UsageSettings)
admin.site.register(DailyUsageStats)
admin.site.register(Conversation)
admin.site.register(ConversationUtterance)
admin.site.register(Alert)
admin.site.register(Feedback)
admin.site.register(LegalDocument)
