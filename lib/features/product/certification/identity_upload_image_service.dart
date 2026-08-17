import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'identity_upload_method.dart';

abstract interface class IdentityUploadImagePicker {
  Future<String?> pick(IdentityUploadMethod method);
}

abstract interface class IdentityUploadImageCompressor {
  Future<String?> compressToLimit(String sourcePath);
}

class DefaultIdentityUploadImagePicker implements IdentityUploadImagePicker {
  DefaultIdentityUploadImagePicker({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  @override
  Future<String?> pick(IdentityUploadMethod method) async {
    final file = await _imagePicker.pickImage(
      source: method == IdentityUploadMethod.camera
          ? ImageSource.camera
          : ImageSource.gallery,
    );
    return file?.path;
  }
}

class DefaultIdentityUploadImageCompressor
    implements IdentityUploadImageCompressor {
  static const _maximumBytes = 500 * 1024;

  @override
  Future<String?> compressToLimit(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) return null;

    final directory = await getTemporaryDirectory();
    var quality = 90;
    var scale = 1.0;
    for (var attempt = 0; attempt < 20; attempt++) {
      final targetPath =
          '${directory.path}/identity_${DateTime.now().microsecondsSinceEpoch}_$attempt.jpg';
      final compressed = await FlutterImageCompress.compressAndGetFile(
        source.path,
        targetPath,
        format: CompressFormat.jpeg,
        quality: quality,
        minWidth: (4096 * scale).round(),
        minHeight: (4096 * scale).round(),
      );
      if (compressed == null) return null;

      final compressedFile = File(compressed.path);
      if (await compressedFile.length() <= _maximumBytes) {
        return compressedFile.path;
      }
      if (quality > 10) {
        quality -= 10;
      } else {
        scale *= 0.95;
      }
    }
    return null;
  }
}
