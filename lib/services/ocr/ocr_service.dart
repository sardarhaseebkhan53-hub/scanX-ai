import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../core/logger/app_logger.dart';
import '../../models/ocr_result.dart';

class OCRService {
  static const String _tag = 'OCRService';

  final List<TextRecognizer> _recognizers = [
    TextRecognizer(script: TextRecognitionScript.latin),
    TextRecognizer(script: TextRecognitionScript.devanagiri),
  ];

  Future<OCRResult> recognizeTextFromFile(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        return const OCRResult(text: '', confidence: 0.0);
      }

      final inputImage = InputImage.fromFile(imageFile);
      RecognizedText? bestResult;
      for (final recognizer in _recognizers) {
        try {
          final result = await recognizer.processImage(inputImage);
          if (bestResult == null || result.text.length > bestResult.text.length) {
            bestResult = result;
          }
        } catch (e) {
          AppLogger.w('OCR recognizer pass skipped: $e', _tag);
        }
      }

      final text = bestResult?.text.trim() ?? '';
      AppLogger.i('OCR completed. Recognized ${text.length} characters.', _tag);
      return _buildResult(text, confidence: text.isEmpty ? 0.0 : 0.96);
    } catch (e) {
      AppLogger.e('OCR text recognition failed: $e', tag: _tag);
      return const OCRResult(
        text: '',
        confidence: 0.0,
        extractedDates: [],
        extractedEmails: [],
        extractedPhones: [],
        extractedNames: [],
        extractedUrls: [],
        extractedAddresses: [],
      );
    }
  }

  Future<OCRResult> extractEntitiesFromText(String text) async {
    return _buildResult(text, confidence: text.trim().isEmpty ? 0.0 : 1.0);
  }

  OCRResult _buildResult(String text, {required double confidence}) {
    return OCRResult(
      text: text,
      confidence: confidence,
      extractedDates: _extractDates(text),
      extractedEmails: _extractEmails(text),
      extractedPhones: _extractPhones(text),
      extractedNames: _extractNames(text),
      extractedUrls: _extractUrls(text),
      extractedAddresses: _extractAddresses(text),
    );
  }

  List<String> _extractDates(String text) {
    final regex = RegExp(
      r'\b(\d{4}[-/.]\d{2}[-/.]\d{2}|\d{2}[-/.]\d{2}[-/.]\d{4}|[A-Z][a-z]{2,8}\s+\d{1,2},\s+\d{4})\b',
    );
    return regex.allMatches(text).map((m) => m.group(0)!).toSet().toList();
  }

  List<String> _extractEmails(String text) {
    final regex = RegExp(
      r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
    );
    return regex.allMatches(text).map((m) => m.group(0)!).toSet().toList();
  }

  List<String> _extractPhones(String text) {
    final regex = RegExp(
      r'(\+\d{1,3}[\s-]?)?(\(\d{3}\)|\d{3})[\s-]?\d{3}[\s-]?\d{4}|\b\d{10,14}\b',
    );
    return regex.allMatches(text).map((m) => m.group(0)!).toSet().toList();
  }

  List<String> _extractNames(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final names = <String>[];
    for (final line in lines.take(8)) {
      final trimmed = line.trim();
      if (trimmed.length < 45 && RegExp(r'^[A-Z][a-z]+(\s+[A-Z][a-z]+)+$').hasMatch(trimmed)) {
        names.add(trimmed);
      }
    }
    return names.toSet().toList();
  }

  List<String> _extractUrls(String text) {
    final regex = RegExp(
      r'\b(https?://\S+|www\.\S+)\b',
      caseSensitive: false,
    );
    return regex.allMatches(text).map((m) => m.group(0)!).toSet().toList();
  }

  List<String> _extractAddresses(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final addresses = <String>[];
    final addressRegex = RegExp(
      r'\b(\d{1,5}\s+[a-zA-Z0-9\s.,-]+(St|Street|Ave|Avenue|Rd|Road|Blvd|Drive|Dr|Lane|Ln|Way|Pl|Place|Court|Ct|Sq|Square|HQ|Islamabad|Karachi|Lahore|NY|CA|TX|London|Dubai|Doha|Riyadh)\b[a-zA-Z0-9\s.,-]*)',
      caseSensitive: false,
    );
    for (final line in lines) {
      final m = addressRegex.firstMatch(line);
      if (m != null && m.group(0)!.length > 10) {
        addresses.add(m.group(0)!.trim());
      }
    }
    return addresses.toSet().toList();
  }

  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.close();
    }
  }
}
