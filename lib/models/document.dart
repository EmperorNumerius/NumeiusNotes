import 'package:notes_app/models/stroke.dart';
import 'package:notes_app/models/content_block.dart';

/// A single note document containing strokes, content blocks, and optional audio.
class NoteDocument {
  final String id;
  String title;
  String? folderId; // which folder this note belongs to (null = root)
  String subject; // subject tag for filtering
  List<Stroke> strokes;
  List<ContentBlock> blocks;
  String? audioPath;
  String? pdfPath; // path to imported PDF for annotation
  String transcription; // lecture transcription text
  DateTime createdAt;
  DateTime updatedAt;

  NoteDocument({
    required this.id,
    this.title = 'Untitled',
    this.folderId,
    this.subject = '',
    List<Stroke>? strokes,
    List<ContentBlock>? blocks,
    this.audioPath,
    this.pdfPath,
    this.transcription = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : strokes = strokes ?? [],
        blocks = blocks ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  void touch() => updatedAt = DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'folderId': folderId,
        'subject': subject,
        'strokes': strokes.map((s) => s.toJson()).toList(),
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'audioPath': audioPath,
        'pdfPath': pdfPath,
        'transcription': transcription,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory NoteDocument.fromJson(Map<String, dynamic> json) {
    return NoteDocument(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      folderId: json['folderId'] as String?,
      subject: json['subject'] as String? ?? '',
      strokes: (json['strokes'] as List?)
              ?.map((s) => Stroke.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      blocks: (json['blocks'] as List?)
              ?.map((b) => ContentBlock.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
      audioPath: json['audioPath'] as String?,
      pdfPath: json['pdfPath'] as String?,
      transcription: json['transcription'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
