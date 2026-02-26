import 'dart:io';
import 'dart:ui';

import 'package:notes_app/models/anchor_type.dart';
import 'package:notes_app/models/content_block.dart';
import 'package:notes_app/models/document.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfWritebackResult {
  final bool success;
  final String message;
  final String? outputPath;
  final DateTime writtenAt;
  final int revision;

  const PdfWritebackResult({
    required this.success,
    required this.message,
    required this.writtenAt,
    required this.revision,
    this.outputPath,
  });
}

/// Rebuilds the editable PDF working copy from the immutable source + anchored annotations.
class PdfWritebackService {
  static final _originalSuffixRegex = RegExp(r'_original$');
  static final Map<String, Future<PdfWritebackResult>> _queues = {};

  Future<PdfWritebackResult> writeback(
    NoteDocument doc, {
    bool includeTextBlocks = true,
  }) {
    final docId = doc.id;
    final previous = _queues[docId] ?? Future.value(
      PdfWritebackResult(
        success: true,
        message: 'No previous writeback.',
        writtenAt: DateTime.now(),
        revision: doc.pdfWritebackRevision,
      ),
    );

    final next = previous.catchError((_) {}).then(
      (_) => _writebackNow(doc, includeTextBlocks: includeTextBlocks),
    );
    _queues[docId] = next;
    next.whenComplete(() {
      if (identical(_queues[docId], next)) {
        _queues.remove(docId);
      }
    });
    return next;
  }

  Future<PdfWritebackResult> _writebackNow(
    NoteDocument doc, {
    required bool includeTextBlocks,
  }) async {
    final sourcePath = doc.pdfOriginalPath ?? doc.pdfWorkingPath ?? doc.pdfPath;
    if (sourcePath == null || sourcePath.isEmpty) {
      return PdfWritebackResult(
        success: false,
        message: 'No PDF source available for writeback.',
        writtenAt: DateTime.now(),
        revision: doc.pdfWritebackRevision,
      );
    }

    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      return PdfWritebackResult(
        success: false,
        message: 'PDF source file not found.',
        writtenAt: DateTime.now(),
        revision: doc.pdfWritebackRevision,
      );
    }

    final workingPath =
        doc.pdfWorkingPath ?? doc.pdfPath ?? _deriveWorkingPath(sourcePath);
    final workingFile = File(workingPath);
    workingFile.parent.createSync(recursive: true);

    try {
      final bytes = await sourceFile.readAsBytes();
      final pdf = PdfDocument(inputBytes: bytes);

      for (var pageIndex = 0; pageIndex < pdf.pages.count; pageIndex++) {
        final page = pdf.pages[pageIndex];
        final pageSize = Size(page.size.width, page.size.height);
        final fallbackViewport =
            (doc.pdfViewportWidth != null && doc.pdfViewportHeight != null)
            ? Size(doc.pdfViewportWidth!, doc.pdfViewportHeight!)
            : null;

        final pageStrokes = doc.strokes.where(
          (s) =>
              s.pageIndex == pageIndex &&
              (s.anchorType == AnchorType.pdfPage || s.normalizedPoints != null),
        );

        for (final stroke in pageStrokes) {
          final points = stroke.resolvePointsForPage(
            pageSize,
            fallbackViewportSize: fallbackViewport,
          );
          if (points.length < 2) continue;

          final pen = PdfPen(
            PdfColor(
              (stroke.color.r * 255).round(),
              (stroke.color.g * 255).round(),
              (stroke.color.b * 255).round(),
              (stroke.color.a * 255).round(),
            ),
            width: stroke.width,
          );

          for (var i = 1; i < points.length; i++) {
            page.graphics.drawLine(
              pen,
              Offset(points[i - 1].dx, points[i - 1].dy),
              Offset(points[i].dx, points[i].dy),
            );
          }
        }

        if (includeTextBlocks) {
          final pageBlocks = doc.blocks.where((b) {
            final anchoredToPage =
                b.anchorType == AnchorType.pdfPage ||
                (b.normalizedX != null && b.normalizedY != null);
            return anchoredToPage &&
                b.pageIndex == pageIndex &&
                _blockTextForWriteback(b).trim().isNotEmpty;
          });
          for (final block in pageBlocks) {
            final x = ((block.normalizedX ?? 0) * pageSize.width).clamp(
              0.0,
              pageSize.width - 1,
            );
            final y = ((block.normalizedY ?? 0) * pageSize.height).clamp(
              0.0,
              pageSize.height - 1,
            );
            final width = block.blockWidth.clamp(80.0, pageSize.width - x);
            final font = PdfStandardFont(PdfFontFamily.helvetica, 11);
            page.graphics.drawString(
              _blockTextForWriteback(block),
              font,
              bounds: Rect.fromLTWH(x, y, width, pageSize.height - y),
              brush: PdfBrushes.white,
              format: PdfStringFormat(
                lineAlignment: PdfVerticalAlignment.top,
                alignment: PdfTextAlignment.left,
              ),
            );
          }
        }
      }

      final out = await pdf.save();
      pdf.dispose();
      await workingFile.writeAsBytes(out, flush: true);

      doc.pdfWorkingPath = workingPath;
      doc.pdfPath = workingPath;
      doc.pdfWritebackRevision += 1;

      return PdfWritebackResult(
        success: true,
        message: 'Writeback complete.',
        outputPath: workingPath,
        writtenAt: DateTime.now(),
        revision: doc.pdfWritebackRevision,
      );
    } catch (e) {
      return PdfWritebackResult(
        success: false,
        message: 'PDF writeback failed: $e',
        writtenAt: DateTime.now(),
        revision: doc.pdfWritebackRevision,
      );
    }
  }

  String _deriveWorkingPath(String sourcePath) {
    final ext = p.extension(sourcePath);
    final name = p.basenameWithoutExtension(sourcePath);
    if (name.endsWith('_original')) {
      return p.join(
        p.dirname(sourcePath),
        '${name.replaceAll(_originalSuffixRegex, '_working')}$ext',
      );
    }
    return p.join(p.dirname(sourcePath), '${name}_working$ext');
  }

  String _blockTextForWriteback(ContentBlock block) {
    if (block.type.name == 'chemistry') {
      final formula = block.metadata['formula'];
      if (formula is String && formula.trim().isNotEmpty) {
        return formula.trim();
      }
    }
    return (block.content as String?) ?? '';
  }
}
