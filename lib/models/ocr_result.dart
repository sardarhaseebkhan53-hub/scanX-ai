import 'package:equatable/equatable.dart';

class OCRResult extends Equatable {
  final String text;
  final String detectedLanguage;
  final double confidence;
  final List<String> extractedDates;
  final List<String> extractedEmails;
  final List<String> extractedPhones;
  final List<String> extractedNames;
  final List<String> extractedUrls;
  final List<String> extractedAddresses;
  final String? translatedText;

  const OCRResult({
    required this.text,
    this.detectedLanguage = 'en',
    this.confidence = 0.95,
    this.extractedDates = const [],
    this.extractedEmails = const [],
    this.extractedPhones = const [],
    this.extractedNames = const [],
    this.extractedUrls = const [],
    this.extractedAddresses = const [],
    this.translatedText,
  });

  OCRResult copyWith({
    String? text,
    String? detectedLanguage,
    double? confidence,
    List<String>? extractedDates,
    List<String>? extractedEmails,
    List<String>? extractedPhones,
    List<String>? extractedNames,
    List<String>? extractedUrls,
    List<String>? extractedAddresses,
    String? translatedText,
  }) {
    return OCRResult(
      text: text ?? this.text,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      confidence: confidence ?? this.confidence,
      extractedDates: extractedDates ?? this.extractedDates,
      extractedEmails: extractedEmails ?? this.extractedEmails,
      extractedPhones: extractedPhones ?? this.extractedPhones,
      extractedNames: extractedNames ?? this.extractedNames,
      extractedUrls: extractedUrls ?? this.extractedUrls,
      extractedAddresses: extractedAddresses ?? this.extractedAddresses,
      translatedText: translatedText ?? this.translatedText,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'detectedLanguage': detectedLanguage,
      'confidence': confidence,
      'extractedDates': extractedDates,
      'extractedEmails': extractedEmails,
      'extractedPhones': extractedPhones,
      'extractedNames': extractedNames,
      'extractedUrls': extractedUrls,
      'extractedAddresses': extractedAddresses,
      'translatedText': translatedText,
    };
  }

  factory OCRResult.fromMap(Map<dynamic, dynamic> map) {
    return OCRResult(
      text: map['text'] as String? ?? '',
      detectedLanguage: map['detectedLanguage'] as String? ?? 'en',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.95,
      extractedDates: (map['extractedDates'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      extractedEmails: (map['extractedEmails'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      extractedPhones: (map['extractedPhones'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      extractedNames: (map['extractedNames'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      extractedUrls: (map['extractedUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      extractedAddresses: (map['extractedAddresses'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      translatedText: map['translatedText'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        text,
        detectedLanguage,
        confidence,
        extractedDates,
        extractedEmails,
        extractedPhones,
        extractedNames,
        extractedUrls,
        extractedAddresses,
        translatedText,
      ];
}
