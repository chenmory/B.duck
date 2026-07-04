# AI 对话网页接口文档

AI 对话网页地址：

```text
http://127.0.0.1:8000/chat/
```

这个网页用于模拟“小黄鸭玩具”和孩子对话。它会：

1. 自动登录 demo 账号。
2. 获取孩子和设备。
3. 把孩子输入发送到后端。
4. 后端生成 mock 小黄鸭回复。
5. 后端把对话写入 MySQL。
6. 家长端 App 通过对话记录接口读取这些数据。

## 1. 自动登录

`POST /api/v1/auth/login`

请求：

```json
{
  "account": "demo_parent",
  "password": "123456"
}
```

返回 `accessToken`，后续请求放到请求头：

```http
Authorization: Bearer <accessToken>
```

## 2. 获取孩子

`GET /api/v1/children`

网页取第一条孩子数据作为当前模拟孩子。

## 3. 获取设备

`GET /api/v1/devices?childId=child_1`

网页取第一台设备作为当前模拟小黄鸭。

## 4. 发送孩子消息

`POST /api/v1/chat/messages`

请求：

```json
{
  "childId": "child_1",
  "deviceId": "duck_1",
  "text": "月亮为什么会跟着我走？"
}
```

响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "id": "c_1",
    "childId": "child_1",
    "deviceId": "duck_1",
    "startedAt": "2026-06-30T11:20:00+09:00",
    "endedAt": "2026-06-30T11:20:16+09:00",
    "childSpeech": "月亮为什么会跟着我走？",
    "duckReply": "这是个很棒的问题！我们可以像小侦探一样观察它，再一起找找背后的原因。",
    "emotion": "curious",
    "riskLevel": "normal",
    "parentNote": "",
    "flagged": false,
    "tags": ["科普"],
    "fullConversation": "孩子：月亮为什么会跟着我走？\n小黄鸭：这是个很棒的问题！...",
    "emotionAnalysis": "孩子展现出探索兴趣，可以延伸为科普或观察任务。",
    "safetyJudgement": "内容健康，属于科普探索话题。",
    "utterances": [
      {
        "speaker": "child",
        "content": "月亮为什么会跟着我走？",
        "createdAt": "2026-06-30T11:20:00+09:00"
      },
      {
        "speaker": "duck",
        "content": "这是个很棒的问题！我们可以像小侦探一样观察它，再一起找找背后的原因。",
        "createdAt": "2026-06-30T11:20:03+09:00"
      }
    ]
  },
  "requestId": "req_chat_message"
}
```

## 5. 入库逻辑

后端收到 `POST /chat/messages` 后会写入：

- `core_conversation`
- `core_conversationutterance`
- `core_dailyusagestats`
- 如果 `riskLevel != normal`，额外写入 `core_alert`

## 6. Mock AI 规则

当前后端根据关键词生成回复：

| 命中关键词 | 输出 |
| --- | --- |
| 月亮、恐龙、宇宙、为什么 | 科普类回复，emotion=curious |
| 故事、睡觉、晚安 | 故事/睡前陪伴回复，emotion=calm |
| 英语、hello、apple | 英语启蒙回复 |
| 地址、电话、陌生人、害怕、暴力、恐怖 | 安全提醒回复，riskLevel=attention |
| 其他 | 陪伴式追问，emotion=happy |

真实 AI 接入时替换 `apps/core/services.py` 的 `generate_duck_reply` 即可。

## 7. 前端页面文件

```text
backend/templates/chat/index.html
```

网页是纯 HTML/CSS/JS，没有构建步骤。
