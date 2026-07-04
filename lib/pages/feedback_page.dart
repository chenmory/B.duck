import 'package:flutter/material.dart';

import '../services/duck_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _contentController = TextEditingController();
  final _contactController = TextEditingController();
  final _types = ['功能建议', '设备问题', '对话内容', '安全提醒', '其他'];
  String _type = '功能建议';
  bool _submitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请填写反馈内容')));
      return;
    }
    setState(() => _submitting = true);
    try {
      if (!duckApiService.isLoggedIn) {
        await duckApiService.ensureDemoLogin();
      }
      await duckApiService.submitFeedback(
        type: _type,
        content: _contentController.text.trim(),
        contact: _contactController.text.trim(),
      );
      _contentController.clear();
      _contactController.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('反馈已提交，感谢你的帮助')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('提交失败，请确认后端服务已启动')));
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('用户反馈')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            const SectionHeader(title: '反馈类型'),
            AppCard(
              child: DropdownButtonFormField<String>(
                initialValue: _type,
                items: [
                  for (final type in _types)
                    DropdownMenuItem(value: type, child: Text(type)),
                ],
                onChanged: (value) => setState(() => _type = value ?? _type),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
            ),
            const SectionHeader(title: '反馈内容'),
            TextField(
              controller: _contentController,
              minLines: 6,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: '请描述你遇到的问题、期待的能力或使用感受',
              ),
            ),
            const SectionHeader(title: '联系方式'),
            TextField(
              controller: _contactController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: '手机号 / 邮箱，可选',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: const Icon(Icons.send_rounded),
              label: Text(_submitting ? '提交中...' : '提交反馈'),
            ),
            const SizedBox(height: 12),
            Text(
              '反馈会提交到后端数据库，便于后续产品迭代整理。',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
