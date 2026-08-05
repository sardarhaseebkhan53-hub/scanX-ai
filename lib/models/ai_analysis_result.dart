import 'package:equatable/equatable.dart';

class AIAnalysisResult extends Equatable {
  final String? summary;
  final String? explanation;
  final String? translatedText;
  final String? rewrittenText;
  final String? invoiceNumber;
  final String? vendorName;
  final String? date;
  final double? subtotal;
  final double? tax;
  final double? totalAmount;
  final String? currency;
  final List<Map<String, dynamic>> items;
  final String? suggestedTitle;
  final String? suggestedFolderName;
  final List<String> extractedTags;

  const AIAnalysisResult({
    this.summary,
    this.explanation,
    this.translatedText,
    this.rewrittenText,
    this.invoiceNumber,
    this.vendorName,
    this.date,
    this.subtotal,
    this.tax,
    this.totalAmount,
    this.currency = 'USD',
    this.items = const [],
    this.suggestedTitle,
    this.suggestedFolderName,
    this.extractedTags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'summary': summary,
      'explanation': explanation,
      'translatedText': translatedText,
      'rewrittenText': rewrittenText,
      'invoiceNumber': invoiceNumber,
      'vendorName': vendorName,
      'date': date,
      'subtotal': subtotal,
      'tax': tax,
      'totalAmount': totalAmount,
      'currency': currency,
      'items': items,
      'suggestedTitle': suggestedTitle,
      'suggestedFolderName': suggestedFolderName,
      'extractedTags': extractedTags,
    };
  }

  factory AIAnalysisResult.fromMap(Map<dynamic, dynamic> map) {
    return AIAnalysisResult(
      summary: map['summary'] as String?,
      explanation: map['explanation'] as String?,
      translatedText: map['translatedText'] as String?,
      rewrittenText: map['rewrittenText'] as String?,
      invoiceNumber: map['invoiceNumber'] as String?,
      vendorName: map['vendorName'] as String?,
      date: map['date'] as String?,
      subtotal: (map['subtotal'] as num?)?.toDouble(),
      tax: (map['tax'] as num?)?.toDouble(),
      totalAmount: (map['totalAmount'] as num?)?.toDouble(),
      currency: map['currency'] as String? ?? 'USD',
      items: (map['items'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      suggestedTitle: map['suggestedTitle'] as String?,
      suggestedFolderName: map['suggestedFolderName'] as String?,
      extractedTags: (map['extractedTags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  @override
  List<Object?> get props => [
        summary,
        explanation,
        translatedText,
        rewrittenText,
        invoiceNumber,
        vendorName,
        date,
        subtotal,
        tax,
        totalAmount,
        currency,
        items,
        suggestedTitle,
        suggestedFolderName,
        extractedTags,
      ];
}
