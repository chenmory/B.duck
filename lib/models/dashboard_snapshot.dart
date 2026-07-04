import 'device.dart';
import 'usage_stats.dart';

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.greeting,
    required this.todaySummary,
    required this.device,
    required this.usage,
    required this.attentionCount,
  });

  final String greeting;
  final String todaySummary;
  final Device device;
  final UsageStats usage;
  final int attentionCount;

  factory DashboardSnapshot.fromJson(Map<String, dynamic> json) {
    return DashboardSnapshot(
      greeting: json['greeting']?.toString() ?? '你好',
      todaySummary: json['todaySummary']?.toString() ?? '今天还没有新的对话摘要。',
      device: Device.fromJson(
        (json['device'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      usage: UsageStats.fromJson(
        (json['usage'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      attentionCount: _intValue(json['attentionCount'], fallback: 0),
    );
  }
}

int _intValue(dynamic value, {required int fallback}) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
