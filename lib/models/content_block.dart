import 'package:notes_app/models/anchor_type.dart';

/// Types of content that can exist in a document.
enum ContentBlockType {
  text,
  code,
  latex,
  chemistry,
  calculator,
  flashcard,
  markdown,
  image,
}

/// A block of typed content (text, code, LaTeX, chemistry, or calculator) in a document.
/// Each block has a free-form position on the canvas.
class ContentBlock {
  final String id;
  final ContentBlockType type;
  String content;
  String language; // for code blocks: 'python', 'cpp', etc.
  String output; // execution output for code blocks
  AnchorType anchorType;

  // Free-form canvas position
  double x;
  double y;
  double blockWidth;

  /// Target page index in the PDF.
  int pageIndex;

  /// Optional normalized anchor ([0,1]) relative to page width/height.
  double? normalizedX;
  double? normalizedY;

  /// Flexible metadata map — used by chemistry blocks to store compound data,
  /// calculator blocks to store history, etc.
  Map<String, dynamic> metadata;

  ContentBlock({
    required this.id,
    this.type = ContentBlockType.text,
    this.content = '',
    this.language = 'python',
    this.output = '',
    this.anchorType = AnchorType.canvas,
    this.x = 100,
    this.y = 100,
    this.blockWidth = 360,
    this.pageIndex = 0,
    this.normalizedX,
    this.normalizedY,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'content': content,
    'language': language,
    'output': output,
    'anchorType': anchorType.name,
    'x': x,
    'y': y,
    'blockWidth': blockWidth,
    'pageIndex': pageIndex,
    'normalizedX': normalizedX,
    'normalizedY': normalizedY,
    'metadata': metadata,
  };

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String?;
    final blockType = ContentBlockType.values.asNameMap()[typeName] ??
        ContentBlockType.text;
    final anchorName = json['anchorType'] as String?;
    final inferredAnchor = AnchorType.values.asNameMap()[anchorName] ??
        ((json['normalizedX'] != null && json['normalizedY'] != null)
            ? AnchorType.pdfPage
            : AnchorType.canvas);

    return ContentBlock(
      id: json['id'] as String,
      type: blockType,
      content: json['content'] as String? ?? '',
      language: json['language'] as String? ?? 'python',
      output: json['output'] as String? ?? '',
      anchorType: inferredAnchor,
      x: (json['x'] as num?)?.toDouble() ?? 100,
      y: (json['y'] as num?)?.toDouble() ?? 100,
      blockWidth: (json['blockWidth'] as num?)?.toDouble() ?? 360,
      pageIndex: (json['pageIndex'] as num?)?.toInt() ?? 0,
      normalizedX: (json['normalizedX'] as num?)?.toDouble(),
      normalizedY: (json['normalizedY'] as num?)?.toDouble(),
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  void updateNormalizedAnchor({
    required double viewportWidth,
    required double viewportHeight,
    int? page,
  }) {
    final vw = viewportWidth <= 0 ? 1.0 : viewportWidth;
    final vh = viewportHeight <= 0 ? 1.0 : viewportHeight;
    normalizedX = (x / vw).clamp(0.0, 1.0);
    normalizedY = (y / vh).clamp(0.0, 1.0);
    anchorType = AnchorType.pdfPage;
    if (page != null) pageIndex = page;
  }

  void updateCanvasAnchor({required double worldX, required double worldY}) {
    x = worldX;
    y = worldY;
    anchorType = AnchorType.canvas;
    normalizedX = null;
    normalizedY = null;
  }
}
