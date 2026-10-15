import 'dart:io';

import 'package:image_picker/image_picker.dart';

/// Wraps `image_picker` so features do not depend on the plugin directly.
class ImagePickerService {
  ImagePickerService([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const int _maxWidth = 1600;
  static const int _imageQuality = 82;

  Future<File?> pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: _maxWidth.toDouble(),
      imageQuality: _imageQuality,
    );
    return file == null ? null : File(file.path);
  }

  Future<File?> pickFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: _maxWidth.toDouble(),
      imageQuality: _imageQuality,
    );
    return file == null ? null : File(file.path);
  }

  Future<List<File>> pickMultipleFromGallery({int limit = 5}) async {
    final files = await _picker.pickMultiImage(
      maxWidth: _maxWidth.toDouble(),
      imageQuality: _imageQuality,
      limit: limit,
    );
    return files.map((f) => File(f.path)).toList();
  }
}