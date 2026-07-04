# 后端服务与数据库文档

## 1. 技术栈

- Python 3.12
- Django 5.2
- MySQL 8.x
- PyMySQL
- JSON API，不依赖 DRF，便于第一版快速交付

## 2. 目录结构

```text
backend/
├── manage.py
├── requirements.txt
├── .env.example
├── duck_backend/
│   ├── settings.py
│   ├── urls.py
│   ├── asgi.py
│   └── wsgi.py
├── apps/core/
│   ├── models.py
│   ├── views.py
│   ├── urls.py
│   ├── serializers.py
│   ├── services.py
│   ├── admin.py
│   ├── migrations/
│   └── management/commands/seed_demo.py
├── templates/chat/index.html
└── docs/
```

## 3. 本地启动

```powershell
cd D:\code\dart\duck_parent_app\backend
.\scripts\install_deps.bat
```

创建 MySQL 数据库：

```sql
CREATE DATABASE yellow_duck CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

修改 `.env`：

```text
MYSQL_DATABASE=yellow_duck
MYSQL_USER=root
MYSQL_PASSWORD=你的密码
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
```

迁移并初始化 demo 数据：

```powershell
.\scripts\migrate_and_seed.bat
.\scripts\runserver.bat
```

## 4. 数据表设计

### 4.1 parents / auth_user

Django 自带 `auth_user` 保存账号密码。扩展表 `core_parentprofile` 保存家长资料。

核心字段：

- `user_id`
- `name`
- `phone`
- `relation`
- `avatar_url`

### 4.2 core_childprofile

孩子资料。

- `parent_id`
- `nickname`
- `age`
- `gender`
- `interests` JSON
- `focus_areas` JSON

### 4.3 core_device

小黄鸭设备。

- `child_id`
- `name`
- `serial_number`
- `is_online`
- `battery_level`
- `network_name`
- `firmware_version`
- `volume`
- `voice_name`
- `last_online_at`

### 4.4 core_safetysettings

安全守护设置，一台设备一条。

- `device_id`
- `sensitive_topic_filter`
- `stranger_info_alert`
- `negative_emotion_alert`
- `night_usage_alert`
- `blocked_keywords` JSON
- `reply_style`

### 4.5 core_usagesettings

使用时间设置，一台设备一条。

- `device_id`
- `max_daily_minutes`
- `sleep_start`
- `sleep_end`
- `nap_do_not_disturb`
- `weekly_plan` JSON
- `paused`

### 4.6 core_dailyusagestats

每日使用统计。

- `child_id`
- `date`
- `conversation_count`
- `companion_minutes`
- `story_count`
- `learning_interactions`

唯一约束：`child_id + date`。

### 4.7 core_conversation

一轮孩子和小黄鸭的对话摘要。

- `child_id`
- `device_id`
- `started_at`
- `ended_at`
- `child_speech`
- `duck_reply`
- `emotion`
- `risk_level`
- `full_conversation`
- `emotion_analysis`
- `safety_judgement`
- `parent_note`
- `flagged`
- `tags` JSON

### 4.8 core_conversationutterance

完整对话明细，按 speaker 存每句话。

- `conversation_id`
- `speaker`: child / duck
- `content`
- `created_at`

### 4.9 core_alert

风险提醒。

- `child_id`
- `conversation_id`
- `type`
- `title`
- `content`
- `status`

### 4.10 core_feedback

用户反馈。

- `parent_id`
- `type`
- `content`
- `contact`
- `client_info` JSON

### 4.11 core_legaldocument

隐私政策和用户协议。

- `type`
- `version`
- `title`
- `content`
- `effective_at`
- `is_latest`

## 5. 数据流

```text
AI 对话网页
  -> POST /api/v1/chat/messages
  -> Django 生成 mock 小黄鸭回复
  -> 写入 Conversation / ConversationUtterance / DailyUsageStats / Alert
  -> 家长端 App
  -> GET /api/v1/conversations
  -> GET /api/v1/conversations/{conversationId}
```

## 6. Demo 账号

```text
账号：demo_parent
密码：123456
```

`.\scripts\migrate_and_seed.bat` 会执行迁移，并调用 `seed_demo` 创建家长、孩子、设备、安全设置、使用时间设置和协议文档。

## 7. 认证

当前第一版使用 Django signing 生成原型 Token：

- `accessToken`: 默认 7200 秒
- `refreshToken`: 默认 30 天

生产环境建议替换为标准 JWT 或 OAuth2，并引入 Token 黑名单、设备绑定、刷新 Token 轮换。

## 8. 注意事项

- 当前 mock AI 回复在 `apps/core/services.py` 的 `generate_duck_reply`。
- 真实大模型接入时可替换 `generate_duck_reply`，但仍调用 `create_chat_conversation` 统一入库。
- 儿童语音原始音频尚未建表；如果后续保存音频，建议新增 `ConversationAudio`，音频文件放对象存储，数据库只存 URL、时长、hash 和权限元数据。
