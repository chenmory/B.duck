class LegalDocument {
  const LegalDocument({
    required this.type,
    required this.version,
    required this.title,
    required this.content,
  });

  final String type;
  final String version;
  final String title;
  final String content;

  factory LegalDocument.fromJson(Map<String, dynamic> json) {
    return LegalDocument(
      type: json['type']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      title: json['title']?.toString() ?? '协议文档',
      content: json['content']?.toString() ?? '',
    );
  }
}
