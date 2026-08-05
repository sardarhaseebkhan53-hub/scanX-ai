import 'package:flutter_test/flutter_test.dart';
import 'package:scanx_ai/core/constants/app_constants.dart';
import 'package:scanx_ai/models/watermark_config.dart';

void main() {
  group('WatermarkConfig Unit Tests', () {
    test('buildFormattedText generates app name and developer attribution by default', () {
      const config = WatermarkConfig();
      final text = config.buildFormattedText();

      expect(text, contains('Scanned with ${AppConstants.appName}'));
      expect(text, contains(AppConstants.developerName));
      expect(text, contains('Date:'));
    });

    test('buildFormattedText returns empty string when isEnabled is false', () {
      const config = WatermarkConfig(isEnabled: false);
      expect(config.buildFormattedText(), isEmpty);
    });

    test('toMap and fromMap serialize and deserialize accurately', () {
      const config = WatermarkConfig(
        isEnabled: true,
        customText: 'CONFIDENTIAL ENTERPRISE SCAN',
        position: 'center',
        opacity: 0.7,
        includeGps: true,
      );

      final map = config.toMap();
      final restored = WatermarkConfig.fromMap(map);

      expect(restored.isEnabled, isTrue);
      expect(restored.customText, equals('CONFIDENTIAL ENTERPRISE SCAN'));
      expect(restored.position, equals('center'));
      expect(restored.opacity, equals(0.7));
      expect(restored.includeGps, isTrue);
    });

    test('buildFormattedText includes custom text when specified', () {
      const config = WatermarkConfig(
        customText: 'Sardar Haseeb Technologies',
      );
      final text = config.buildFormattedText();

      expect(text, contains('Sardar Haseeb Technologies'));
    });
  });
}
