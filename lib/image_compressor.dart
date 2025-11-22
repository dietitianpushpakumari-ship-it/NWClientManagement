import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p; // Add 'path' to pubspec.yaml if missing

class ImageCompressor {
  /// Compresses an image file to WebP format and saves it locally.
  static Future<File?> compressAndGetFile(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      // Create a unique target path for the compressed image
      final targetPath = p.join(dir.path, "chat_${DateTime.now().millisecondsSinceEpoch}.webp");

      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 40, // Adjust quality (0-100). 70 is a good balance.
        format: CompressFormat.webp, // 🎯 Using WebP for efficiency
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      print("Image Compression Failed: $e");
      return null; // Return original if compression fails (optional logic)
    }
  }
}