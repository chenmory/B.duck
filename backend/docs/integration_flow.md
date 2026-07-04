# 三端联调流程

## 1. 启动后端

PowerShell 默认可能禁止运行 `.ps1`，所以这里不使用：

```powershell
.\.venv\Scripts\Activate.ps1
```

请使用项目提供的 `.bat` 脚本：

```powershell
cd D:\code\dart\duck_parent_app\backend
.\scripts\install_deps.bat
```

然后编辑 `.env`，填好 MySQL 密码：

```text
MYSQL_DATABASE=yellow_duck
MYSQL_USER=root
MYSQL_PASSWORD=你的MySQL密码
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
```

在 MySQL 中创建数据库：

```sql
CREATE DATABASE IF NOT EXISTS yellow_duck
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
```

执行迁移和 demo 初始化：

```powershell
.\scripts\migrate_and_seed.bat
```

启动后端：

```powershell
.\scripts\runserver.bat
```

如果 `migrate` 报 MySQL 连接失败，先确认：

- MySQL 已安装并启动。
- `.env` 中 `MYSQL_HOST / MYSQL_PORT / MYSQL_USER / MYSQL_PASSWORD` 正确。
- 已创建数据库 `yellow_duck`。

## 2. 打开 AI 对话网页

```text
http://127.0.0.1:8000/chat/
```

输入：

```text
月亮为什么会跟着我走？
```

网页会调用：

```text
POST /api/v1/chat/messages
```

后端会写入：

- `core_conversation`
- `core_conversationutterance`
- `core_dailyusagestats`
- 必要时写入 `core_alert`

回复生成逻辑：

- 优先读取 `.env` 中的 `DEEPSEEK_API_KEY`，调用 DeepSeek 生成小黄鸭回复、情绪标签和风险标签。
- 如果 DeepSeek 不可用，自动回退到 `apps/core/services.py` 中的本地规则。
- 普通挫败情绪，例如“不开心、没拿到第一名”，应返回 `emotion=sad`、`riskLevel=normal`，家长端展示为“低落 / 正常”。

## 3. 家长端读取对话

家长端登录：

```text
POST /api/v1/auth/login
```

获取对话列表：

```text
GET /api/v1/conversations?childId=child_1&page=1&pageSize=20
```

获取详情：

```text
GET /api/v1/conversations/c_1
```

## 4. 数据流

```text
孩子/玩具模拟网页
  -> Django API
  -> MySQL
  -> 家长端 App API
  -> Flutter 页面展示
```

## 5. Flutter 已接入 API

当前 Flutter 已新增：

```text
lib/services/duck_api_service.dart
```

已接入：

- 登录页：调用 `POST /api/v1/auth/login`，失败时回退本地 mock。
- 首页：调用 `GET /api/v1/me`、`GET /api/v1/children`、`GET /api/v1/dashboard/today`。
- 对话记录页：调用 `GET /api/v1/conversations`。
- 对话详情页：调用 `GET /api/v1/conversations/{id}`。
- 对话详情备注/关注：调用 `PATCH /api/v1/conversations/{id}`。
- 安全守护页：调用 `GET/PUT /api/v1/devices/{deviceId}/safety-settings`，关键词新增/删除调用 blocked-keywords 接口。
- 使用时间页：调用 `GET/PUT /api/v1/devices/{deviceId}/usage-settings`，暂停/恢复调用 `POST /usage-settings/pause`。
- 设备管理页：调用 `GET /api/v1/devices`、`PATCH /api/v1/devices/{deviceId}`、`POST /firmware/check`，解绑调用 `DELETE /api/v1/devices/{deviceId}`。
- 孩子资料页：调用 `GET /api/v1/children`、`PUT /api/v1/children/{childId}`。
- 我的页：调用 `GET /api/v1/me`、`GET /api/v1/children`、`POST /api/v1/auth/logout`。
- 隐私政策/用户协议：调用 `GET /api/v1/legal-documents/privacy` 和 `GET /api/v1/legal-documents/terms`。
- 用户反馈页：调用 `POST /api/v1/feedback`。

仍保留本地 mock 作为后端离线兜底，便于原型演示不白屏。

正式版建议继续把 `DuckApiService` 拆成 `AuthService`、`DeviceRepository`、`ConversationRepository` 等领域仓储，并接入真实账号体系和设备鉴权。
