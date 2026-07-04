import 'package:flutter/material.dart';

import '../models/child_profile.dart';
import '../models/parent_user.dart';
import '../routes/app_routes.dart';
import '../services/duck_api_service.dart';
import '../services/mock_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/duck_avatar.dart';
import '../widgets/section_header.dart';
import '../widgets/setting_item.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  ParentUser _user = mockService.parentUser;
  ChildProfile _child = mockService.childProfile;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    setState(() => _loading = true);
    try {
      await duckApiService.ensureDemoLogin();
      final results = await Future.wait<dynamic>([
        duckApiService.fetchMe(),
        duckApiService.fetchPrimaryChild(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _user = results[0] as ParentUser;
        _child = results[1] as ChildProfile;
      });
    } catch (_) {
      if (mounted) {
        _toast(context, '后端账号信息暂不可用，当前显示本地 mock 数据');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logout(BuildContext context) async {
    await duckApiService.logout();
    if (!context.mounted) {
      return;
    }
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
          Text(
            '我的',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Row(
              children: [
                const DuckAvatar(size: 66),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_user.name} · ${_user.relation}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_user.phone}  管理 ${_child.nickname} 的小黄鸭',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(title: '家庭资料'),
          AppCard(
            child: Column(
              children: [
                SettingItem(
                  icon: Icons.child_friendly_rounded,
                  title: '孩子资料',
                  subtitle: '兴趣、年龄与重点关注方向',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.childProfile),
                ),
                const Divider(height: 1),
                SettingItem(
                  icon: Icons.security_rounded,
                  title: '账号与安全',
                  subtitle: '手机号、登录密码与设备验证',
                  onTap: () => _toast(context, '账号与安全将在正式版接入'),
                  iconColor: AppColors.skyBlue,
                ),
              ],
            ),
          ),
          const SectionHeader(title: '服务与支持'),
          AppCard(
            child: Column(
              children: [
                SettingItem(
                  icon: Icons.privacy_tip_outlined,
                  title: '隐私政策',
                  subtitle: '儿童语音数据如何被保护',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.privacy),
                ),
                const Divider(height: 1),
                SettingItem(
                  icon: Icons.description_outlined,
                  title: '用户协议',
                  subtitle: '使用规则与家长责任说明',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.terms),
                  iconColor: AppColors.skyBlue,
                ),
                const Divider(height: 1),
                SettingItem(
                  icon: Icons.headset_mic_outlined,
                  title: '联系我们',
                  subtitle: '客服时间 09:00 - 21:00',
                  onTap: () => _toast(context, '客服入口将在正式版接入'),
                  iconColor: AppColors.mint,
                ),
                const Divider(height: 1),
                SettingItem(
                  icon: Icons.feedback_outlined,
                  title: '用户反馈',
                  subtitle: '告诉我们你的建议或问题',
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.feedback),
                  iconColor: AppColors.warmOrange,
                ),
                const Divider(height: 1),
                SettingItem(
                  icon: Icons.info_outline_rounded,
                  title: '关于我们',
                  subtitle: '小黄鸭家长端 v1.0.0',
                  onTap: () => _toast(context, '当前为 Flutter App 原型'),
                  iconColor: AppColors.duckYellow,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('退出登录'),
          ),
        ],
      ),
    );
  }
}
