import 'package:flutter/material.dart';

import '../models/usage_stats.dart';
import '../services/duck_api_service.dart';
import '../services/mock_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';
import '../widgets/setting_item.dart';

class UsageTimePage extends StatefulWidget {
  const UsageTimePage({super.key});

  @override
  State<UsageTimePage> createState() => _UsageTimePageState();
}

class _UsageTimePageState extends State<UsageTimePage> {
  late UsageStats _usage;
  String? _deviceId;
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _usage = mockService.usageStats;
    _loadUsage();
  }

  Future<void> _loadUsage() async {
    setState(() => _loading = true);
    try {
      await duckApiService.ensureDemoLogin();
      final device = await duckApiService.fetchPrimaryDevice();
      final usage = await duckApiService.fetchUsageSettings(device.id);
      if (!mounted) {
        return;
      }
      _deviceId = device.id;
      _updateLocal(usage);
    } catch (_) {
      if (mounted) {
        _toast('后端使用时间数据暂不可用，当前显示本地 mock 数据');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _updateLocal(UsageStats usage) {
    setState(() => _usage = usage);
    mockService.usageStats = usage;
  }

  Future<void> _saveUsage(UsageStats usage) async {
    _updateLocal(usage);
    final deviceId = _deviceId;
    if (deviceId == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await duckApiService.updateUsageSettings(deviceId, usage);
      if (mounted) {
        _updateLocal(
          updated.copyWith(
            conversationCount: usage.conversationCount,
            companionMinutes: usage.companionMinutes,
            storyCount: usage.storyCount,
            learningInteractions: usage.learningInteractions,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        _toast('使用时间设置已本地更新，后端保存失败');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _togglePause() async {
    final next = !_usage.paused;
    _updateLocal(_usage.copyWith(paused: next));
    final deviceId = _deviceId;
    if (deviceId == null) {
      return;
    }
    try {
      final paused = await duckApiService.pauseDevice(deviceId, next);
      if (mounted) {
        _updateLocal(_usage.copyWith(paused: paused));
      }
    } catch (_) {
      if (mounted) {
        _toast('暂停状态已本地更新，后端保存失败');
      }
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickSleepTime({required bool isStart}) async {
    final initial = parseTimeOfDay(
      isStart ? _usage.sleepStart : _usage.sleepEnd,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isStart ? '选择睡眠开始时间' : '选择睡眠结束时间',
    );
    if (picked == null) {
      return;
    }
    final formatted = formatTimeOfDay(picked);
    _saveUsage(
      isStart
          ? _usage.copyWith(sleepStart: formatted)
          : _usage.copyWith(sleepEnd: formatted),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_usage.companionMinutes / _usage.maxDailyMinutes).clamp(
      0.0,
      1.0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('使用时间管理')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            if (_loading || _saving)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
            AppCard(
              color: const Color(0xFFFFF1BD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: const Icon(
                          Icons.timer_rounded,
                          color: AppColors.warmOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '今日已使用 ${_usage.companionMinutes} 分钟',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '每日上限 ${_usage.maxDailyMinutes} 分钟',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.warmOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader(title: '每日最大使用时长'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${_usage.maxDailyMinutes} 分钟',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const Spacer(),
                      const Text(
                        '30 - 180 分钟',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                  Slider(
                    value: _usage.maxDailyMinutes.toDouble(),
                    min: 30,
                    max: 180,
                    divisions: 10,
                    label: '${_usage.maxDailyMinutes} 分钟',
                    onChanged: (value) => _updateLocal(
                      _usage.copyWith(maxDailyMinutes: value.round()),
                    ),
                    onChangeEnd: (value) => _saveUsage(
                      _usage.copyWith(maxDailyMinutes: value.round()),
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader(title: '睡眠时间段'),
            AppCard(
              child: Column(
                children: [
                  SettingItem(
                    icon: Icons.bedtime_rounded,
                    title: '开始时间',
                    subtitle: _usage.sleepStart,
                    onTap: () => _pickSleepTime(isStart: true),
                  ),
                  const Divider(height: 1),
                  SettingItem(
                    icon: Icons.wb_sunny_rounded,
                    title: '结束时间',
                    subtitle: _usage.sleepEnd,
                    iconColor: AppColors.skyBlue,
                    onTap: () => _pickSleepTime(isStart: false),
                  ),
                  const Divider(height: 1),
                  SettingItem(
                    icon: Icons.airline_seat_individual_suite_rounded,
                    title: '午休勿扰',
                    subtitle: '午休时段仅保留必要提醒',
                    iconColor: AppColors.mint,
                    trailing: Switch(
                      value: _usage.napDoNotDisturb,
                      onChanged: (value) =>
                          _saveUsage(_usage.copyWith(napDoNotDisturb: value)),
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader(title: '周使用计划'),
            AppCard(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final day in _usage.weeklyPlan.keys)
                    FilterChip(
                      label: Text('周$day'),
                      selected: _usage.weeklyPlan[day] ?? false,
                      onSelected: (selected) {
                        final plan = Map<String, bool>.from(_usage.weeklyPlan);
                        plan[day] = selected;
                        _saveUsage(_usage.copyWith(weeklyPlan: plan));
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _togglePause,
              icon: Icon(
                _usage.paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              ),
              label: Text(_usage.paused ? '恢复小黄鸭' : '一键暂停小黄鸭'),
            ),
          ],
        ),
      ),
    );
  }
}
