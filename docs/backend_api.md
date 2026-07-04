# 小黄鸭家长端后端接口文档

版本：v0.1  
适用端：Flutter 家长端 App  
接口前缀：`/api/v1`  
数据格式：`application/json; charset=utf-8`

## 1. 对接原则

当前 Flutter 原型的数据都来自 `lib/services/mock_service.dart`。接入后端时建议新增：

- `lib/services/api_client.dart`：统一处理 Base URL、Token、请求头、错误码。
- `lib/services/auth_service.dart`：登录、刷新 Token、退出登录。
- `lib/services/duck_repository.dart`：设备、首页、对话、安全、使用时间等业务接口。
- `lib/models/*`：保留现有模型，补充 `fromJson` / `toJson`。

接口命名以家长端视角为主，后端可按领域拆成 Auth、Child、Device、Conversation、Safety、Usage、Feedback 服务。

## 2. 通用约定

### 2.1 请求头

```http
Content-Type: application/json
Authorization: Bearer <accessToken>
X-Client-Platform: ios | android | web
X-App-Version: 1.0.0
```

登录、刷新 Token、获取协议文档可以不传 `Authorization`。

### 2.2 通用响应结构

```json
{
  "code": 0,
  "message": "ok",
  "data": {},
  "requestId": "req_20260630_001"
}
```

### 2.3 分页结构

```json
{
  "items": [],
  "page": 1,
  "pageSize": 20,
  "total": 86,
  "hasMore": true
}
```

### 2.4 常用错误码

| code | 含义 |
| --- | --- |
| 0 | 成功 |
| 40001 | 参数错误 |
| 40100 | 未登录或 Token 失效 |
| 40300 | 无权限访问该孩子/设备 |
| 40400 | 资源不存在 |
| 40900 | 状态冲突，例如设备已被绑定 |
| 42900 | 请求过于频繁 |
| 50000 | 服务端错误 |

## 3. 数据模型

### 3.1 ParentUser

```json
{
  "id": "parent_001",
  "name": "林女士",
  "phone": "138****2468",
  "relation": "妈妈",
  "avatarUrl": ""
}
```

### 3.2 ChildProfile

```json
{
  "id": "child_001",
  "nickname": "小满",
  "age": 5,
  "gender": "女",
  "interests": ["恐龙", "绘本", "英语", "宇宙", "动物"],
  "focusAreas": ["语言表达", "情绪陪伴", "科普启蒙"]
}
```

### 3.3 Device

```json
{
  "id": "duck-001",
  "name": "暖暖的小黄鸭",
  "serialNumber": "YD-AI-2026-0629",
  "isOnline": true,
  "batteryLevel": 82,
  "networkName": "Home-Kids-5G",
  "firmwareVersion": "v1.8.2",
  "volume": 0.58,
  "voiceName": "软萌小鸭音",
  "lastOnlineAt": "2026-06-30T09:35:12+09:00"
}
```

### 3.4 UsageStats

```json
{
  "conversationCount": 18,
  "companionMinutes": 42,
  "storyCount": 3,
  "learningInteractions": 6,
  "maxDailyMinutes": 60,
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

### 3.5 SafetySettings

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

`replyStyle` 建议枚举：

| 值 | 前端展示 |
| --- | --- |
| gentle_companion | 温柔陪伴 |
| knowledge | 知识启蒙 |
| story | 故事模式 |
| short | 简短回答 |

### 3.6 ConversationRecord

```json
{
  "id": "c1",
  "childId": "child_001",
  "deviceId": "duck-001",
  "startedAt": "2026-06-30T19:42:00+09:00",
  "endedAt": "2026-06-30T19:45:20+09:00",
  "childSpeech": "月亮为什么会跟着我一起走呀？",
  "duckReply": "因为月亮离我们很远很远，所以你走的时候，它看起来像在温柔地陪着你。",
  "emotion": "curious",
  "riskLevel": "normal",
  "fullConversation": "孩子：...\n小黄鸭：...",
  "emotionAnalysis": "孩子表现出明显的探索兴趣，问题连续且具体，情绪稳定积极。",
  "safetyJudgement": "内容健康，无敏感信息。",
  "parentNote": "",
  "flagged": false,
  "tags": ["科普", "月亮"]
}
```

枚举建议：

| 字段 | 值 |
| --- | --- |
| emotion | happy, curious, sad, scared, calm |
| riskLevel | normal, attention, high_risk |

## 4. 认证与账号

### 4.1 账号密码登录

`POST /api/v1/auth/login`

请求：

```json
{
  "account": "13800000000",
  "password": "123456"
}
```

响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "accessToken": "jwt_access_token",
    "refreshToken": "jwt_refresh_token",
    "expiresIn": 7200,
    "user": {
      "id": "parent_001",
      "name": "林女士",
      "phone": "138****2468",
      "relation": "妈妈"
    }
  },
  "requestId": "req_login_001"
}
```

前端使用位置：登录页。

### 4.2 刷新 Token

`POST /api/v1/auth/refresh`

请求：

```json
{
  "refreshToken": "jwt_refresh_token"
}
```

响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "accessToken": "new_access_token",
    "refreshToken": "new_refresh_token",
    "expiresIn": 7200
  },
  "requestId": "req_refresh_001"
}
```

### 4.3 退出登录

`POST /api/v1/auth/logout`

请求：

```json
{
  "refreshToken": "jwt_refresh_token"
}
```

响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": null,
  "requestId": "req_logout_001"
}
```

### 4.4 当前家长信息

`GET /api/v1/me`

响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "id": "parent_001",
    "name": "林女士",
    "phone": "138****2468",
    "relation": "妈妈",
    "avatarUrl": ""
  },
  "requestId": "req_me_001"
}
```

前端使用位置：我的页、首页问候。

## 5. 首页 Dashboard

### 5.1 获取首页聚合数据

`GET /api/v1/dashboard/today?childId=child_001&deviceId=duck-001&date=2026-06-30`

响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "greeting": "晚上好",
    "todaySummary": "今天孩子主要聊了恐龙、月亮和幼儿园午餐，情绪整体积极。",
    "device": {
      "id": "duck-001",
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
  "requestId": "req_dashboard_001"
}
```

前端使用位置：首页顶部问候、设备卡片、今日使用概览、今日对话摘要。

建议后端聚合返回，减少首页多接口等待。

## 6. 孩子资料

### 6.1 获取孩子列表

`GET /api/v1/children`

响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": [
    {
      "id": "child_001",
      "nickname": "小满",
      "age": 5,
      "gender": "女",
      "interests": ["恐龙", "绘本"],
      "focusAreas": ["语言表达", "情绪陪伴"]
    }
  ],
  "requestId": "req_children_001"
}
```

### 6.2 获取孩子详情

`GET /api/v1/children/{childId}`

### 6.3 更新孩子资料

`PUT /api/v1/children/{childId}`

请求：

```json
{
  "nickname": "小满",
  "age": 5,
  "gender": "女",
  "interests": ["恐龙", "绘本", "英语", "宇宙"],
  "focusAreas": ["语言表达", "情绪陪伴", "科普启蒙"]
}
```

响应：返回更新后的 `ChildProfile`。

前端使用位置：孩子资料页、我的页。

## 7. 设备管理

### 7.1 获取绑定设备列表

`GET /api/v1/devices?childId=child_001`

响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": [
    {
      "id": "duck-001",
      "name": "暖暖的小黄鸭",
      "serialNumber": "YD-AI-2026-0629",
      "isOnline": true,
      "batteryLevel": 82,
      "networkName": "Home-Kids-5G",
      "firmwareVersion": "v1.8.2",
      "volume": 0.58,
      "voiceName": "软萌小鸭音"
    }
  ],
  "requestId": "req_devices_001"
}
```

### 7.2 获取设备详情

`GET /api/v1/devices/{deviceId}`

响应：返回 `Device`。

### 7.3 更新设备设置

`PATCH /api/v1/devices/{deviceId}`

请求：

```json
{
  "name": "暖暖的小黄鸭",
  "volume": 0.65,
  "voiceName": "故事老师音"
}
```

响应：返回更新后的 `Device`。

前端使用位置：设备名称、音量 slider、音色选择。

### 7.4 绑定设备

`POST /api/v1/devices/bind`

请求：

```json
{
  "childId": "child_001",
  "bindCode": "123456",
  "deviceName": "暖暖的小黄鸭"
}
```

响应：返回 `Device`。

### 7.5 重新绑定设备

`POST /api/v1/devices/{deviceId}/rebind`

请求：

```json
{
  "bindCode": "123456"
}
```

响应：返回 `Device`。

### 7.6 解绑设备

`DELETE /api/v1/devices/{deviceId}`

响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": null,
  "requestId": "req_unbind_001"
}
```

### 7.7 检查固件更新

`POST /api/v1/devices/{deviceId}/firmware/check`

响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "hasUpdate": true,
    "currentVersion": "v1.8.2",
    "latestVersion": "v1.9.0",
    "releaseNotes": "优化夜间提醒与语音识别稳定性。"
  },
  "requestId": "req_firmware_001"
}
```

## 8. 对话记录

### 8.1 获取对话列表

`GET /api/v1/conversations`

查询参数：

| 参数 | 必填 | 示例 | 说明 |
| --- | --- | --- | --- |
| childId | 是 | child_001 | 孩子 ID |
| deviceId | 否 | duck-001 | 设备 ID |
| dateFrom | 否 | 2026-06-30 | 开始日期 |
| dateTo | 否 | 2026-06-30 | 结束日期 |
| emotion | 否 | curious | 情绪筛选 |
| riskLevel | 否 | attention | 风险筛选 |
| page | 否 | 1 | 页码 |
| pageSize | 否 | 20 | 每页数量 |

响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "items": [
      {
        "id": "c1",
        "childId": "child_001",
        "deviceId": "duck-001",
        "startedAt": "2026-06-30T19:42:00+09:00",
        "childSpeech": "月亮为什么会跟着我一起走呀？",
        "duckReply": "因为月亮离我们很远很远，所以你走的时候，它看起来像在温柔地陪着你。",
        "emotion": "curious",
        "riskLevel": "normal",
        "flagged": false
      }
    ],
    "page": 1,
    "pageSize": 20,
    "total": 18,
    "hasMore": false
  },
  "requestId": "req_conversations_001"
}
```

前端使用位置：对话记录页列表。

### 8.2 获取对话详情

`GET /api/v1/conversations/{conversationId}`

响应：返回完整 `ConversationRecord`，包含 `fullConversation`、`emotionAnalysis`、`safetyJudgement`、`parentNote`。

前端使用位置：对话详情页。

### 8.3 更新家长备注和关注标记

`PATCH /api/v1/conversations/{conversationId}`

请求：

```json
{
  "parentNote": "晚上和孩子聊聊陌生人边界。",
  "flagged": true
}
```

响应：返回更新后的 `ConversationRecord`。

前端使用位置：对话详情页“保存备注”“标记为需关注”。

### 8.4 获取今日 AI 摘要

如果首页不使用聚合接口，也可以提供单独接口：

`GET /api/v1/conversations/summary?childId=child_001&date=2026-06-30`

响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "summary": "今天孩子主要聊了恐龙、月亮和幼儿园午餐，情绪整体积极。",
    "mainTopics": ["恐龙", "月亮", "幼儿园午餐"],
    "overallEmotion": "positive",
    "attentionCount": 1
  },
  "requestId": "req_summary_001"
}
```

## 9. 安全守护

### 9.1 获取安全设置

`GET /api/v1/devices/{deviceId}/safety-settings`

响应：返回 `SafetySettings`。

### 9.2 更新安全设置

`PUT /api/v1/devices/{deviceId}/safety-settings`

请求：

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

响应：返回更新后的 `SafetySettings`。

前端使用位置：安全守护页所有开关、禁聊关键词、AI 回复风格。

### 9.3 添加禁聊关键词

`POST /api/v1/devices/{deviceId}/safety-settings/blocked-keywords`

请求：

```json
{
  "keyword": "危险游戏"
}
```

响应：返回更新后的关键词数组。

### 9.4 删除禁聊关键词

`DELETE /api/v1/devices/{deviceId}/safety-settings/blocked-keywords/{keyword}`

响应：返回更新后的关键词数组。

## 10. 使用时间管理

### 10.1 获取今日使用统计

`GET /api/v1/children/{childId}/usage/today?date=2026-06-30`

响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "conversationCount": 18,
    "companionMinutes": 42,
    "storyCount": 3,
    "learningInteractions": 6
  },
  "requestId": "req_usage_today_001"
}
```

### 10.2 获取使用时间设置

`GET /api/v1/devices/{deviceId}/usage-settings`

响应：返回 `UsageStats` 中的设置字段：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "maxDailyMinutes": 60,
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
  },
  "requestId": "req_usage_settings_001"
}
```

### 10.3 更新使用时间设置

`PUT /api/v1/devices/{deviceId}/usage-settings`

请求：

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

响应：返回更新后的设置。

### 10.4 暂停/恢复小黄鸭

`POST /api/v1/devices/{deviceId}/usage-settings/pause`

请求：

```json
{
  "paused": true
}
```

响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "paused": true
  },
  "requestId": "req_pause_001"
}
```

前端使用位置：使用时间管理页“一键暂停小黄鸭”。

## 11. 我的 / 设置

### 11.1 账号与安全入口

当前原型只做入口。后续建议接口：

- `GET /api/v1/account/security`：获取账号安全状态。
- `POST /api/v1/account/password/change`：修改密码。
- `POST /api/v1/account/phone/change`：更换手机号。
- `POST /api/v1/account/verification-code`：发送验证码。

### 11.2 协议文档

`GET /api/v1/legal-documents/{type}`

`type` 可选：

- `privacy`
- `terms`

查询参数：

| 参数 | 必填 | 说明 |
| --- | --- | --- |
| version | 否 | 指定版本，不传返回最新 |

响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "type": "privacy",
    "version": "2026-06-30",
    "title": "隐私政策",
    "content": "我们非常重视儿童语音数据与家庭信息的保护...",
    "effectiveAt": "2026-06-30T00:00:00+09:00"
  },
  "requestId": "req_legal_001"
}
```

前端使用位置：登录页、我的页的隐私政策和用户协议。

## 12. 用户反馈

### 12.1 提交反馈

`POST /api/v1/feedback`

请求：

```json
{
  "type": "feature",
  "content": "希望可以导出一周对话摘要。",
  "contact": "parent@example.com",
  "clientInfo": {
    "platform": "ios",
    "appVersion": "1.0.0",
    "deviceModel": "iPhone"
  }
}
```

`type` 建议枚举：

| 值 | 前端展示 |
| --- | --- |
| feature | 功能建议 |
| device | 设备问题 |
| conversation | 对话内容 |
| safety | 安全提醒 |
| other | 其他 |

响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "feedbackId": "fb_001",
    "submittedAt": "2026-06-30T10:30:00+09:00"
  },
  "requestId": "req_feedback_001"
}
```

前端使用位置：用户反馈页提交按钮。

## 13. 风险提醒与通知

当前原型没有单独通知页，但安全守护和首页的“需关注”可以预留接口。

### 13.1 获取提醒列表

`GET /api/v1/alerts?childId=child_001&status=unread&page=1&pageSize=20`

响应：

```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "items": [
      {
        "id": "alert_001",
        "type": "stranger_info",
        "title": "陌生人信息提醒",
        "content": "孩子提到了家庭地址相关问题，建议关注。",
        "conversationId": "c4",
        "status": "unread",
        "createdAt": "2026-06-30T20:12:00+09:00"
      }
    ],
    "page": 1,
    "pageSize": 20,
    "total": 1,
    "hasMore": false
  },
  "requestId": "req_alerts_001"
}
```

### 13.2 标记提醒已读

`PATCH /api/v1/alerts/{alertId}`

请求：

```json
{
  "status": "read"
}
```

## 14. 可选实时接口

设备在线状态、电量、Wi-Fi 状态可以用轮询，也可以用 WebSocket/SSE。

### 14.1 设备状态实时推送

`GET /api/v1/devices/{deviceId}/events`

建议使用 SSE，事件示例：

```text
event: device_status
data: {"deviceId":"duck-001","isOnline":true,"batteryLevel":81,"networkName":"Home-Kids-5G"}
```

前端可以先不接实时接口，用首页进入和下拉刷新时请求 `GET /devices/{deviceId}`。

## 15. 前端页面与接口映射

| 页面 | 主要接口 |
| --- | --- |
| 启动页 | 本地判断 Token，必要时调用 `/auth/refresh` |
| 登录页 | `POST /auth/login`，`GET /legal-documents/privacy`，`GET /legal-documents/terms` |
| 首页 Dashboard | `GET /dashboard/today` |
| 对话记录页 | `GET /conversations` |
| 对话详情页 | `GET /conversations/{id}`，`PATCH /conversations/{id}` |
| 安全守护页 | `GET /devices/{id}/safety-settings`，`PUT /devices/{id}/safety-settings` |
| 使用时间管理页 | `GET /children/{id}/usage/today`，`GET/PUT /devices/{id}/usage-settings`，`POST /usage-settings/pause` |
| 设备管理页 | `GET /devices/{id}`，`PATCH /devices/{id}`，`POST /firmware/check`，`DELETE /devices/{id}` |
| 孩子资料页 | `GET /children/{id}`，`PUT /children/{id}` |
| 我的 / 设置页 | `GET /me`，`POST /auth/logout` |
| 隐私政策 / 用户协议 | `GET /legal-documents/{type}` |
| 用户反馈页 | `POST /feedback` |

## 16. 后端落库建议

核心表或集合：

- `parents`：家长账号。
- `children`：孩子资料。
- `devices`：设备信息与绑定关系。
- `device_status_logs`：设备在线、电量、网络状态历史。
- `conversations`：对话摘要、完整文本、分析结果。
- `safety_settings`：安全守护配置。
- `usage_settings`：使用时间规则。
- `usage_daily_stats`：每日使用统计。
- `feedback`：用户反馈。
- `legal_documents`：协议和隐私政策版本。
- `alerts`：风险提醒。

## 17. 隐私与安全要求

本产品涉及儿童语音和对话文本，后端需要重点处理：

- 儿童数据最小化采集，只保存家长端必要展示字段。
- 对话文本、语音文件、家庭信息加密存储。
- 家长只能访问自己绑定的孩子和设备。
- 后台管理端访问儿童数据需要审计日志。
- 风险提醒不要在推送中暴露完整儿童语音内容。
- 提供数据删除、导出、撤回授权能力。
- 登录 Token 建议短有效期，Refresh Token 可撤销。

## 18. 第一阶段最小可接入接口

如果要最快把当前 Flutter 原型从 mock 切到真实后端，优先实现以下接口：

1. `POST /api/v1/auth/login`
2. `GET /api/v1/dashboard/today`
3. `GET /api/v1/conversations`
4. `GET /api/v1/conversations/{conversationId}`
5. `PATCH /api/v1/conversations/{conversationId}`
6. `GET /api/v1/devices/{deviceId}/safety-settings`
7. `PUT /api/v1/devices/{deviceId}/safety-settings`
8. `GET /api/v1/devices/{deviceId}/usage-settings`
9. `PUT /api/v1/devices/{deviceId}/usage-settings`
10. `GET /api/v1/devices/{deviceId}`
11. `PATCH /api/v1/devices/{deviceId}`
12. `GET /api/v1/children/{childId}`
13. `PUT /api/v1/children/{childId}`
14. `POST /api/v1/feedback`

这 14 个接口即可覆盖当前主要可点击页面。
