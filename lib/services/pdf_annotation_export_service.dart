import 'dart:io';
import 'dart:ui';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:notes_app/models/anchor_type.dart';
import 'package:notes_app/models/document.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfExportResult {
  final bool success;
  final String? outputPath;
  final String message;
  final DateTime exportedAt;

  const PdfExportResult({
    required this.success,
    required this.message,
    required this.exportedAt,
    this.outputPath,
  });
}

/// Writes a flattened PDF containing the original pages + note annotations.
class PdfAnnotationExportService {
  Future<PdfExportResult> exportAnnotatedPdf(
    NoteDocument doc, {
    bool includeTextBlocks = true,
    Directory? outputRoot,
  }) async {
    final sourcePath = doc.pdfWorkingPath ?? doc.pdfPath ?? doc.pdfOriginalPath;
    if (sourcePath == null || sourcePath.isEmpty) {
      return PdfExportResult(
        success: false,
        message: 'No source PDF path is set on the document.',
        exportedAt: DateTime.now(),
      );
    }

    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      return PdfExportResult(
        success: false,
        message: 'Source PDF file does not exist.',
        exportedAt: DateTime.now(),
      );
    }

    try {
      final bytes = await sourceFile.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      for (int pageIndex = 0; pageIndex < document.pages.count; pageIndex++) {
        final page = document.pages[pageIndex];
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

          for (int i = 1; i < points.length; i++) {
            page.graphics.drawLine(
              pen,
              Offset(points[i - 1].dx, points[i - 1].dy),
              Offset(points[i].dx, points[i].dy),
            );
          }
        }

        if (includeTextBlocks) {
          final pageBlocks = doc.blocks
              .where((b) => b.pageIndex == pageIndex)
              .where(
                (b) =>
                    b.anchorType == AnchorType.pdfPage ||
                    (b.normalizedX != null && b.normalizedY != null),
              )
              .where((b) => b.content.trim().isNotEmpty);
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
            final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
            page.graphics.drawString(
              block.content,
              font,
              bounds: Rect.fromLTWH(x, y, width, pageSize.height - y),
              brush: PdfBrushes.black,
              format: PdfStringFormat(
                lineAlignment: PdfVerticalAlignment.top,
                alignment: PdfTextAlignment.left,
              ),
            );
          }
        }
      }

      final appDir = outputRoot ?? await getApplicationDocumentsDirectory();
      final outDir = Directory(p.join(appDir.path, 'NotesApp', 'pdfs'));
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }

      final baseName = p.basenameWithoutExtension(sourcePath);
      final outputPath = p.join(outDir.path, '${baseName}_annotated.pdf');
      final outBytes = await document.save();
      await File(outputPath).writeAsBytes(outBytes, flush: true);
      document.dispose();

      return PdfExportResult(
        success: true,
        outputPath: outputPath,
        message: 'Exported annotated PDF successfully.',
        exportedAt: DateTime.now(),
      );
    } catch (e) {
      return PdfExportResult(
        success: false,
        message: 'PDF export failed: $e',
        exportedAt: DateTime.now(),
      );
    }
  }
}
