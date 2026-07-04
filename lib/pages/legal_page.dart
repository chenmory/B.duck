import 'package:flutter/material.dart';

import '../models/legal_document.dart';
import '../services/duck_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';

enum LegalType { privacy, terms }

class LegalPage extends StatefulWidget {
  const LegalPage({super.key, required this.type});

  final LegalType type;

  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  LegalDocument? _document;
  bool _loading = false;

  bool get _isPrivacy => widget.type == LegalType.privacy;

  String get _title => _isPrivacy ? '隐私政策' : '用户协议';

  String get _docType => _isPrivacy ? 'privacy' : 'terms';

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    setState(() => _loading = true);
    try {
      final document = await duckApiService.fetchLegalDocument(_docType);
      if (mounted) {
        setState(() => _document = document);
      }
    } catch (_) {
      // Keep the local placeholder text visible when the backend is offline.
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final document = _document;
    final content =
        document?.content ?? (_isPrivacy ? _privacyText : _termsText);

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
            AppCard(
              color: _isPrivacy
                  ? const Color(0xFFEAF8FF)
                  : const Color(0xFFFFF1BD),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      _isPrivacy
                          ? Icons.privacy_tip_rounded
                          : Icons.description_rounded,
                      color: _isPrivacy
                          ? AppColors.skyBlue
                          : AppColors.warmOrange,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _isPrivacy ? '儿童语音数据保护是产品设计的优先事项' : '家长端用于管理设备与查看陪伴记录',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        height: 1.35,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SectionHeader(
              title: document?.title ?? _title,
              subtitle: document == null
                  ? '当前为原型占位文案，正式版本需由法务审核'
                  : '版本 ${document.version}，正式版本仍需由法务审核',
            ),
            AppCard(
              child: Text(
                content,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _privacyText = '''
我们非常重视儿童语音数据与家庭信息的保护。

在正式产品中，小黄鸭家长端将仅在家长授权后收集必要数据，用于设备绑定、对话记录展示、安全风险提醒、使用时间管理和成长观察。儿童语音内容应经过安全存储、访问控制和最小化使用。

家长可以查看、管理、删除与孩子相关的记录，并可以关闭非必要功能。当前页面为原型占位，不构成完整法律文本。''';

const _termsText = '''
欢迎使用小黄鸭家长端。

本 App 用于帮助家长管理 AI 语音对话玩具，包括设备状态、对话记录、安全设置、使用时间和孩子资料。家长应确保绑定设备由家庭成员合理使用，并根据孩子年龄与家庭规则配置安全边界。

当前版本为产品原型，所有数据均为本地 mock 数据，不代表真实服务承诺。正式上线前，用户协议将补充账号、服务、数据、未成年人保护与免责声明等完整条款。''';
