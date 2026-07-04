class UsageStats {
  const UsageStats({
    required this.conversationCount,
    required this.companionMinutes,
    required this.storyCount,
    required this.learningInteractions,
    required this.maxDailyMinutes,
    required this.sleepStart,
    required this.sleepEnd,
    required this.napDoNotDisturb,
    required this.weeklyPlan,
    required this.paused,
  });

  final int conversationCount;
  final int companionMinutes;
  final int storyCount;
  final int learningInteractions;
  final int maxDailyMinutes;
  final String sleepStart;
  final String sleepEnd;
  final bool napDoNotDisturb;
  final Map<String, bool> weeklyPlan;
  final bool paused;

  factory UsageStats.fromJson(Map<String, dynamic> json) {
    return UsageStats(
      conversationCount: _intValue(json['conversationCount'], fallback: 0),
      companionMinutes: _intValue(json['companionMinutes'], fallback: 0),
      storyCount: _intValue(json['storyCount'], fallback: 0),
      learningInteractions: _intValue(
        json['learningInteractions'],
        fallback: 0,
      ),
      maxDailyMinutes: _intValue(json['maxDailyMinutes'], fallback: 60),
      sleepStart: json['sleepStart']?.toString() ?? '21:00',
      sleepEnd: json['sleepEnd']?.toString() ?? '07:00',
      napDoNotDisturb: json['napDoNotDisturb'] != false,
      weeklyPlan: _weeklyPlanFromJson(json['weeklyPlan']),
      paused: json['paused'] == true,
    );
  }

  Map<String, dynamic> toSettingsJson() {
    return {
      'maxDailyMinutes': maxDailyMinutes,
      'sleepStart': sleepStart,
      'sleepEnd': sleepEnd,
      'napDoNotDisturb': napDoNotDisturb,
      'weeklyPlan': _weeklyPlanToJson(weeklyPlan),
      'paused': paused,
    };
  }

  UsageStats copyWith({
    int? conversationCount,
    int? companionMinutes,
    int? storyCount,
    int? learningInteractions,
    int? maxDailyMinutes,
    String? sleepStart,
    String? sleepEnd,
    bool? napDoNotDisturb,
    Map<String, bool>? weeklyPlan,
    bool? paused,
  }) {
    return UsageStats(
      conversationCount: conversationCount ?? this.conversationCount,
      companionMinutes: companionMinutes ?? this.companionMinutes,
      storyCount: storyCount ?? this.storyCount,
      learningInteractions: learningInteractions ?? this.learningInteractions,
      maxDailyMinutes: maxDailyMinutes ?? this.maxDailyMinutes,
      sleepStart: sleepStart ?? this.sleepStart,
      sleepEnd: sleepEnd ?? this.sleepEnd,
      napDoNotDisturb: napDoNotDisturb ?? this.napDoNotDisturb,
      weeklyPlan: weeklyPlan ?? this.weeklyPlan,
      paused: paused ?? this.paused,
    );
  }
}

const _apiDayToLabel = {
  'mon': '一',
  'tue': '二',
  'wed': '三',
  'thu': '四',
  'fri': '五',
  'sat': '六',
  'sun': '日',
};

int _intValue(dynamic value, {required int fallback}) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

Map<String, bool> _weeklyPlanFromJson(dynamic value) {
  final result = <String, bool>{};
  final source = value is Map ? value : const {};
  for (final entry in _apiDayToLabel.entries) {
    final raw = source[entry.key] ?? source[entry.value];
    result[entry.value] = raw is bool ? raw : raw?.toString() == 'true';
  }
  return result;
}

Map<String, bool> _weeklyPlanToJson(Map<String, bool> value) {
  final result = <String, bool>{};
  for (final entry in _apiDayToLabel.entries) {
    result[entry.key] = value[entry.value] ?? false;
  }
  return result;
}
