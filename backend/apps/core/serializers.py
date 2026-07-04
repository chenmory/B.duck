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


def parent_to_dict(parent: ParentProfile):
    return {
        "id": f"parent_{parent.id}",
        "name": parent.name,
        "phone": parent.phone,
        "relation": parent.relation,
        "avatarUrl": parent.avatar_url,
    }


def child_to_dict(child: ChildProfile):
    return {
        "id": f"child_{child.id}",
        "nickname": child.nickname,
        "age": child.age,
        "gender": child.gender,
        "interests": child.interests or [],
        "focusAreas": child.focus_areas or [],
    }


def device_to_dict(device: Device, brief=False):
    data = {
        "id": f"duck_{device.id}",
        "name": device.name,
        "serialNumber": device.serial_number,
        "isOnline": device.is_online,
        "batteryLevel": device.battery_level,
        "networkName": device.network_name,
        "firmwareVersion": device.firmware_version,
        "volume": device.volume,
        "voiceName": device.voice_name,
        "lastOnlineAt": device.last_online_at.isoformat() if device.last_online_at else None,
    }
    if brief:
        return {
            "id": data["id"],
            "name": data["name"],
            "isOnline": data["isOnline"],
            "batteryLevel": data["batteryLevel"],
            "networkName": data["networkName"],
        }
    return data


def safety_to_dict(settings: SafetySettings):
    return {
        "sensitiveTopicFilter": settings.sensitive_topic_filter,
        "strangerInfoAlert": settings.stranger_info_alert,
        "negativeEmotionAlert": settings.negative_emotion_alert,
        "nightUsageAlert": settings.night_usage_alert,
        "blockedKeywords": settings.blocked_keywords or [],
        "replyStyle": settings.reply_style,
    }


def usage_to_dict(settings: UsageSettings, stats: DailyUsageStats | None = None):
    data = {
        "maxDailyMinutes": settings.max_daily_minutes,
        "sleepStart": settings.sleep_start,
        "sleepEnd": settings.sleep_end,
        "napDoNotDisturb": settings.nap_do_not_disturb,
        "weeklyPlan": settings.weekly_plan or default_weekly_plan(),
        "paused": settings.paused,
    }
    if stats:
        data.update(
            {
                "conversationCount": stats.conversation_count,
                "companionMinutes": stats.companion_minutes,
                "storyCount": stats.story_count,
                "learningInteractions": stats.learning_interactions,
            }
        )
    return data


def usage_stats_to_dict(stats: DailyUsageStats):
    return {
        "conversationCount": stats.conversation_count,
        "companionMinutes": stats.companion_minutes,
        "storyCount": stats.story_count,
        "learningInteractions": stats.learning_interactions,
    }


def conversation_to_dict(conversation: Conversation, detail=False):
    data = {
        "id": f"c_{conversation.id}",
        "childId": f"child_{conversation.child_id}",
        "deviceId": f"duck_{conversation.device_id}" if conversation.device_id else None,
        "startedAt": conversation.started_at.isoformat(),
        "endedAt": conversation.ended_at.isoformat() if conversation.ended_at else None,
        "childSpeech": conversation.child_speech,
        "duckReply": conversation.duck_reply,
        "emotion": conversation.emotion,
        "riskLevel": conversation.risk_level,
        "parentNote": conversation.parent_note,
        "flagged": conversation.flagged,
        "tags": conversation.tags or [],
    }
    if detail:
        data.update(
            {
                "fullConversation": conversation.full_conversation,
                "emotionAnalysis": conversation.emotion_analysis,
                "safetyJudgement": conversation.safety_judgement,
                "utterances": [
                    {
                        "speaker": utterance.speaker,
                        "content": utterance.content,
                        "createdAt": utterance.created_at.isoformat(),
                    }
                    for utterance in conversation.utterances.order_by("created_at")
                ],
            }
        )
    return data


def alert_to_dict(alert: Alert):
    return {
        "id": f"alert_{alert.id}",
        "type": alert.type,
        "title": alert.title,
        "content": alert.content,
        "conversationId": f"c_{alert.conversation_id}" if alert.conversation_id else None,
        "status": alert.status,
        "createdAt": alert.created_at.isoformat(),
    }


def feedback_to_dict(feedback: Feedback):
    return {
        "feedbackId": f"fb_{feedback.id}",
        "submittedAt": feedback.created_at.isoformat(),
    }


def legal_to_dict(document: LegalDocument):
    return {
        "type": document.type,
        "version": document.version,
        "title": document.title,
        "content": document.content,
        "effectiveAt": document.effective_at.isoformat(),
    }


def default_weekly_plan():
    return {
        "mon": True,
        "tue": True,
        "wed": True,
        "thu": True,
        "fri": True,
        "sat": True,
        "sun": False,
    }
