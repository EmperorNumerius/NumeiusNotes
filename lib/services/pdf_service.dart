import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class PdfImportBundle {
  final String originalPath;
  final String workingPath;

  const PdfImportBundle({
    required this.originalPath,
    required this.workingPath,
  });
}

/// Handles PDF file import by creating immutable original + editable working copies.
class PdfService {
  static final _uuid = const Uuid();

  static Future<PdfImportBundle?> importPdfBundle() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.isEmpty) return null;

    final sourcePath = result.files.single.path;
    if (sourcePath == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory('${appDir.path}/NotesApp/pdfs');
    if (!pdfDir.existsSync()) {
      pdfDir.createSync(recursive: true);
    }

    final id = _uuid.v4();
    final originalPath = '${pdfDir.path}/${id}_original.pdf';
    final workingPath = '${pdfDir.path}/${id}_working.pdf';

    await File(sourcePath).copy(originalPath);
    await File(sourcePath).copy(workingPath);

    return PdfImportBundle(
      originalPath: originalPath,
      workingPath: workingPath,
    );
  }

  /// Legacy helper returning only the editable working path.
  static Future<String?> importPdf() async {
    final bundle = await importPdfBundle();
    return bundle?.workingPath;
  }
}

