from django.core.management.base import BaseCommand

from apps.core.models import Alert, Conversation
from apps.core.services import generate_rule_based_reply


class Command(BaseCommand):
    help = "Reanalyze existing conversation emotion/risk labels with local prototype rules."

    def handle(self, *args, **options):
        updated = 0
        for conversation in Conversation.objects.order_by("id"):
            reply, emotion, risk, tags, analysis, judgement = generate_rule_based_reply(conversation.child_speech)
            conversation.duck_reply = reply
            conversation.emotion = emotion
            conversation.risk_level = risk
            conversation.tags = tags
            conversation.emotion_analysis = analysis
            conversation.safety_judgement = judgement
            conversation.full_conversation = f"孩子：{conversation.child_speech}\n小黄鸭：{reply}"
            conversation.flagged = risk != "normal"
            conversation.save(
                update_fields=[
                    "duck_reply",
                    "emotion",
                    "risk_level",
                    "tags",
                    "emotion_analysis",
                    "safety_judgement",
                    "full_conversation",
                    "flagged",
                    "updated_at",
                ]
            )
            if risk != "normal":
                Alert.objects.get_or_create(
                    child=conversation.child,
                    conversation=conversation,
                    type="safety_attention",
                    defaults={
                        "title": "对话需关注",
                        "content": "孩子提到了可能需要家长关注的话题，建议查看对话详情。",
                    },
                )
            else:
                Alert.objects.filter(conversation=conversation, type="safety_attention").delete()
            updated += 1

        self.stdout.write(self.style.SUCCESS(f"Reanalyzed {updated} conversations."))
