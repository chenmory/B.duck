# 家长端 App 接口文档

Base URL：

```text
http://127.0.0.1:8000/api/v1
```

通用请求头：

```http
Content-Type: application/json
Authorization: Bearer <accessToken>
X-Client-Platform: ios | android | web
X-App-Version: 1.0.0
```

通用响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": {},
  "requestId": "req_xxx"
}
```

## 1. 登录

`POST /auth/login`

请求：

```json
{
  "account": "demo_parent",
  "password": "123456"
}
```

响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "accessToken": "token",
    "refreshToken": "refresh_token",
    "expiresIn": 7200,
    "user": {
      "id": "parent_1",
      "name": "林女士",
      "phone": "138****2468",
      "relation": "妈妈",
      "avatarUrl": ""
    }
  },
  "requestId": "req_login"
}
```

## 2. 刷新 Token

`POST /auth/refresh`

```json
{
  "refreshToken": "refresh_token"
}
```

## 3. 当前家长信息

`GET /me`

用于“我的”页面和首页问候。

## 4. 首页 Dashboard

`GET /dashboard/today?date=2026-06-30`

响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "greeting": "晚上好",
    "todaySummary": "今天孩子主要聊了科普，整体互动积极、稳定。",
    "device": {
      "id": "duck_1",
      "name": "暖暖的小黄鸭",
      "isOnline": true,
      "batteryLevel": 82,
      "networkName": "Home-Kids-5G"
    },
    "usage": {
      "conversationCount": 18,
      "companionMinutes": 42,
      "storyCount": 3,
      "learningInteractions": 6
    },
    "attentionCount": 1
  },
  "requestId": "req_dashboard"
}
```

## 5. 孩子资料

### 5.1 获取孩子列表

`GET /children`

### 5.2 获取孩子详情

`GET /children/{childId}`

示例：

```text
GET /children/child_1
```

### 5.3 更新孩子资料

`PUT /children/{childId}`

```json
{
  "nickname": "小满",
  "age": 5,
  "gender": "女",
  "interests": ["恐龙", "绘本", "英语"],
  "focusAreas": ["语言表达", "情绪陪伴"]
}
```

## 6. 设备管理

### 6.1 获取设备列表

`GET /devices?childId=child_1`

### 6.2 获取设备详情

`GET /devices/{deviceId}`

示例：

```text
GET /devices/duck_1
```

### 6.3 更新设备设置

`PATCH /devices/{deviceId}`

```json
{
  "name": "暖暖的小黄鸭",
  "volume": 0.65,
  "voiceName": "故事老师音"
}
```

### 6.4 绑定设备

`POST /devices/bind`

```json
{
  "childId": "child_1",
  "bindCode": "YD-AI-2026-0629",
  "deviceName": "暖暖的小黄鸭"
}
```

### 6.5 解绑设备

`DELETE /devices/{deviceId}`

### 6.6 检查固件更新

`POST /devices/{deviceId}/firmware/check`

## 7. 对话记录

### 7.1 获取对话列表

`GET /conversations?childId=child_1&dateFrom=2026-06-30&dateTo=2026-06-30&page=1&pageSize=20`

响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "items": [
      {
        "id": "c_1",
        "childId": "child_1",
        "deviceId": "duck_1",
        "startedAt": "2026-06-30T10:20:00+09:00",
        "childSpeech": "月亮为什么会跟着我走？",
        "duckReply": "这是个很棒的问题！我们可以像小侦探一样观察它。",
        "emotion": "curious",
        "riskLevel": "normal",
        "parentNote": "",
        "flagged": false,
        "tags": ["科普"]
      }
    ],
    "page": 1,
    "pageSize": 20,
    "total": 1,
    "hasMore": false
  },
  "requestId": "req_conversations"
}
```

### 7.2 获取对话详情

`GET /conversations/{conversationId}`

示例：

```text
GET /conversations/c_1
```

### 7.3 更新备注和关注标记

`PATCH /conversations/{conversationId}`

```json
{
  "parentNote": "晚上和孩子聊聊陌生人边界。",
  "flagged": true
}
```

## 8. 安全守护

### 8.1 获取安全设置

`GET /devices/{deviceId}/safety-settings`

### 8.2 更新安全设置

`PUT /devices/{deviceId}/safety-settings`

```json
{
  "sensitiveTopicFilter": true,
  "strangerInfoAlert": true,
  "negativeEmotionAlert": true,
  "nightUsageAlert": true,
  "blockedKeywords": ["暴力", "恐怖", "金钱", "陌生人联系方式"],
  "replyStyle": "gentle_companion"
}
```

### 8.3 添加禁聊关键词

`POST /devices/{deviceId}/safety-settings/blocked-keywords`

```json
{
  "keyword": "危险游戏"
}
```

### 8.4 删除禁聊关键词

`DELETE /devices/{deviceId}/safety-settings/blocked-keywords/{keyword}`

## 9. 使用时间管理

### 9.1 今日使用统计

`GET /children/{childId}/usage/today?date=2026-06-30`

### 9.2 获取使用时间设置

`GET /devices/{deviceId}/usage-settings`

### 9.3 更新使用时间设置

`PUT /devices/{deviceId}/usage-settings`

```json
{
  "maxDailyMinutes": 90,
  "sleepStart": "21:00",
  "sleepEnd": "07:00",
  "napDoNotDisturb": true,
  "weeklyPlan": {
    "mon": true,
    "tue": true,
    "wed": true,
    "thu": true,
    "fri": true,
    "sat": true,
    "sun": false
  },
  "paused": false
}
```

### 9.4 暂停/恢复小黄鸭

`POST /devices/{deviceId}/usage-settings/pause`

```json
{
  "paused": true
}
```

## 10. 协议文档

`GET /legal-documents/privacy`  
`GET /legal-documents/terms`

这两个接口登录页也可以调用，不要求 Token。

## 11. 用户反馈

`POST /feedback`

```json
{
  "type": "feature",
  "content": "希望可以导出一周对话摘要。",
  "contact": "parent@example.com",
  "clientInfo": {
    "platform": "ios",
    "appVersion": "1.0.0"
  }
}
```

## 12. 退出登录

`POST /auth/logout`

## 13. 枚举

### emotion

| 值 | 展示 |
| --- | --- |
| happy | 开心 |
| curious | 好奇 |
| sad | 低落 |
| scared | 害怕 |
| calm | 平静 |

### riskLevel

| 值 | 展示 |
| --- | --- |
| normal | 正常 |
| attention | 需关注 |
| high_risk | 高风险 |

### replyStyle

| 值 | 展示 |
| --- | --- |
| gentle_companion | 温柔陪伴 |
| knowledge | 知识启蒙 |
| story | 故事模式 |
| short | 简短回答 |
