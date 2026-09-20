import 'dart:convert';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageBase64Service {
  Future<String> convertToCompressedBase64(
      XFile image,
      ) async {
    final originalFile = File(image.path);

    if (!await originalFile.exists()) {
      throw Exception('Selected image does not exist.');
    }

    final compressedBytes =
    await FlutterImageCompress.compressWithFile(
      image.path,
      minWidth: 1000,
      minHeight: 1000,
      quality: 55,
      format: CompressFormat.jpeg,
    );

    if (compressedBytes == null || compressedBytes.isEmpty) {
      throw Exception('Could not compress the image.');
    }

    return base64Encode(compressedBytes);
  }

  int base64SizeInBytes(String base64Image) {
    return utf8.encode(base64Image).length;
  }

  double base64SizeInKb(String base64Image) {
    return base64SizeInBytes(base64Image) / 1024;
  }
}
