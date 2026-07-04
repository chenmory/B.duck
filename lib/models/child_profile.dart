class ChildProfile {
  const ChildProfile({
    this.id = '',
    required this.nickname,
    required this.age,
    required this.gender,
    required this.interests,
    required this.focusAreas,
  });

  final String id;
  final String nickname;
  final int age;
  final String gender;
  final List<String> interests;
  final List<String> focusAreas;

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: json['id']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '孩子',
      age: _intValue(json['age'], fallback: 5),
      gender: json['gender']?.toString() ?? '未设置',
      interests: _stringList(json['interests']),
      focusAreas: _stringList(json['focusAreas']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
      'age': age,
      'gender': gender,
      'interests': interests,
      'focusAreas': focusAreas,
    };
  }

  ChildProfile copyWith({
    String? id,
    String? nickname,
    int? age,
    String? gender,
    List<String>? interests,
    List<String>? focusAreas,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      interests: interests ?? this.interests,
      focusAreas: focusAreas ?? this.focusAreas,
    );
  }
}

int _intValue(dynamic value, {required int fallback}) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}
