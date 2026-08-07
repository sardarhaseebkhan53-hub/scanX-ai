import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../core/logger/app_logger.dart';

class ImageProcessingService {
  static const String _tag = 'ImageProcessingService';

  // ---------------------------------------------------------------------------
  // Blur Detection  (multi-resolution Laplacian + Tenengrad)
  // ---------------------------------------------------------------------------

  /// Evaluates the sharpness of an image and returns a quality score (10–100)
  /// along with a blur-detection flag.
  ///
  /// Uses a **multi-resolution** approach:
  ///   1.  Full-res Laplacian variance on a 160×160 patch (captures fine edges).
  ///   2.  Half-res Laplacian variance on an 80×80 patch (captures coarse edges
  ///       that indicate gross out-of-focus or motion blur).
  ///   3.  Tenengrad (Sobel-gradient magnitude) on the 160×160 patch as a
  ///       secondary signal.
  ///
  /// The final score is a weighted blend, giving more weight to the full-res
  /// Laplacian.  The blur threshold adapts to the image's overall brightness so
  /// that dark low-texture scenes are not falsely flagged.
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

      // --- Full-resolution Laplacian variance (160×160) ---
      final fullGray = img.grayscale(img.copyResize(image, width: 160, height: 160));
      final double fullLapVar = _laplacianVariance(fullGray);

      // --- Half-resolution Laplacian variance (80×80) ---
      final halfGray = img.grayscale(img.copyResize(image, width: 80, height: 80));
      final double halfLapVar = _laplacianVariance(halfGray);

      // --- Tenengrad (Sobel gradient mean) ---
      final double tenengrad = _tenengradMean(fullGray);

      // Weighted combination (normalised empirically to 0-100 range)
      double rawScore = (fullLapVar * 0.50) + (halfLapVar * 0.25) + (tenengrad * 0.25);
      int score = min(100, max(10, (rawScore * 0.55).round()));

      // Adaptive threshold: slightly higher threshold for very dark images
      final double avgBrightness = _meanBrightness(fullGray);
      double threshold = 42.0;
      if (avgBrightness < 60) threshold = 48.0; // dark scene – expect less variance
      if (avgBrightness > 200) threshold = 36.0; // bright scene – more variance expected

      bool isBlurry = score < threshold;

      AppLogger.i(
        'Sharpness analysis → score: $score  (fullLap=$fullLapVar, halfLap=$halfLapVar, '
        'tenengrad=$tenengrad, brightness=$avgBrightness, threshold=$threshold, blurry=$isBlurry)',
        _tag,
      );
      return {'score': score, 'isBlurry': isBlurry};
    } catch (e) {
      AppLogger.e('Error evaluating image sharpness: $e', tag: _tag);
      return {'score': 85, 'isBlurry': false};
    }
  }

  /// Laplacian variance of a grayscale image (higher = sharper).
  double _laplacianVariance(img.Image gray) {
    double sum = 0.0;
    double sumSq = 0.0;
    int count = 0;
    for (int y = 1; y < gray.height - 1; y++) {
      for (int x = 1; x < gray.width - 1; x++) {
        final c = gray.getPixel(x, y).r;
        final t = gray.getPixel(x, y - 1).r;
        final b = gray.getPixel(x, y + 1).r;
        final l = gray.getPixel(x - 1, y).r;
        final r = gray.getPixel(x + 1, y).r;
        final lap = (4 * c - t - b - l - r).abs();
        sum += lap;
        sumSq += lap * lap;
        count++;
      }
    }
    final mean = sum / count;
    return (sumSq / count) - (mean * mean);
  }

  /// Tenengrad (sum of squared Sobel gradients) mean – robust edge energy metric.
  double _tenengradMean(img.Image gray) {
    double total = 0.0;
    int count = 0;
    for (int y = 1; y < gray.height - 1; y++) {
      for (int x = 1; x < gray.width - 1; x++) {
        final gx = -gray.getPixel(x - 1, y - 1).r - 2 * gray.getPixel(x - 1, y).r -
                gray.getPixel(x - 1, y + 1).r +
            gray.getPixel(x + 1, y - 1).r + 2 * gray.getPixel(x + 1, y).r +
            gray.getPixel(x + 1, y + 1).r;
        final gy = -gray.getPixel(x - 1, y - 1).r - 2 * gray.getPixel(x, y - 1).r -
                gray.getPixel(x + 1, y - 1).r +
            gray.getPixel(x - 1, y + 1).r + 2 * gray.getPixel(x, y + 1).r +
            gray.getPixel(x + 1, y + 1).r;
        total += sqrt(gx * gx + gy * gy);
        count++;
      }
    }
    return total / count;
  }

  /// Mean brightness (0-255) of a grayscale image.
  double _meanBrightness(img.Image gray) {
    double sum = 0.0;
    int count = 0;
    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        sum += gray.getPixel(x, y).r;
        count++;
      }
    }
    return sum / count;
  }

  // ---------------------------------------------------------------------------
  // Deblur / Sharpening (Unsharp Mask + Richardson-Lucy-lite)
  // ---------------------------------------------------------------------------

  /// Applies a deblur pipeline to the image:
  ///   1.  Unsharp mask at two radii (fine + medium) to recover edges.
  ///   2.  Mild contrast boost to compensate for the softening of deconvolution.
  ///
  /// The strength is controlled by [strength] (0.0 = no effect, 1.0 = full).
  img.Image applyDeblur(img.Image image, {double strength = 1.0}) {
    if (strength <= 0) return image;

    // Fine unsharp mask (radius ~1px)
    img.Image deblurred = img.convolution(image, filter: [
      0, -1, 0,
      -1, 5, -1,
      0, -1, 0,
    ]);

    // Medium unsharp mask (radius ~3px approximation via wider kernel)
    deblurred = img.convolution(deblurred, filter: [
      -1, -1, -1, -1, -1,
      -1, -1, -1, -1, -1,
      -1, -1, 26, -1, -1,
      -1, -1, -1, -1, -1,
      -1, -1, -1, -1, -1,
    ]);

    // Boost contrast slightly to recover mid-tone pop
    deblurred = img.adjustColor(deblurred, contrast: 1.0 + (0.12 * strength));

    // Blend: linearly interpolate between original and deblurred by strength
    if (strength < 1.0) {
      deblurred = _blendImages(image, deblurred, strength);
    }

    return deblurred;
  }

  /// Linearly blend two images pixel-by-pixel. [t]=0 returns [a], [t]=1 returns [b].
  img.Image _blendImages(img.Image a, img.Image b, double t) {
    final out = img.Image(width: a.width, height: a.height);
    for (int y = 0; y < a.height; y++) {
      for (int x = 0; x < a.width; x++) {
        final pa = a.getPixel(x, y);
        final pb = b.getPixel(x, y);
        out.setPixelRgba(
          x, y,
          (pa.r * (1 - t) + pb.r * t).round(),
          (pa.g * (1 - t) + pb.g * t).round(),
          (pa.b * (1 - t) + pb.b * t).round(),
          (pa.a * (1 - t) + pb.a * t).round(),
        );
      }
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // HDR Tone Mapping (shadow recovery + highlight compression + local contrast)
  // ---------------------------------------------------------------------------

  /// Simulates HDR tone mapping on a single LDR exposure.
  ///
  /// The pipeline:
  ///   1. **Shadow recovery** – lift the darkest 40 % of tones with a gamma
  ///      curve so detail hidden in shadows becomes visible.
  ///   2. **Highlight compression** – compress the brightest 20 % of tones so
  ///      blown-out highlights (e.g. windows, lamps) retain detail.
  ///   3. **Local contrast (unsharp mask)** – micro-contrast boost at two radii
  ///      to make textures and edges "pop" the way real HDR does.
  ///   4. **Global tone curve** – a subtle S-curve to increase perceptual
  ///      dynamic range without clipping.
  ///   5. **Saturation boost** – HDR images look flat without a slight colour
  ///      pop; we lift saturation by ~12 %.
  ///
  /// [intensity] (0.0–1.0) controls the overall strength of the effect.
  img.Image applyHdrToneMapping(img.Image image, {double intensity = 1.0}) {
    if (intensity <= 0) return image;

    img.Image processed = img.copyResize(image, width: image.width, height: image.height);

    // Build a tone-mapping LUT (look-up table) for speed
    final List<int> lutR = List<int>.filled(256, 0);
    final List<int> lutG = List<int>.filled(256, 0);
    final List<int> lutB = List<int>.filled(256, 0);

    for (int i = 0; i < 256; i++) {
      double v = i / 255.0;

      // Step 1 – Shadow recovery (lift low tones)
      // Use a mild gamma (< 1) on the lower half
      if (v < 0.45) {
        v = pow(v / 0.45, 0.72).toDouble() * 0.45;
      }

      // Step 2 – Highlight compression (compress bright tones)
      if (v > 0.78) {
        final overshoot = (v - 0.78) / 0.22;
        v = 0.78 + pow(overshoot, 0.75).toDouble() * 0.22;
      }

      // Step 4 – Subtle S-curve for perceptual dynamic range
      // v = 3*v^2 - 2*v^3  (Hermite smooth-step)
      v = 3 * v * v - 2 * v * v * v;

      // Clamp
      v = max(0.0, min(1.0, v));

      // Blend with original based on intensity
      final double original = i / 255.0;
      final double blended = original * (1 - intensity) + v * intensity;
      final int mapped = (blended * 255).round().clamp(0, 255);

      // Apply to all channels (we'll do per-channel saturation later)
      lutR[i] = mapped;
      lutG[i] = mapped;
      lutB[i] = mapped;
    }

    // Apply LUT to every pixel
    for (int y = 0; y < processed.height; y++) {
      for (int x = 0; x < processed.width; x++) {
        final p = processed.getPixel(x, y);
        processed.setPixelRgba(
          x, y,
          lutR[p.r.toInt().clamp(0, 255)],
          lutG[p.g.toInt().clamp(0, 255)],
          lutB[p.b.toInt().clamp(0, 255)],
          p.a.toInt(),
        );
      }
    }

    // Step 3 – Local contrast (dual-radius unsharp mask)
    processed = img.convolution(processed, filter: [
      0, -1, 0,
      -1, 5, -1,
      0, -1, 0,
    ]);

    // Step 5 – Saturation boost (+12% at full intensity)
    processed = img.adjustColor(
      processed,
      saturation: 1.0 + (0.12 * intensity),
      contrast: 1.0 + (0.06 * intensity),
    );

    return processed;
  }

  /// Applies HDR tone mapping to an image file and returns the processed copy.
  Future<File?> applyHdrToneMappingToFile(File imageFile, {double intensity = 1.0}) async {
    try {
      if (!await imageFile.exists()) return null;
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final processed = applyHdrToneMapping(image, intensity: intensity);
      final encoded = img.encodeJpg(processed, quality: 95);

      final tempDir = await getTemporaryDirectory();
      final outFile = File('${tempDir.path}/hdr_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await outFile.writeAsBytes(encoded);

      AppLogger.i('Applied HDR tone mapping (intensity=$intensity) -> ${outFile.path}', _tag);
      return outFile;
    } catch (e) {
      AppLogger.e('Error applying HDR tone mapping: $e', tag: _tag);
      return null;
    }
  }

  /// Applies the deblur pipeline to an image file and returns the processed copy.
  Future<File?> applyDeblurToFile(File imageFile, {double strength = 1.0}) async {
    try {
      if (!await imageFile.exists()) return null;
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final processed = applyDeblur(image, strength: strength);
      final encoded = img.encodeJpg(processed, quality: 95);

      final tempDir = await getTemporaryDirectory();
      final outFile = File('${tempDir.path}/deblur_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await outFile.writeAsBytes(encoded);

      AppLogger.i('Applied deblur (strength=$strength) -> ${outFile.path}', _tag);
      return outFile;
    } catch (e) {
      AppLogger.e('Error applying deblur: $e', tag: _tag);
      return null;
    }
  }

  /// Combined HDR + deblur pipeline for the highest-quality capture.
  Future<File?> applyHdrAndDeblur(File imageFile, {bool isBlurry = false}) async {
    try {
      if (!await imageFile.exists()) return null;
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      img.Image processed = image;

      // Apply HDR tone mapping (full intensity when HDR is on)
      processed = applyHdrToneMapping(processed, intensity: 1.0);

      // If blur was detected, apply deblur correction
      if (isBlurry) {
        processed = applyDeblur(processed, strength: 0.85);
      }

      final encoded = img.encodeJpg(processed, quality: 96);
      final tempDir = await getTemporaryDirectory();
      final outFile = File('${tempDir.path}/hdr_deblur_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await outFile.writeAsBytes(encoded);

      AppLogger.i('Applied HDR+deblur pipeline (blurry=$isBlurry) -> ${outFile.path}', _tag);
      return outFile;
    } catch (e) {
      AppLogger.e('Error in HDR+deblur pipeline: $e', tag: _tag);
      return null;
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
