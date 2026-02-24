import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Handles image import — copies selected image files into app storage.
class ImageService {
  static final _uuid = const Uuid();

  /// Opens a file picker, copies selected image into app docs, returns saved path.
  static Future<String?> importImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'],
    );

    if (result == null || result.files.isEmpty) return null;

    final sourcePath = result.files.single.path;
    if (sourcePath == null) return null;

    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) return null;

    final extension = sourcePath.split('.').last.toLowerCase();

    // Copy to app directory
    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${appDir.path}/NotesApp/images');
    if (!imageDir.existsSync()) imageDir.createSync(recursive: true);

    final destPath = '${imageDir.path}/${_uuid.v4()}.$extension';
    await sourceFile.copy(destPath);
    return destPath;
  }
}
