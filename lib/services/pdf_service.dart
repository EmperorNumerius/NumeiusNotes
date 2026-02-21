import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Handles PDF file import — copies PDFs into app storage.
class PdfService {
  static final _uuid = const Uuid();

  /// Opens a file picker, copies the selected PDF into app docs, returns the path.
  static Future<String?> importPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.isEmpty) return null;

    final sourcePath = result.files.single.path;
    if (sourcePath == null) return null;

    // Copy to app directory
    final appDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory('${appDir.path}/NotesApp/pdfs');
    if (!pdfDir.existsSync()) pdfDir.createSync(recursive: true);

    final destPath = '${pdfDir.path}/${_uuid.v4()}.pdf';
    await File(sourcePath).copy(destPath);
    return destPath;
  }
}
