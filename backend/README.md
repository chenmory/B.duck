# 小黄鸭 Django 后端

这是小黄鸭家长端原型配套后端，使用 Django + MySQL。

## 你刚遇到的 PowerShell 报错

如果运行：

```powershell
.\.venv\Scripts\Activate.ps1
```

提示“禁止运行脚本 / Execution Policies”，不用改系统策略。直接使用下面这些 `.bat` 脚本即可，它们会显式调用：

```text
.venv\Scripts\python.exe
```

所以不需要激活虚拟环境。

## 第一次运行

```powershell
cd D:\code\dart\duck_parent_app\backend
.\scripts\install_deps.bat
```

## 最快跑通三端联调，不安装 MySQL

如果你只是想先看到聊天网页、后端入库、家长端读取这条链路，可以先用 SQLite 开发模式：

```powershell
.\scripts\run_dev_sqlite.bat
```

然后打开：

```text
http://127.0.0.1:8000/chat/
```

这个模式会使用 `backend/db.sqlite3`，不需要 MySQL。正式按需求使用 MySQL 时，再看下一节。

## 使用 MySQL 运行

然后编辑 `.env`，把 MySQL 密码改成你的本机密码：

```text
DATABASE_ENGINE=mysql
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

也可以直接使用：

```text
backend/sql/create_database.sql
```

## 迁移和初始化 demo 数据

```powershell
.\scripts\migrate_and_seed.bat
```

## 启动后端

```powershell
.\scripts\runserver.bat
```

启动后打开：

```text
http://127.0.0.1:8000/chat/
```

家长端 API 前缀：

```text
http://127.0.0.1:8000/api/v1
```

## Demo 账号

```text
账号：demo_parent
密码：123456
```

聊天网页会自动使用 demo 账号登录。它发送的每条消息都会写入 `Conversation` 和 `ConversationUtterance`，家长端通过对话记录接口即可读取。

## DeepSeek AI 回复

后端已支持通过 DeepSeek 生成小黄鸭回复、情绪标签和风险标签。配置在 `.env`：

```text
AI_CHAT_ENABLED=true
DEEPSEEK_API_KEY=你的DeepSeek API Key
DEEPSEEK_BASE_URL=https://api.deepseek.com
DEEPSEEK_MODEL=deepseek-v4-flash
DEEPSEEK_TIMEOUT_SECONDS=20
```

调用位置：

```text
apps/core/ai_client.py
apps/core/services.py
```

如果 DeepSeek 请求失败、超时或没有配置 Key，后端会自动回退到本地规则，聊天网页和家长端不会因此中断。

如果需要重算数据库里已有对话的情绪/风险标签：

```powershell
.\.venv\Scripts\python.exe manage.py reanalyze_conversations
```

## 常见问题

### ModuleNotFoundError: No module named 'pymysql'

说明你运行的是系统 Python，不是项目虚拟环境。请使用：

```powershell
.\scripts\install_deps.bat
.\scripts\migrate_and_seed.bat
.\scripts\runserver.bat
```

或者手动使用：

```powershell
.\.venv\Scripts\python.exe manage.py check
```

### Can't connect to MySQL server on '127.0.0.1'

说明 MySQL 没启动、没安装，或者 `.env` 里的账号密码不对。先确认 MySQL 服务正在运行，并且已创建 `yellow_duck` 数据库。

## 文档

- 后端服务与数据库：`docs/backend_database_and_service.md`
- 家长端 App 接口：`docs/parent_app_api.md`
- AI 对话网页接口：`docs/chat_web_api.md`
- 三端联调流程：`docs/integration_flow.md`
