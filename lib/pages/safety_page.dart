import 'package:flutter/material.dart';

import '../models/safety_settings.dart';
import '../services/duck_api_service.dart';
import '../services/mock_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';
import '../widgets/setting_item.dart';

class SafetyPage extends StatefulWidget {
  const SafetyPage({super.key, required this.showAppBar});

  final bool showAppBar;

  @override
  State<SafetyPage> createState() => _SafetyPageState();
}

class _SafetyPageState extends State<SafetyPage> {
  late SafetySettings _settings;
  final _replyStyles = ['温柔陪伴', '知识启蒙', '故事模式', '简短回答'];
  String? _deviceId;
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _settings = mockService.safetySettings;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    try {
      await duckApiService.ensureDemoLogin();
      final device = await duckApiService.fetchPrimaryDevice();
      final settings = await duckApiService.fetchSafetySettings(device.id);
      if (!mounted) {
        return;
      }
      _deviceId = device.id;
      _updateLocal(settings);
    } catch (_) {
      if (mounted) {
        _toast('后端安全设置暂不可用，当前显示本地 mock 数据');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _updateLocal(SafetySettings settings) {
    setState(() => _settings = settings);
    mockService.safetySettings = settings;
  }

  Future<void> _saveSettings(SafetySettings settings) async {
    _updateLocal(settings);
    final deviceId = _deviceId;
    if (deviceId == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await duckApiService.updateSafetySettings(
        deviceId,
        settings,
      );
      if (mounted) {
        _updateLocal(updated);
      }
    } catch (_) {
      if (mounted) {
        _toast('安全设置已本地更新，后端保存失败');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addKeyword() async {
    final controller = TextEditingController();
    final keyword = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加禁聊关键词'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '例如：危险游戏'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('添加'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (keyword == null || keyword.isEmpty) {
      return;
    }
    final keywords = [..._settings.blockedKeywords];
    if (!keywords.contains(keyword)) {
      keywords.add(keyword);
      _updateLocal(_settings.copyWith(blockedKeywords: keywords));
      final deviceId = _deviceId;
      if (deviceId != null) {
        try {
          final remoteKeywords = await duckApiService.addBlockedKeyword(
            deviceId,
            keyword,
          );
          if (mounted) {
            _updateLocal(_settings.copyWith(blockedKeywords: remoteKeywords));
          }
        } catch (_) {
          if (mounted) {
            _toast('关键词已本地添加，后端保存失败');
          }
        }
      }
    }
  }

  Future<void> _deleteKeyword(String keyword) async {
    final keywords = [..._settings.blockedKeywords]..remove(keyword);
    _updateLocal(_settings.copyWith(blockedKeywords: keywords));
    final deviceId = _deviceId;
    if (deviceId == null) {
      return;
    }
    try {
      final remoteKeywords = await duckApiService.deleteBlockedKeyword(
        deviceId,
        keyword,
      );
      if (mounted) {
        _updateLocal(_settings.copyWith(blockedKeywords: remoteKeywords));
      }
    } catch (_) {
      if (mounted) {
        _toast('关键词已本地删除，后端保存失败');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      top: !widget.showAppBar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          if (_loading || _saving)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
          if (!widget.showAppBar) ...[
            Text(
              '安全守护',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '用温和边界守住孩子的对话空间',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ],
          const SectionHeader(title: '风险提醒'),
          AppCard(
            child: Column(
              children: [
                SettingItem(
                  icon: Icons.filter_alt_rounded,
                  title: '敏感话题过滤',
                  subtitle: '自动避开不适合儿童展开的话题',
                  trailing: Switch(
                    value: _settings.sensitiveTopicFilter,
                    onChanged: (value) => _saveSettings(
                      _settings.copyWith(sensitiveTopicFilter: value),
                    ),
                  ),
                ),
                const Divider(height: 1),
                SettingItem(
                  icon: Icons.contact_emergency_rounded,
                  title: '陌生人信息提醒',
                  subtitle: '出现地址、电话、陌生人邀请时提醒家长',
                  trailing: Switch(
                    value: _settings.strangerInfoAlert,
                    onChanged: (value) => _saveSettings(
                      _settings.copyWith(strangerInfoAlert: value),
                    ),
                  ),
                  iconColor: AppColors.skyBlue,
                ),
                const Divider(height: 1),
                SettingItem(
                  icon: Icons.sentiment_dissatisfied_rounded,
                  title: '消极情绪提醒',
                  subtitle: '持续低落、害怕或求助表达会被标记',
                  trailing: Switch(
                    value: _settings.negativeEmotionAlert,
                    onChanged: (value) => _saveSettings(
                      _settings.copyWith(negativeEmotionAlert: value),
                    ),
                  ),
                  iconColor: AppColors.warmOrange,
                ),
                const Divider(height: 1),
                SettingItem(
                  icon: Icons.nightlight_round,
                  title: '夜间使用提醒',
                  subtitle: '睡眠时段使用会提示家长',
                  trailing: Switch(
                    value: _settings.nightUsageAlert,
                    onChanged: (value) => _saveSettings(
                      _settings.copyWith(nightUsageAlert: value),
                    ),
                  ),
                  iconColor: AppColors.mint,
                ),
              ],
            ),
          ),
          SectionHeader(
            title: '禁聊关键词',
            subtitle: '小黄鸭会把相关话题转向安全、积极的表达',
            actionLabel: '添加',
            onAction: _addKeyword,
          ),
          AppCard(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final keyword in _settings.blockedKeywords)
                  InputChip(
                    label: Text(keyword),
                    onDeleted: () => _deleteKeyword(keyword),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('添加关键词'),
                  onPressed: _addKeyword,
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'AI 回复风格'),
          AppCard(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final style in _replyStyles)
                  ChoiceChip(
                    label: Text(style),
                    selected: _settings.replyStyle == style,
                    onSelected: (_) =>
                        _saveSettings(_settings.copyWith(replyStyle: style)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!widget.showAppBar) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('安全守护')),
      body: body,
    );
  }
}
