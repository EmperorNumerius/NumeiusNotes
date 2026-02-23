import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/models/content_block.dart';
import 'package:notes_app/models/document.dart';
import 'package:notes_app/models/stroke.dart';
import 'package:notes_app/services/pdf_annotation_export_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  test('PdfAnnotationExportService generates annotated output file', () async {
    final temp = await Directory.systemTemp.createTemp('pdf_export_test_');
    final sourcePath = '${temp.path}/source.pdf';

    final srcDoc = PdfDocument();
    srcDoc.pages.add();
    final srcBytes = await srcDoc.save();
    srcDoc.dispose();
    await File(sourcePath).writeAsBytes(srcBytes, flush: true);

    final noteDoc = NoteDocument(
      id: 'd1',
      pdfPath: sourcePath,
      strokes: [
        Stroke(
          points: const [Offset(10, 10), Offset(120, 100)],
          pageIndex: 0,
          normalizedPoints: const [Offset(0.1, 0.1), Offset(0.6, 0.5)],
          width: 2,
        ),
      ],
      blocks: [
        ContentBlock(
          id: 'b1',
          content: 'Test block',
          pageIndex: 0,
          normalizedX: 0.2,
          normalizedY: 0.2,
        ),
      ],
    );

    final result = await PdfAnnotationExportService().exportAnnotatedPdf(
      noteDoc,
      outputRoot: temp,
    );

    expect(result.success, isTrue);
    expect(result.outputPath, isNotNull);
    expect(File(result.outputPath!).existsSync(), isTrue);
    expect(File(result.outputPath!).lengthSync(), greaterThan(0));
  });
}
