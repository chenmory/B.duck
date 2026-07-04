import 'package:flutter/material.dart';

import '../models/conversation_record.dart';
import '../services/duck_api_service.dart';
import '../services/mock_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';
import '../widgets/tag_chip.dart';

class ConversationDetailPage extends StatefulWidget {
  const ConversationDetailPage({super.key, required this.record});

  final ConversationRecord? record;

  @override
  State<ConversationDetailPage> createState() => _ConversationDetailPageState();
}

class _ConversationDetailPageState extends State<ConversationDetailPage> {
  late ConversationRecord? _record;
  late final TextEditingController _noteController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _record = widget.record == null
        ? null
        : (mockService.findConversation(widget.record!.id) ?? widget.record);
    _noteController = TextEditingController(text: _record?.parentNote ?? '');
    _loadRemoteDetail();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadRemoteDetail() async {
    final record = widget.record;
    if (record == null) {
      return;
    }
    setState(() => _loading = true);
    try {
      await duckApiService.ensureDemoLogin();
      final detail = await duckApiService.fetchConversationDetail(record.id);
      if (!mounted) {
        return;
      }
      setState(() => _record = detail);
      _noteController.text = detail.parentNote;
    } catch (_) {
      // Keep local or list-level data visible if backend detail is unavailable.
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveNote() async {
    final record = _record;
    if (record == null) {
      return;
    }
    final note = _noteController.text.trim();
    try {
      final updated = duckApiService.isLoggedIn
          ? await duckApiService.updateConversation(
              id: record.id,
              parentNote: note,
            )
          : record.copyWith(parentNote: note);
      if (!duckApiService.isLoggedIn) {
        mockService.updateConversation(updated);
      }
      if (!mounted) {
        return;
      }
      setState(() => _record = updated);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('备注已保存')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存失败，请检查后端服务')));
      }
    }
  }

  Future<void> _toggleFlag() async {
    final record = _record;
    if (record == null) {
      return;
    }
    final flagged = !record.flagged;
    try {
      final updated = duckApiService.isLoggedIn
          ? await duckApiService.updateConversation(
              id: record.id,
              flagged: flagged,
            )
          : record.copyWith(
              flagged: flagged,
              riskLevel: flagged ? '需关注' : '正常',
            );
      if (!duckApiService.isLoggedIn) {
        mockService.updateConversation(updated);
      }
      if (!mounted) {
        return;
      }
      setState(() => _record = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(updated.flagged ? '已标记为需关注' : '已取消关注标记')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('操作失败，请检查后端服务')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = _record;
    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('对话详情')),
        body: const Center(child: Text('未找到对话记录')),
      );
    }

    final riskColor = record.riskLevel == '需关注' || record.riskLevel == '高风险'
        ? AppColors.attention
        : AppColors.success;

    return Scaffold(
      appBar: AppBar(title: const Text('对话详情')),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formatDateTime(record.time),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TagChip(label: record.emotion, color: AppColors.skyBlue),
                      const SizedBox(width: 8),
                      TagChip(label: record.riskLevel, color: riskColor),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    record.fullConversation,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.65),
                  ),
                ],
              ),
            ),
            const SectionHeader(title: '情绪分析'),
            AppCard(
              child: _InsightRow(
                icon: Icons.mood_rounded,
                color: AppColors.warmOrange,
                text: record.emotionAnalysis,
              ),
            ),
            const SectionHeader(title: '安全判断'),
            AppCard(
              child: _InsightRow(
                icon: Icons.verified_user_rounded,
                color: riskColor,
                text: record.safetyJudgement,
              ),
            ),
            const SectionHeader(title: '家长备注'),
            TextField(
              controller: _noteController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(hintText: '记录你想继续了解或跟孩子聊聊的点'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _toggleFlag,
              icon: Icon(
                record.flagged
                    ? Icons.bookmark_remove_rounded
                    : Icons.bookmark_add_rounded,
              ),
              label: Text(record.flagged ? '取消关注标记' : '标记为需关注'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _saveNote,
              icon: const Icon(Icons.save_outlined),
              label: const Text('保存备注'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.55),
          ),
        ),
      ],
    );
  }
}
