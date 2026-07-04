import 'package:flutter/material.dart';

import '../models/child_profile.dart';
import '../models/dashboard_snapshot.dart';
import '../models/device.dart';
import '../models/parent_user.dart';
import '../routes/app_routes.dart';
import '../services/duck_api_service.dart';
import '../services/mock_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/duck_avatar.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/tag_chip.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.onSwitchTab});

  final ValueChanged<int> onSwitchTab;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DashboardSnapshot? _snapshot;
  ParentUser _parent = mockService.parentUser;
  ChildProfile _child = mockService.childProfile;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '早上好';
    }
    if (hour < 18) {
      return '下午好';
    }
    return '晚上好';
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await duckApiService.ensureDemoLogin();
      final results = await Future.wait<dynamic>([
        duckApiService.fetchMe(),
        duckApiService.fetchPrimaryChild(),
        duckApiService.fetchDashboardToday(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _parent = results[0] as ParentUser;
        _child = results[1] as ChildProfile;
        _snapshot = results[2] as DashboardSnapshot;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _error = '后端首页数据暂不可用，当前显示本地 mock 数据');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final usage = snapshot?.usage ?? mockService.usageStats;
    final device = snapshot?.device ?? mockService.device;
    final summary = snapshot?.todaySummary ?? mockService.todaySummary;
    final attentionCount = snapshot?.attentionCount ?? 0;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            _GreetingCard(
              title: '${snapshot?.greeting ?? _greeting}，${_parent.name}',
              subtitle:
                  '今天小鸭陪伴了${_child.nickname} ${usage.companionMinutes} 分钟',
              loading: _loading,
              onRefresh: _loading ? null : _loadDashboard,
            ),
            if (_error != null) ...[
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
                    Expanded(child: Text(_error!)),
                  ],
                ),
              ),
            ],
            const SectionHeader(title: '绑定设备', subtitle: '在线状态与电量一眼可见'),
            _DeviceStatusCard(device: device),
            const SectionHeader(title: '今日使用概览'),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 1.28,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatCard(
                  title: '今日对话',
                  value: '${usage.conversationCount} 次',
                  icon: Icons.record_voice_over_rounded,
                  color: AppColors.skyBlue,
                ),
                StatCard(
                  title: '陪伴时长',
                  value: '${usage.companionMinutes} 分',
                  icon: Icons.timer_rounded,
                  color: AppColors.warmOrange,
                ),
                StatCard(
                  title: '故事次数',
                  value: '${usage.storyCount} 次',
                  icon: Icons.auto_stories_rounded,
                  color: AppColors.mint,
                ),
                StatCard(
                  title: '学习互动',
                  value: '${usage.learningInteractions} 次',
                  icon: Icons.school_rounded,
                  color: AppColors.duckYellow,
                ),
              ],
            ),
            const SectionHeader(
              title: '今天聊了什么',
              subtitle: 'AI 摘要帮助家长快速了解孩子关注点',
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.skyBlue.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.skyBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '今日对话摘要',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      TagChip(
                        label: attentionCount > 0
                            ? '$attentionCount 条需关注'
                            : '情绪稳定',
                        color: attentionCount > 0
                            ? AppColors.attention
                            : AppColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    summary,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.55,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader(title: '快捷入口'),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              childAspectRatio: 1.8,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _QuickEntry(
                  icon: Icons.forum_rounded,
                  title: '对话记录',
                  color: AppColors.skyBlue,
                  onTap: () => widget.onSwitchTab(1),
                ),
                _QuickEntry(
                  icon: Icons.shield_rounded,
                  title: '安全设置',
                  color: AppColors.success,
                  onTap: () => widget.onSwitchTab(2),
                ),
                _QuickEntry(
                  icon: Icons.schedule_rounded,
                  title: '使用时间',
                  color: AppColors.warmOrange,
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.usage),
                ),
                _QuickEntry(
                  icon: Icons.devices_other_rounded,
                  title: '设备管理',
                  color: AppColors.duckYellow,
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.device),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.onRefresh,
  });

  final String title;
  final String subtitle;
  final bool loading;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE58A), Color(0xFFFFF8E7)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmOrange.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          const DuckAvatar(size: 74, showBadge: true),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.72),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: loading ? '同步中' : '刷新首页',
            onPressed: onRefresh,
            icon: loading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _DeviceStatusCard extends StatelessWidget {
  const _DeviceStatusCard({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              const DuckAvatar(size: 58, showBadge: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        TagChip(
                          label: device.isOnline ? '在线' : '离线',
                          color: device.isOnline
                              ? AppColors.success
                              : AppColors.muted,
                          icon: Icons.circle,
                        ),
                        TagChip(
                          label: device.networkName,
                          color: AppColors.skyBlue,
                          icon: Icons.wifi_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.battery_5_bar_rounded, color: AppColors.success),
              const SizedBox(width: 8),
              Text(
                '电量 ${device.batteryLevel}%',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: device.batteryLevel / 100,
                    minHeight: 9,
                    backgroundColor: AppColors.success.withValues(alpha: 0.14),
                    valueColor: const AlwaysStoppedAnimation(AppColors.success),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickEntry extends StatelessWidget {
  const _QuickEntry({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
