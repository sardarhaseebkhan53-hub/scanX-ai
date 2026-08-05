import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../core/logger/app_logger.dart';

class ImageProcessingService {
  static const String _tag = 'ImageProcessingService';

  Future<Map<String, dynamic>> evaluateImageSharpness(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        return {'score': 75, 'isBlurry': false};
      }

      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        return {'score': 75, 'isBlurry': false};
      }

      // Sample a 128x128 grayscale patch for fast Laplacian variance computation
      final resized = img.copyResize(image, width: 128, height: 128);
      final gray = img.grayscale(resized);

      double sum = 0.0;
      double sumSq = 0.0;
      int count = 0;

      for (int y = 1; y < gray.height - 1; y++) {
        for (int x = 1; x < gray.width - 1; x++) {
          final center = gray.getPixel(x, y).r;
          final top = gray.getPixel(x, y - 1).r;
          final bottom = gray.getPixel(x, y + 1).r;
          final left = gray.getPixel(x - 1, y).r;
          final right = gray.getPixel(x + 1, y).r;

          // Discrete Laplacian filter: 4*center - top - bottom - left - right
          final laplacian = (4 * center - top - bottom - left - right).abs();
          sum += laplacian;
          sumSq += laplacian * laplacian;
          count++;
        }
      }

      final mean = sum / count;
      final variance = (sumSq / count) - (mean * mean);

      // Normalize variance to a quality score between 10 and 100
      int score = min(100, max(10, (variance * 0.45).round()));
      bool isBlurry = score < 50;

      AppLogger.i('Computed Laplacian sharpness score: $score (isBlurry: $isBlurry)', _tag);
      return {'score': score, 'isBlurry': isBlurry};
    } catch (e) {
      AppLogger.e('Error evaluating image sharpness: $e', tag: _tag);
      return {'score': 85, 'isBlurry': false};
    }
  }

  Future<File?> rotateImageFile(File imageFile, int angleDegrees) async {
    try {
      if (!await imageFile.exists()) return null;

      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final normalizedAngle = angleDegrees % 360;
      final rotated = img.copyRotate(image, angle: normalizedAngle);
      final encoded = img.encodeJpg(rotated, quality: 100);

      final tempDir = await getTemporaryDirectory();
      final outFile = File('${tempDir.path}/rot_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await outFile.writeAsBytes(encoded);

      AppLogger.i('Rotated image by $angleDegrees° -> ${outFile.path}', _tag);
      return outFile;
    } catch (e) {
      AppLogger.e('Error rotating image file: $e', tag: _tag);
      return null;
    }
  }

  Future<Map<String, dynamic>> compressImageFile(
    File imageFile, {
    int maxDimension = 1280,
    int jpegQuality = 65,
  }) async {
    try {
      if (!await imageFile.exists()) {
        return {'file': imageFile, 'sizeBytes': 0, 'savingsPercent': 0};
      }

      final origSize = await imageFile.length();
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        return {'file': imageFile, 'sizeBytes': origSize, 'savingsPercent': 0};
      }

      img.Image processed = image;
      if (image.width > maxDimension || image.height > maxDimension) {
        if (image.width >= image.height) {
          processed = img.copyResize(image, width: maxDimension);
        } else {
          processed = img.copyResize(image, height: maxDimension);
        }
      }

      final encoded = img.encodeJpg(processed, quality: jpegQuality);
      final tempDir = await getTemporaryDirectory();
      final outFile = File('${tempDir.path}/comp_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await outFile.writeAsBytes(encoded);

      final newSize = await outFile.length();
      final savings = origSize > 0 ? ((origSize - newSize) / origSize * 100).round() : 0;

      AppLogger.i('Compressed image $origSize -> $newSize bytes ($savings% savings)', _tag);
      return {
        'file': outFile,
        'sizeBytes': newSize,
        'savingsPercent': max(0, savings),
      };
    } catch (e) {
      AppLogger.e('Error compressing image file: $e', tag: _tag);
      return {'file': imageFile, 'sizeBytes': 0, 'savingsPercent': 0};
    }
  }

  Future<File?> applyFilterPreset(File imageFile, String filterModeName) async {
    try {
      if (!await imageFile.exists()) return null;

      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      if (filterModeName == 'original') {
        return imageFile;
      }

      img.Image processed;

      switch (filterModeName) {
        case 'blackAndWhite':
          processed = img.grayscale(image);
          processed = img.contrast(processed, contrast: 175);
          break;
        case 'highContrast':
          processed = img.adjustColor(image, contrast: 1.45, brightness: 1.04, saturation: 0.92);
          processed = img.convolution(processed, filter: [0, -1, 0, -1, 5, -1, 0, -1, 0]);
          break;
        case 'grayscale':
          processed = img.grayscale(image);
          processed = img.contrast(processed, contrast: 118);
          break;
        case 'receipt':
        case 'book':
          processed = img.grayscale(image);
          processed = img.adjustColor(processed, brightness: 1.10, contrast: 1.28);
          break;
        case 'signature':
          processed = img.grayscale(image);
          processed = img.contrast(processed, contrast: 190);
          break;
        case 'passport':
        case 'photo':
          processed = img.adjustColor(image, saturation: 1.08, contrast: 1.08, brightness: 1.02);
          break;
        case 'color':
        case 'autoEnhanced':
        case 'magazine':
        case 'aiEnhance':
          processed = _enhanceDocument(image);
          break;
        case 'aiSharpen':
          processed = _enhanceDocument(image);
          processed = img.convolution(
            processed,
            filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
          );
          break;
        default:
          processed = image;
      }

      final encoded = img.encodeJpg(processed, quality: 95);
      final tempDir = await getTemporaryDirectory();
      final outFile = File('${tempDir.path}/filt_${filterModeName}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await outFile.writeAsBytes(encoded);

      AppLogger.i('Applied real pixel filter: $filterModeName -> ${outFile.path}', _tag);
      return outFile;
    } catch (e) {
      AppLogger.e('Error applying filter preset: $e', tag: _tag);
      return null;
    }
  }

  img.Image _enhanceDocument(img.Image image) {
    var processed = img.adjustColor(
      image,
      brightness: 1.06,
      contrast: 1.24,
      saturation: 1.14,
      gamma: 0.92,
    );
    processed = img.convolution(
      processed,
      filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
    );
    return processed;
  }

  Future<File?> applyManualAdjustments(
    File imageFile, {
    double brightness = 0.0,
    double contrast = 0.0,
    double saturation = 0.0,
    double sharpness = 50.0,
  }) async {
    try {
      if (!await imageFile.exists()) return null;

      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      img.Image processed = img.adjustColor(
        image,
        brightness: 1.0 + (brightness / 200.0),
        contrast: 1.0 + (contrast / 100.0),
        saturation: 1.0 + (saturation / 100.0),
      );

      if (sharpness > 65.0) {
        processed = img.convolution(
          processed,
          filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
        );
      }

      final encoded = img.encodeJpg(processed, quality: 95);
      final tempDir = await getTemporaryDirectory();
      final outFile = File('${tempDir.path}/adj_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await outFile.writeAsBytes(encoded);

      AppLogger.i('Applied manual color adjustments to pixels -> ${outFile.path}', _tag);
      return outFile;
    } catch (e) {
      AppLogger.e('Error applying manual adjustments: $e', tag: _tag);
      return null;
    }
  }
}
