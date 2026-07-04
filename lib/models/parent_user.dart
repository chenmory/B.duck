class ParentUser {
  const ParentUser({
    this.id = '',
    required this.name,
    required this.phone,
    required this.relation,
  });

  final String id;
  final String name;
  final String phone;
  final String relation;

  factory ParentUser.fromJson(Map<String, dynamic> json) {
    return ParentUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '家长',
      phone: json['phone']?.toString() ?? '',
      relation: json['relation']?.toString() ?? '家长',
    );
  }
}
