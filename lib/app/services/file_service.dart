import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

class FileService {
  final ImagePicker _imagePicker = ImagePicker();

  Future<File?> pickImage() async {
    final result = await _imagePicker.pickImage(source: ImageSource.camera);
    return result != null ? File(result.path) : null;
  }

  Future<File?> pickFile({List<String>? allowedExtensions}) async {
    final result = await FilePicker.platform.pickFiles(allowedExtensions: allowedExtensions);
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final file = result.files.first;
    return File(file.path!);
  }

  String? mimeFromFile(File file) {
    return lookupMimeType(file.path);
  }
}
