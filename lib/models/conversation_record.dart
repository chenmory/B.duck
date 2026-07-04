class ConversationRecord {
  const ConversationRecord({
    required this.id,
    required this.time,
    required this.childSpeech,
    required this.duckReply,
    required this.emotion,
    required this.riskLevel,
    required this.fullConversation,
    required this.emotionAnalysis,
    required this.safetyJudgement,
    this.parentNote = '',
    this.flagged = false,
  });

  final String id;
  final DateTime time;
  final String childSpeech;
  final String duckReply;
  final String emotion;
  final String riskLevel;
  final String fullConversation;
  final String emotionAnalysis;
  final String safetyJudgement;
  final String parentNote;
  final bool flagged;

  factory ConversationRecord.fromJson(Map<String, dynamic> json) {
    final childSpeech = json['childSpeech']?.toString() ?? '';
    final duckReply = json['duckReply']?.toString() ?? '';
    return ConversationRecord(
      id: json['id']?.toString() ?? '',
      time:
          DateTime.tryParse(json['startedAt']?.toString() ?? '') ??
          DateTime.now(),
      childSpeech: childSpeech,
      duckReply: duckReply,
      emotion: _emotionLabel(json['emotion']?.toString()),
      riskLevel: _riskLabel(json['riskLevel']?.toString()),
      fullConversation:
          json['fullConversation']?.toString() ??
          '孩子：$childSpeech\n小黄鸭：$duckReply',
      emotionAnalysis: json['emotionAnalysis']?.toString() ?? '后端暂未返回情绪分析。',
      safetyJudgement: json['safetyJudgement']?.toString() ?? '后端暂未返回安全判断。',
      parentNote: json['parentNote']?.toString() ?? '',
      flagged: json['flagged'] == true,
    );
  }

  ConversationRecord copyWith({
    String? id,
    DateTime? time,
    String? childSpeech,
    String? duckReply,
    String? emotion,
    String? riskLevel,
    String? fullConversation,
    String? emotionAnalysis,
    String? safetyJudgement,
    String? parentNote,
    bool? flagged,
  }) {
    return ConversationRecord(
      id: id ?? this.id,
      time: time ?? this.time,
      childSpeech: childSpeech ?? this.childSpeech,
      duckReply: duckReply ?? this.duckReply,
      emotion: emotion ?? this.emotion,
      riskLevel: riskLevel ?? this.riskLevel,
      fullConversation: fullConversation ?? this.fullConversation,
      emotionAnalysis: emotionAnalysis ?? this.emotionAnalysis,
      safetyJudgement: safetyJudgement ?? this.safetyJudgement,
      parentNote: parentNote ?? this.parentNote,
      flagged: flagged ?? this.flagged,
    );
  }
}

String _emotionLabel(String? value) {
  switch (value) {
    case 'happy':
      return '开心';
    case 'curious':
      return '好奇';
    case 'sad':
      return '低落';
    case 'scared':
      return '害怕';
    case 'calm':
      return '平静';
    default:
      return value ?? '平静';
  }
}

String _riskLabel(String? value) {
  switch (value) {
    case 'normal':
      return '正常';
    case 'attention':
      return '需关注';
    case 'high_risk':
      return '高风险';
    default:
      return value ?? '正常';
  }
}
