import 'package:flutter/material.dart';

import '../models/conversation_record.dart';
import '../routes/app_routes.dart';
import '../services/duck_api_service.dart';
import '../services/mock_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';
import '../widgets/tag_chip.dart';

class ConversationRecordsPage extends StatefulWidget {
  const ConversationRecordsPage({super.key, required this.showAppBar});

  final bool showAppBar;

  @override
  State<ConversationRecordsPage> createState() =>
      _ConversationRecordsPageState();
}

class _ConversationRecordsPageState extends State<ConversationRecordsPage> {
  int _filterIndex = 0;
  final _filters = ['今天', '昨天', '本周'];
  List<ConversationRecord>? _remoteRecords;
  bool _loading = false;
  String? _remoteError;

  @override
  void initState() {
    super.initState();
    _loadRemoteRecords();
  }

  Future<void> _loadRemoteRecords() async {
    setState(() {
      _loading = true;
      _remoteError = null;
    });
    try {
      await duckApiService.ensureDemoLogin();
      final records = await duckApiService.fetchConversations();
      if (!mounted) {
        return;
      }
      setState(() => _remoteRecords = records);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _remoteError = '后端对话记录暂不可用，当前显示本地 mock 数据');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<ConversationRecord> get _records {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final records = _remoteRecords ?? mockService.conversationRecords;
    switch (_filterIndex) {
      case 0:
        return records.where((record) {
          final day = DateTime(
            record.time.year,
            record.time.month,
            record.time.day,
          );
          return day == today;
        }).toList();
      case 1:
        final yesterday = today.subtract(const Duration(days: 1));
        return records.where((record) {
          final day = DateTime(
            record.time.year,
            record.time.month,
            record.time.day,
          );
          return day == yesterday;
        }).toList();
      default:
        return records;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      top: !widget.showAppBar,
      child: RefreshIndicator(
        onRefresh: _loadRemoteRecords,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            if (!widget.showAppBar) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '对话记录',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: '刷新',
                    onPressed: _loading ? null : _loadRemoteRecords,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _remoteRecords == null
                    ? '快速扫读孩子和小黄鸭的语音互动'
                    : '已连接后端，显示数据库中的真实对话记录',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            ],
            if (_remoteError != null) ...[
              const SizedBox(height: 12),
              AppCard(
                color: const Color(0xFFFFF1BD),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.warmOrange,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_remoteError!)),
                  ],
                ),
              ),
            ],
            const SectionHeader(title: '日期筛选'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < _filters.length; i++)
                  ChoiceChip(
                    label: Text(_filters[i]),
                    selected: _filterIndex == i,
                    onSelected: (_) => setState(() => _filterIndex = i),
                  ),
              ],
            ),
            SectionHeader(
              title: '对话列表',
              subtitle: _loading ? '正在同步后端数据...' : '共 ${_records.length} 条记录',
            ),
            if (_records.isEmpty)
              const AppCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 26),
                    child: Text('当前日期暂无对话记录'),
                  ),
                ),
              )
            else
              ..._records.map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ConversationTile(record: record),
                ),
              ),
          ],
        ),
      ),
    );

    if (!widget.showAppBar) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('对话记录'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: _loading ? null : _loadRemoteRecords,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: body,
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.record});

  final ConversationRecord record;

  Color get _emotionColor {
    switch (record.emotion) {
      case '开心':
        return AppColors.success;
      case '好奇':
        return AppColors.skyBlue;
      case '低落':
        return AppColors.warmOrange;
      case '害怕':
        return AppColors.attention;
      default:
        return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = record.riskLevel == '需关注' || record.riskLevel == '高风险'
        ? AppColors.attention
        : AppColors.success;

    return AppCard(
      onTap: () => Navigator.of(
        context,
      ).pushNamed(AppRoutes.conversationDetail, arguments: record),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 18, color: AppColors.muted),
              const SizedBox(width: 6),
              Text(
                '${formatDate(record.time)} ${formatClock(record.time)}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TagChip(label: record.emotion, color: _emotionColor),
              const SizedBox(width: 6),
              TagChip(label: record.riskLevel, color: riskColor),
            ],
          ),
          const SizedBox(height: 14),
          _SpeechLine(
            icon: Icons.child_care_rounded,
            label: '孩子',
            text: record.childSpeech,
            color: AppColors.duckYellow,
          ),
          const SizedBox(height: 10),
          _SpeechLine(
            icon: Icons.smart_toy_outlined,
            label: '小黄鸭',
            text: record.duckReply,
            color: AppColors.skyBlue,
          ),
        ],
      ),
    );
  }
}

class _SpeechLine extends StatelessWidget {
  const _SpeechLine({
    required this.icon,
    required this.label,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$label：',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
