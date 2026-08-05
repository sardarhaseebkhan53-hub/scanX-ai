import 'dart:math';
import 'date_formatter.dart';

class FileUtils {
  static String formatFileSize(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final int i = (log(bytes) / log(1024)).floor();
    final double size = bytes / pow(1024, i);
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  static String getFileExtension(String path) {
    final idx = path.lastIndexOf('.');
    if (idx == -1) return '';
    return path.substring(idx + 1).toLowerCase();
  }

  static String getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  static String generateAutoFileName({
    required String prefix,
    String? category,
    String extension = 'pdf',
  }) {
    final timestamp = DateFormatter.formatForFileName(DateTime.now());
    final catString = (category != null && category.trim().isNotEmpty)
        ? '_${category.replaceAll(' ', '_')}'
        : '';
    return '${prefix}${catString}_$timestamp.$extension';
  }
}
