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
  // Legacy alias. Keep for compatibility with existing persisted documents.
  String? pdfPath;
  String? pdfOriginalPath;
  String? pdfWorkingPath;
  bool pdfWritebackEnabled;
  int pdfWritebackRevision;
  int pdfPageLayoutVersion;
  String? annotatedPdfPath;
  String transcription; // lecture transcription text
  DateTime? lastPdfExportAt;
  String? lastPdfExportStatus;
  String? lastPdfExportMessage;
  double? pdfViewportWidth;
  double? pdfViewportHeight;
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
    this.pdfOriginalPath,
    this.pdfWorkingPath,
    this.pdfWritebackEnabled = true,
    this.pdfWritebackRevision = 0,
    this.pdfPageLayoutVersion = 1,
    this.annotatedPdfPath,
    this.transcription = '',
    this.lastPdfExportAt,
    this.lastPdfExportStatus,
    this.lastPdfExportMessage,
    this.pdfViewportWidth,
    this.pdfViewportHeight,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : strokes = strokes ?? [],
        blocks = blocks ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    pdfWorkingPath ??= pdfPath;
    pdfPath = pdfWorkingPath ?? pdfPath;
  }

  String? get activePdfPath => pdfWorkingPath ?? pdfPath;

  bool get hasPdf => activePdfPath != null && activePdfPath!.isNotEmpty;

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
        'pdfOriginalPath': pdfOriginalPath,
        'pdfWorkingPath': pdfWorkingPath,
        'pdfWritebackEnabled': pdfWritebackEnabled,
        'pdfWritebackRevision': pdfWritebackRevision,
        'pdfPageLayoutVersion': pdfPageLayoutVersion,
        'annotatedPdfPath': annotatedPdfPath,
        'transcription': transcription,
        'lastPdfExportAt': lastPdfExportAt?.toIso8601String(),
        'lastPdfExportStatus': lastPdfExportStatus,
        'lastPdfExportMessage': lastPdfExportMessage,
        'pdfViewportWidth': pdfViewportWidth,
        'pdfViewportHeight': pdfViewportHeight,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory NoteDocument.fromJson(Map<String, dynamic> json) {
    final workingPath =
        (json['pdfWorkingPath'] as String?) ?? (json['pdfPath'] as String?);
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
      pdfPath: workingPath,
      pdfOriginalPath: json['pdfOriginalPath'] as String?,
      pdfWorkingPath: workingPath,
      pdfWritebackEnabled: json['pdfWritebackEnabled'] as bool? ?? true,
      pdfWritebackRevision: (json['pdfWritebackRevision'] as num?)?.toInt() ?? 0,
      pdfPageLayoutVersion: (json['pdfPageLayoutVersion'] as num?)?.toInt() ?? 1,
      annotatedPdfPath: json['annotatedPdfPath'] as String?,
      transcription: json['transcription'] as String? ?? '',
      lastPdfExportAt: json['lastPdfExportAt'] != null
          ? DateTime.parse(json['lastPdfExportAt'] as String)
          : null,
      lastPdfExportStatus: json['lastPdfExportStatus'] as String?,
      lastPdfExportMessage: json['lastPdfExportMessage'] as String?,
      pdfViewportWidth: (json['pdfViewportWidth'] as num?)?.toDouble(),
      pdfViewportHeight: (json['pdfViewportHeight'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
