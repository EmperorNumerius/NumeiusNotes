/// A folder for organizing notes.
class NoteFolder {
  final String id;
  String name;
  String? parentId; // null = root level
  String subject; // subject tag for filtering
  int colorValue; // stored as int for serialization
  DateTime createdAt;

  NoteFolder({
    required this.id,
    this.name = 'New Folder',
    this.parentId,
    this.subject = '',
    this.colorValue = 0xFF7C3AED, // default purple
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'parentId': parentId,
        'subject': subject,
        'colorValue': colorValue,
        'createdAt': createdAt.toIso8601String(),
      };

  factory NoteFolder.fromJson(Map<String, dynamic> json) {
    return NoteFolder(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'New Folder',
      parentId: json['parentId'] as String?,
      subject: json['subject'] as String? ?? '',
      colorValue: json['colorValue'] as int? ?? 0xFF7C3AED,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
