import 'package:equatable/equatable.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/date_formatter.dart';

enum WatermarkPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  center,
  custom,
}

class WatermarkConfig extends Equatable {
  final bool isEnabled;
  final String customText;
  final String position; // 'topLeft', 'topRight', 'bottomLeft', 'bottomRight', 'center', 'custom'
  final double opacity;
  final double rotationAngle;
  final double fontSize;
  final String colorHex;
  final bool includeAppName;
  final bool includeDeveloperName;
  final bool includeDate;
  final bool includeTime;
  final bool includeGps;
  final bool includeScanId;
  final bool includeQrCode;
  final bool includeSignature;
  final double margin;
  final double borderRadius;

  const WatermarkConfig({
    this.isEnabled = true,
    this.customText = '',
    this.position = 'bottomRight',
    this.opacity = 0.85,
    this.rotationAngle = 0.0,
    this.fontSize = 12.0,
    this.colorHex = '#64748B',
    this.includeAppName = true,
    this.includeDeveloperName = true,
    this.includeDate = true,
    this.includeTime = false,
    this.includeGps = false,
    this.includeScanId = false,
    this.includeQrCode = false,
    this.includeSignature = false,
    this.margin = 16.0,
    this.borderRadius = 8.0,
  });

  String buildFormattedText() {
    if (!isEnabled) return '';

    final lines = <String>[];

    if (includeAppName) {
      lines.add('Scanned with ${AppConstants.appName}');
    }
    if (includeDeveloperName) {
      lines.add(AppConstants.developerName);
    }
    if (customText.trim().isNotEmpty) {
      lines.add(customText.trim());
    }
    if (includeDate) {
      final dateStr = DateFormatter.formatShortDate(DateTime.now());
      if (includeTime) {
        final timeStr = DateFormatter.formatFullDateTime(DateTime.now());
        lines.add('Date: $timeStr');
      } else {
        lines.add('Date: $dateStr');
      }
    }
    if (includeScanId) {
      lines.add('Scan ID: ${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}');
    }

    if (lines.isEmpty) {
      return 'Scanned with ${AppConstants.appName}\n${AppConstants.developerName}';
    }

    return lines.join('\n');
  }

  WatermarkConfig copyWith({
    bool? isEnabled,
    String? customText,
    String? position,
    double? opacity,
    double? rotationAngle,
    double? fontSize,
    String? colorHex,
    bool? includeAppName,
    bool? includeDeveloperName,
    bool? includeDate,
    bool? includeTime,
    bool? includeGps,
    bool? includeScanId,
    bool? includeQrCode,
    bool? includeSignature,
    double? margin,
    double? borderRadius,
  }) {
    return WatermarkConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      customText: customText ?? this.customText,
      position: position ?? this.position,
      opacity: opacity ?? this.opacity,
      rotationAngle: rotationAngle ?? this.rotationAngle,
      fontSize: fontSize ?? this.fontSize,
      colorHex: colorHex ?? this.colorHex,
      includeAppName: includeAppName ?? this.includeAppName,
      includeDeveloperName: includeDeveloperName ?? this.includeDeveloperName,
      includeDate: includeDate ?? this.includeDate,
      includeTime: includeTime ?? this.includeTime,
      includeGps: includeGps ?? this.includeGps,
      includeScanId: includeScanId ?? this.includeScanId,
      includeQrCode: includeQrCode ?? this.includeQrCode,
      includeSignature: includeSignature ?? this.includeSignature,
      margin: margin ?? this.margin,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'customText': customText,
      'position': position,
      'opacity': opacity,
      'rotationAngle': rotationAngle,
      'fontSize': fontSize,
      'colorHex': colorHex,
      'includeAppName': includeAppName,
      'includeDeveloperName': includeDeveloperName,
      'includeDate': includeDate,
      'includeTime': includeTime,
      'includeGps': includeGps,
      'includeScanId': includeScanId,
      'includeQrCode': includeQrCode,
      'includeSignature': includeSignature,
      'margin': margin,
      'borderRadius': borderRadius,
    };
  }

  factory WatermarkConfig.fromMap(Map<dynamic, dynamic> map) {
    return WatermarkConfig(
      isEnabled: map['isEnabled'] as bool? ?? true,
      customText: map['customText'] as String? ?? '',
      position: map['position'] as String? ?? 'bottomRight',
      opacity: (map['opacity'] as num?)?.toDouble() ?? 0.85,
      rotationAngle: (map['rotationAngle'] as num?)?.toDouble() ?? 0.0,
      fontSize: (map['fontSize'] as num?)?.toDouble() ?? 12.0,
      colorHex: map['colorHex'] as String? ?? '#64748B',
      includeAppName: map['includeAppName'] as bool? ?? true,
      includeDeveloperName: map['includeDeveloperName'] as bool? ?? true,
      includeDate: map['includeDate'] as bool? ?? true,
      includeTime: map['includeTime'] as bool? ?? false,
      includeGps: map['includeGps'] as bool? ?? false,
      includeScanId: map['includeScanId'] as bool? ?? false,
      includeQrCode: map['includeQrCode'] as bool? ?? false,
      includeSignature: map['includeSignature'] as bool? ?? false,
      margin: (map['margin'] as num?)?.toDouble() ?? 16.0,
      borderRadius: (map['borderRadius'] as num?)?.toDouble() ?? 8.0,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        customText,
        position,
        opacity,
        rotationAngle,
        fontSize,
        colorHex,
        includeAppName,
        includeDeveloperName,
        includeDate,
        includeTime,
        includeGps,
        includeScanId,
        includeQrCode,
        includeSignature,
        margin,
        borderRadius,
      ];
}
