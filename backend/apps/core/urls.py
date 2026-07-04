from django.urls import path

from . import views

api = "api/v1/"

urlpatterns = [
    path("chat/", views.public_chat_page, name="chat_page"),
    path(api + "auth/login", views.login, name="api_login"),
    path(api + "auth/refresh", views.refresh_token, name="api_refresh"),
    path(api + "auth/logout", views.logout, name="api_logout"),
    path(api + "me", views.me, name="api_me"),
    path(api + "dashboard/today", views.dashboard_today, name="api_dashboard_today"),
    path(api + "children", views.children, name="api_children"),
    path(api + "children/<str:child_id>", views.child_detail, name="api_child_detail"),
    path(api + "children/<str:child_id>/usage/today", views.usage_today, name="api_usage_today"),
    path(api + "devices", views.devices, name="api_devices"),
    path(api + "devices/bind", views.bind_device, name="api_device_bind"),
    path(api + "devices/<str:device_id>", views.device_detail, name="api_device_detail"),
    path(api + "devices/<str:device_id>/firmware/check", views.firmware_check, name="api_firmware_check"),
    path(api + "devices/<str:device_id>/safety-settings", views.safety_settings, name="api_safety_settings"),
    path(api + "devices/<str:device_id>/safety-settings/blocked-keywords", views.blocked_keywords, name="api_blocked_keywords_add"),
    path(
        api + "devices/<str:device_id>/safety-settings/blocked-keywords/<str:keyword>",
        views.blocked_keywords,
        name="api_blocked_keywords_delete",
    ),
    path(api + "devices/<str:device_id>/usage-settings", views.usage_settings, name="api_usage_settings"),
    path(api + "devices/<str:device_id>/usage-settings/pause", views.pause_device, name="api_usage_pause"),
    path(api + "conversations", views.conversations, name="api_conversations"),
    path(api + "conversations/<str:conversation_id>", views.conversation_detail, name="api_conversation_detail"),
    path(api + "chat/messages", views.chat_message, name="api_chat_message"),
    path(api + "legal-documents/<str:doc_type>", views.legal_document, name="api_legal_document"),
    path(api + "feedback", views.feedback, name="api_feedback"),
    path(api + "alerts", views.alerts, name="api_alerts"),
    path(api + "alerts/<str:alert_id>", views.alert_detail, name="api_alert_detail"),
]
