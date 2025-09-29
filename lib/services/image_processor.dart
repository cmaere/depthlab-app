import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../models/shared_image.dart';

class ImageProcessor {
  static Future<SharedImage> processImage(String imagePath) async {
    final file = File(imagePath);
    final fileName = file.path.split('/').last;
    
    try {
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      
      return SharedImage(
        path: imagePath,
        fileName: fileName,
        base64Data: base64String,
      );
    } catch (e) {
      throw Exception('Failed to process image: $e');
    }
  }

  static Future<Uint8List?> base64ToBytes(String base64String) async {
    try {
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  static String getImageExtension(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return extension;
  }

  static bool isValidImageFile(String fileName) {
    final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'heic', 'webp'];
    final extension = getImageExtension(fileName);
    return validExtensions.contains(extension);
  }

  static int getImageSizeInBytes(String base64String) {
    return base64Decode(base64String).length;
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}