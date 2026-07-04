import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/child_profile.dart';
import '../models/conversation_record.dart';
import '../models/dashboard_snapshot.dart';
import '../models/device.dart';
import '../models/legal_document.dart';
import '../models/parent_user.dart';
import '../models/safety_settings.dart';
import '../models/usage_stats.dart';

final duckApiService = DuckApiService();

class DuckApiService {
  DuckApiService({this.baseUrl = 'http://127.0.0.1:8000/api/v1'});

  final String baseUrl;
  String? _accessToken;
  ParentUser? _currentParent;

  bool get isLoggedIn => _accessToken != null;
  ParentUser? get currentParent => _currentParent;

  Future<void> ensureDemoLogin() async {
    if (isLoggedIn) {
      return;
    }
    await login(account: 'demo_parent', password: '123456');
  }

  Future<ParentUser?> login({
    required String account,
    required String password,
  }) async {
    final data = await _request(
      'POST',
      '/auth/login',
      body: {'account': account, 'password': password},
      requireAuth: false,
    );
    _accessToken = data['accessToken']?.toString();
    final userData = data['user'];
    if (userData is Map) {
      _currentParent = ParentUser.fromJson(userData.cast<String, dynamic>());
    }
    return _currentParent;
  }

  Future<void> logout() async {
    if (_accessToken != null) {
      try {
        await _request('POST', '/auth/logout');
      } catch (_) {
        // Local prototypes should still log out even if the backend is offline.
      }
    }
    _accessToken = null;
    _currentParent = null;
  }

  Future<ParentUser> fetchMe() async {
    final data = await _request('GET', '/me');
    final user = ParentUser.fromJson((data as Map).cast<String, dynamic>());
    _currentParent = user;
    return user;
  }

  Future<DashboardSnapshot> fetchDashboardToday() async {
    final data = await _request('GET', '/dashboard/today');
    return DashboardSnapshot.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<List<ChildProfile>> fetchChildren() async {
    final data = await _request('GET', '/children');
    if (data is! List) {
      return [];
    }
    return data
        .whereType<Map>()
        .map((item) => ChildProfile.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<ChildProfile> fetchPrimaryChild() async {
    final children = await fetchChildren();
    if (children.isEmpty) {
      throw Exception('当前账号未绑定孩子资料');
    }
    return children.first;
  }

  Future<ChildProfile> updateChild(ChildProfile profile) async {
    final data = await _request(
      'PUT',
      '/children/${profile.id}',
      body: profile.toJson(),
    );
    return ChildProfile.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<List<Device>> fetchDevices({String? childId}) async {
    final path = childId == null || childId.isEmpty
        ? '/devices'
        : '/devices?childId=${Uri.encodeQueryComponent(childId)}';
    final data = await _request('GET', path);
    if (data is! List) {
      return [];
    }
    return data
        .whereType<Map>()
        .map((item) => Device.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<Device> fetchPrimaryDevice({String? childId}) async {
    final devices = await fetchDevices(childId: childId);
    if (devices.isEmpty) {
      throw Exception('当前账号未绑定小黄鸭设备');
    }
    return devices.first;
  }

  Future<Device> updateDevice(Device device) async {
    final data = await _request(
      'PATCH',
      '/devices/${device.id}',
      body: device.toUpdateJson(),
    );
    return Device.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<FirmwareCheckResult> checkFirmware(String deviceId) async {
    final data = await _request('POST', '/devices/$deviceId/firmware/check');
    return FirmwareCheckResult.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<void> unbindDevice(String deviceId) async {
    await _request('DELETE', '/devices/$deviceId');
  }

  Future<SafetySettings> fetchSafetySettings(String deviceId) async {
    final data = await _request('GET', '/devices/$deviceId/safety-settings');
    return SafetySettings.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<SafetySettings> updateSafetySettings(
    String deviceId,
    SafetySettings settings,
  ) async {
    final data = await _request(
      'PUT',
      '/devices/$deviceId/safety-settings',
      body: settings.toJson(),
    );
    return SafetySettings.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<List<String>> addBlockedKeyword(
    String deviceId,
    String keyword,
  ) async {
    final data = await _request(
      'POST',
      '/devices/$deviceId/safety-settings/blocked-keywords',
      body: {'keyword': keyword},
    );
    return _stringList(data);
  }

  Future<List<String>> deleteBlockedKeyword(
    String deviceId,
    String keyword,
  ) async {
    final encoded = Uri.encodeComponent(keyword);
    final data = await _request(
      'DELETE',
      '/devices/$deviceId/safety-settings/blocked-keywords/$encoded',
    );
    return _stringList(data);
  }

  Future<UsageStats> fetchUsageSettings(String deviceId) async {
    final data = await _request('GET', '/devices/$deviceId/usage-settings');
    return UsageStats.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<UsageStats> updateUsageSettings(
    String deviceId,
    UsageStats usage,
  ) async {
    final data = await _request(
      'PUT',
      '/devices/$deviceId/usage-settings',
      body: usage.toSettingsJson(),
    );
    return UsageStats.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<bool> pauseDevice(String deviceId, bool paused) async {
    final data = await _request(
      'POST',
      '/devices/$deviceId/usage-settings/pause',
      body: {'paused': paused},
    );
    if (data is Map) {
      return data['paused'] == true;
    }
    return paused;
  }

  Future<List<ConversationRecord>> fetchConversations() async {
    final data = await _request('GET', '/conversations?page=1&pageSize=100');
    final items = data['items'];
    if (items is! List) {
      return [];
    }
    return items
        .whereType<Map>()
        .map(
          (item) => ConversationRecord.fromJson(item.cast<String, dynamic>()),
        )
        .toList();
  }

  Future<ConversationRecord> fetchConversationDetail(String id) async {
    final data = await _request('GET', '/conversations/$id');
    return ConversationRecord.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<ConversationRecord> updateConversation({
    required String id,
    String? parentNote,
    bool? flagged,
  }) async {
    final body = <String, dynamic>{};
    if (parentNote != null) {
      body['parentNote'] = parentNote;
    }
    if (flagged != null) {
      body['flagged'] = flagged;
    }
    final data = await _request('PATCH', '/conversations/$id', body: body);
    return ConversationRecord.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<LegalDocument> fetchLegalDocument(String type) async {
    final data = await _request(
      'GET',
      '/legal-documents/$type',
      requireAuth: false,
    );
    return LegalDocument.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<void> submitFeedback({
    required String type,
    required String content,
    String contact = '',
  }) async {
    await _request(
      'POST',
      '/feedback',
      body: {
        'type': _feedbackTypeCode(type),
        'content': content,
        'contact': contact,
        'clientInfo': {'client': 'flutter-parent-app-prototype'},
      },
    );
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (requireAuth && _accessToken != null)
        'Authorization': 'Bearer $_accessToken',
    };

    late http.Response response;
    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: headers);
      case 'POST':
        response = await http.post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? {}),
        );
      case 'PATCH':
        response = await http.patch(
          uri,
          headers: headers,
          body: jsonEncode(body ?? {}),
        );
      case 'PUT':
        response = await http.put(
          uri,
          headers: headers,
          body: jsonEncode(body ?? {}),
        );
      case 'DELETE':
        response = await http.delete(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
      default:
        throw UnsupportedError('Unsupported HTTP method: $method');
    }

    final decoded =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode >= 400 || decoded['code'] != 0) {
      throw Exception(decoded['message'] ?? '请求失败');
    }
    return decoded['data'];
  }
}

class FirmwareCheckResult {
  const FirmwareCheckResult({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
  });

  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;

  factory FirmwareCheckResult.fromJson(Map<String, dynamic> json) {
    return FirmwareCheckResult(
      hasUpdate: json['hasUpdate'] == true,
      currentVersion: json['currentVersion']?.toString() ?? '',
      latestVersion: json['latestVersion']?.toString() ?? '',
      releaseNotes: json['releaseNotes']?.toString() ?? '',
    );
  }
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}

String _feedbackTypeCode(String value) {
  switch (value) {
    case '功能建议':
      return 'feature';
    case '设备问题':
      return 'device';
    case '对话内容':
      return 'conversation';
    case '安全提醒':
      return 'safety';
    default:
      return 'other';
  }
}
