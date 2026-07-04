# 小黄鸭家长端

面向家长的 Flutter App 原型，用于管理孩子的小黄鸭 AI 语音对话玩具。

## 运行

```powershell
cd D:\code\dart\duck_parent_app
flutter run -d chrome
```

也可以使用本地 Web 预览：

```text
http://127.0.0.1:8087
```

## 目录

```text
lib/
├── main.dart
├── app.dart
├── theme/
├── routes/
├── models/
├── services/
├── pages/
├── widgets/
└── utils/
```

## 数据

当前所有数据来自 `lib/services/mock_service.dart`，包括设备、孩子资料、对话记录、安全设置、使用时间和家长账号。

后续接入真实后端时，优先替换 service 层，并保持页面依赖 models，不直接依赖网络实现。

接口文档见 `docs/backend_api.md`。

Django 后端代码位于 `backend/`，三端接口文档见：

- `backend/docs/backend_database_and_service.md`
- `backend/docs/parent_app_api.md`
- `backend/docs/chat_web_api.md`
