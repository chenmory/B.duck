import json
import logging
import urllib.error
import urllib.request

from django.conf import settings

logger = logging.getLogger(__name__)


EMOTIONS = {"happy", "curious", "sad", "scared", "calm"}
RISK_LEVELS = {"normal", "attention", "high_risk"}


SYSTEM_PROMPT = """
你是“小黄鸭 AI 语音玩具”的儿童陪伴对话引擎，同时要给家长端返回结构化分析。
请只输出 json，不要输出 markdown 或解释文字。

输出字段：
{
  "duckReply": "小黄鸭给孩子的回复，温柔、简短、适合 3-8 岁儿童",
  "emotion": "happy|curious|sad|scared|calm",
  "riskLevel": "normal|attention|high_risk",
  "tags": ["最多 3 个中文标签"],
  "emotionAnalysis": "给家长看的简短情绪分析",
  "safetyJudgement": "给家长看的简短安全判断"
}

判断规则：
- “不开心、难过、伤心、失落、比赛输了、没拿到第一名”等普通挫败感，应标记 emotion=sad 且 riskLevel=normal。
- 提到陌生人索要地址、电话、联系方式、金钱、暴力、恐怖内容，应标记 riskLevel=attention。
- 提到自伤、自杀、严重伤害自己或他人的意图，应标记 riskLevel=high_risk。
- 不要把包含“不开心”的句子标成 happy。
- 回复要先共情，再轻轻引导表达或找家长聊聊。
""".strip()


def generate_deepseek_chat_result(text: str):
    if not settings.AI_CHAT_ENABLED or not settings.DEEPSEEK_API_KEY:
        return None

    payload = {
        "model": settings.DEEPSEEK_MODEL,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": f"孩子说：{text}\n请按要求输出 json。"},
        ],
        "response_format": {"type": "json_object"},
        "temperature": 0.55,
        "max_tokens": 500,
        "stream": False,
    }
    url = f"{settings.DEEPSEEK_BASE_URL.rstrip('/')}/chat/completions"
    request = urllib.request.Request(
        url,
        data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {settings.DEEPSEEK_API_KEY}",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=settings.DEEPSEEK_TIMEOUT_SECONDS) as response:
            body = json.loads(response.read().decode("utf-8"))
        content = body["choices"][0]["message"]["content"]
        data = json.loads(content)
        return normalize_ai_result(data)
    except (KeyError, json.JSONDecodeError, urllib.error.URLError, TimeoutError, ValueError) as exc:
        logger.warning("DeepSeek chat generation failed, falling back to local rules: %s", exc)
        return None


def normalize_ai_result(data):
    emotion = data.get("emotion") if data.get("emotion") in EMOTIONS else "curious"
    risk_level = data.get("riskLevel") if data.get("riskLevel") in RISK_LEVELS else "normal"
    tags = data.get("tags") if isinstance(data.get("tags"), list) else []
    tags = [str(tag).strip() for tag in tags if str(tag).strip()][:3]

    return {
        "duck_reply": _clean_text(data.get("duckReply"), "小黄鸭听见啦，你愿意再多告诉我一点吗？"),
        "emotion": emotion,
        "risk": risk_level,
        "tags": tags,
        "emotion_analysis": _clean_text(data.get("emotionAnalysis"), "孩子状态稳定，可以继续温和陪伴。"),
        "safety_judgement": _clean_text(data.get("safetyJudgement"), "内容正常，适合继续陪伴式交流。"),
    }


def _clean_text(value, fallback):
    if not isinstance(value, str):
        return fallback
    value = value.strip()
    return value or fallback
