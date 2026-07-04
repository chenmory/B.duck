class SafetySettings {
  const SafetySettings({
    required this.sensitiveTopicFilter,
    required this.strangerInfoAlert,
    required this.negativeEmotionAlert,
    required this.nightUsageAlert,
    required this.blockedKeywords,
    required this.replyStyle,
  });

  final bool sensitiveTopicFilter;
  final bool strangerInfoAlert;
  final bool negativeEmotionAlert;
  final bool nightUsageAlert;
  final List<String> blockedKeywords;
  final String replyStyle;

  factory SafetySettings.fromJson(Map<String, dynamic> json) {
    return SafetySettings(
      sensitiveTopicFilter: json['sensitiveTopicFilter'] != false,
      strangerInfoAlert: json['strangerInfoAlert'] != false,
      negativeEmotionAlert: json['negativeEmotionAlert'] != false,
      nightUsageAlert: json['nightUsageAlert'] != false,
      blockedKeywords: _stringList(json['blockedKeywords']),
      replyStyle: _replyStyleLabel(json['replyStyle']?.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sensitiveTopicFilter': sensitiveTopicFilter,
      'strangerInfoAlert': strangerInfoAlert,
      'negativeEmotionAlert': negativeEmotionAlert,
      'nightUsageAlert': nightUsageAlert,
      'blockedKeywords': blockedKeywords,
      'replyStyle': _replyStyleCode(replyStyle),
    };
  }

  SafetySettings copyWith({
    bool? sensitiveTopicFilter,
    bool? strangerInfoAlert,
    bool? negativeEmotionAlert,
    bool? nightUsageAlert,
    List<String>? blockedKeywords,
    String? replyStyle,
  }) {
    return SafetySettings(
      sensitiveTopicFilter: sensitiveTopicFilter ?? this.sensitiveTopicFilter,
      strangerInfoAlert: strangerInfoAlert ?? this.strangerInfoAlert,
      negativeEmotionAlert: negativeEmotionAlert ?? this.negativeEmotionAlert,
      nightUsageAlert: nightUsageAlert ?? this.nightUsageAlert,
      blockedKeywords: blockedKeywords ?? this.blockedKeywords,
      replyStyle: replyStyle ?? this.replyStyle,
    );
  }
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}

String _replyStyleLabel(String? value) {
  switch (value) {
    case 'gentle_companion':
      return '温柔陪伴';
    case 'knowledge':
      return '知识启蒙';
    case 'story':
      return '故事模式';
    case 'short':
      return '简短回答';
    default:
      return value ?? '温柔陪伴';
  }
}

String _replyStyleCode(String value) {
  switch (value) {
    case '温柔陪伴':
      return 'gentle_companion';
    case '知识启蒙':
      return 'knowledge';
    case '故事模式':
      return 'story';
    case '简短回答':
      return 'short';
    default:
      return value;
  }
}
