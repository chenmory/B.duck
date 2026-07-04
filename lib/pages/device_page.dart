import 'package:flutter/material.dart';

import '../models/device.dart';
import '../services/duck_api_service.dart';
import '../services/mock_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/duck_avatar.dart';
import '../widgets/section_header.dart';
import '../widgets/setting_item.dart';
import '../widgets/tag_chip.dart';

class DevicePage extends StatefulWidget {
  const DevicePage({super.key});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  late Device _device;
  final _voices = ['软萌小鸭音', '温柔姐姐音', '故事老师音', '英文启蒙音'];
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _device = mockService.device;
    _loadDevice();
  }

  Future<void> _loadDevice() async {
    setState(() => _loading = true);
    try {
      await duckApiService.ensureDemoLogin();
      final device = await duckApiService.fetchPrimaryDevice();
      if (!mounted) {
        return;
      }
      _updateLocal(device);
    } catch (_) {
      if (mounted) {
        _toast('后端设备数据暂不可用，当前显示本地 mock 数据');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _updateLocal(Device device) {
    setState(() => _device = device);
    mockService.device = device;
  }

  Future<void> _saveDevice(Device device) async {
    _updateLocal(device);
    setState(() => _saving = true);
    try {
      await duckApiService.ensureDemoLogin();
      final updated = await duckApiService.updateDevice(device);
      if (!mounted) {
        return;
      }
      _updateLocal(updated);
    } catch (_) {
      if (mounted) {
        _toast('设备设置已本地更新，后端保存失败');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _checkFirmware() async {
    try {
      await duckApiService.ensureDemoLogin();
      final result = await duckApiService.checkFirmware(_device.id);
      if (!mounted) {
        return;
      }
      _toast(
        result.hasUpdate
            ? '发现 ${result.latestVersion}：${result.releaseNotes}'
            : '当前已是最新版本 ${result.currentVersion}',
      );
    } catch (_) {
      if (mounted) {
        _toast('检查更新失败，请确认后端服务已启动');
      }
    }
  }

  Future<void> _confirmUnbind() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解绑设备'),
        content: const Text('解绑后需要重新绑定才能继续查看这台小黄鸭的数据。当前是原型环境，请确认是否继续。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认解绑'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await duckApiService.ensureDemoLogin();
      await duckApiService.unbindDevice(_device.id);
      if (mounted) {
        _toast('设备已解绑，可重新执行 demo 初始化恢复数据');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        _toast('解绑失败，请确认后端服务已启动');
      }
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设备管理')),
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
              child: Row(
                children: [
                  const DuckAvatar(size: 72, showBadge: true),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _device.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            TagChip(
                              label: _device.isOnline ? '在线' : '离线',
                              color: _device.isOnline
                                  ? AppColors.success
                                  : AppColors.muted,
                            ),
                            TagChip(
                              label: '电量 ${_device.batteryLevel}%',
                              color: AppColors.warmOrange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader(title: '设备信息'),
            AppCard(
              child: Column(
                children: [
                  SettingItem(
                    icon: Icons.confirmation_number_outlined,
                    title: '设备编号',
                    subtitle: _device.serialNumber,
                  ),
                  const Divider(height: 1),
                  SettingItem(
                    icon: Icons.wifi_rounded,
                    title: 'Wi-Fi 状态',
                    subtitle: _device.networkName,
                    iconColor: AppColors.skyBlue,
                  ),
                  const Divider(height: 1),
                  SettingItem(
                    icon: Icons.system_update_alt_rounded,
                    title: '固件版本',
                    subtitle: _device.firmwareVersion,
                    iconColor: AppColors.mint,
                    trailing: TextButton(
                      onPressed: _checkFirmware,
                      child: const Text('检查更新'),
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader(title: '声音设置'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.volume_up_rounded,
                        color: AppColors.warmOrange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '设备音量 ${(100 * _device.volume).round()}%',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  Slider(
                    value: _device.volume,
                    onChanged: (value) =>
                        _updateLocal(_device.copyWith(volume: value)),
                    onChangeEnd: (value) =>
                        _saveDevice(_device.copyWith(volume: value)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '小黄鸭音色',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final voice in _voices)
                        ChoiceChip(
                          label: Text(voice),
                          selected: _device.voiceName == voice,
                          onSelected: (_) =>
                              _saveDevice(_device.copyWith(voiceName: voice)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SectionHeader(title: '绑定管理'),
            AppCard(
              child: Column(
                children: [
                  SettingItem(
                    icon: Icons.link_rounded,
                    title: '重新绑定设备',
                    subtitle: '用于更换网络或重新扫码绑定',
                    onTap: () => _toast('重新绑定流程将在正式版接入'),
                  ),
                  const Divider(height: 1),
                  SettingItem(
                    icon: Icons.link_off_rounded,
                    title: '解绑设备',
                    subtitle: '解绑前会要求再次确认家长身份',
                    iconColor: AppColors.attention,
                    onTap: _confirmUnbind,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
