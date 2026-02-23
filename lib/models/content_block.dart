/// Types of content that can exist in a document.
enum ContentBlockType { text, code, latex, chemistry, calculator, flashcard }

/// A block of typed content (text, code, LaTeX, chemistry, or calculator) in a document.
/// Each block has a free-form position on the canvas.
class ContentBlock {
  final String id;
  final ContentBlockType type;
  String content;
  String language; // for code blocks: 'python', 'cpp', etc.
  String output; // execution output for code blocks

  // Free-form canvas position
  double x;
  double y;
  double blockWidth;

  /// Flexible metadata map — used by chemistry blocks to store compound data,
  /// calculator blocks to store history, etc.
  Map<String, dynamic> metadata;

  ContentBlock({
    required this.id,
    this.type = ContentBlockType.text,
    this.content = '',
    this.language = 'python',
    this.output = '',
    this.x = 100,
    this.y = 100,
    this.blockWidth = 360,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'content': content,
        'language': language,
        'output': output,
        'x': x,
        'y': y,
        'blockWidth': blockWidth,
        'metadata': metadata,
      };

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    return ContentBlock(
      id: json['id'] as String,
      type: ContentBlockType.values.byName(json['type'] as String),
      content: json['content'] as String? ?? '',
      language: json['language'] as String? ?? 'python',
      output: json['output'] as String? ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 100,
      y: (json['y'] as num?)?.toDouble() ?? 100,
      blockWidth: (json['blockWidth'] as num?)?.toDouble() ?? 360,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }
}
