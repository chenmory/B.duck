import 'package:flutter/material.dart';

import '../models/child_profile.dart';
import '../services/duck_api_service.dart';
import '../services/mock_service.dart';
import '../widgets/app_card.dart';
import '../widgets/section_header.dart';

class ChildProfilePage extends StatefulWidget {
  const ChildProfilePage({super.key});

  @override
  State<ChildProfilePage> createState() => _ChildProfilePageState();
}

class _ChildProfilePageState extends State<ChildProfilePage> {
  late ChildProfile _profile;
  late final TextEditingController _nicknameController;
  late final TextEditingController _ageController;
  bool _loading = false;
  bool _saving = false;

  final _interestOptions = ['恐龙', '绘本', '英语', '宇宙', '动物', '积木'];
  final _focusOptions = ['语言表达', '情绪陪伴', '科普启蒙', '英语学习', '生活习惯'];
  final _genderOptions = ['女', '男', '未设置'];

  @override
  void initState() {
    super.initState();
    _profile = mockService.childProfile;
    _nicknameController = TextEditingController(text: _profile.nickname);
    _ageController = TextEditingController(text: _profile.age.toString());
    _loadProfile();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      await duckApiService.ensureDemoLogin();
      final profile = await duckApiService.fetchPrimaryChild();
      if (!mounted) {
        return;
      }
      _updateLocal(profile);
      _nicknameController.text = profile.nickname;
      _ageController.text = profile.age.toString();
    } catch (_) {
      if (mounted) {
        _toast('后端孩子资料暂不可用，当前显示本地 mock 数据');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _updateLocal(ChildProfile profile) {
    setState(() => _profile = profile);
    mockService.childProfile = profile;
  }

  Future<void> _save() async {
    final age = int.tryParse(_ageController.text.trim()) ?? _profile.age;
    final profile = _profile.copyWith(
      nickname: _nicknameController.text.trim(),
      age: age,
    );
    _updateLocal(profile);
    if (profile.id.isEmpty) {
      _toast('孩子资料已保存到本地');
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await duckApiService.updateChild(profile);
      if (mounted) {
        _updateLocal(updated);
        _toast('孩子资料已同步到后端');
      }
    } catch (_) {
      if (mounted) {
        _toast('孩子资料已本地保存，后端同步失败');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('孩子资料')),
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
              child: Column(
                children: [
                  TextField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      labelText: '孩子昵称',
                      prefixIcon: Icon(Icons.child_care_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '年龄',
                      prefixIcon: Icon(Icons.cake_outlined),
                      suffixText: '岁',
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader(title: '性别'),
            AppCard(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final gender in _genderOptions)
                    ChoiceChip(
                      label: Text(gender),
                      selected: _profile.gender == gender,
                      onSelected: (_) =>
                          _updateLocal(_profile.copyWith(gender: gender)),
                    ),
                ],
              ),
            ),
            const SectionHeader(title: '兴趣标签'),
            AppCard(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final interest in _interestOptions)
                    FilterChip(
                      label: Text(interest),
                      selected: _profile.interests.contains(interest),
                      onSelected: (selected) {
                        final interests = [..._profile.interests];
                        selected
                            ? interests.add(interest)
                            : interests.remove(interest);
                        _updateLocal(_profile.copyWith(interests: interests));
                      },
                    ),
                ],
              ),
            ),
            const SectionHeader(title: '重点关注方向'),
            AppCard(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final focus in _focusOptions)
                    FilterChip(
                      label: Text(focus),
                      selected: _profile.focusAreas.contains(focus),
                      onSelected: (selected) {
                        final focuses = [..._profile.focusAreas];
                        selected ? focuses.add(focus) : focuses.remove(focus);
                        _updateLocal(_profile.copyWith(focusAreas: focuses));
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('保存资料'),
            ),
          ],
        ),
      ),
    );
  }
}
