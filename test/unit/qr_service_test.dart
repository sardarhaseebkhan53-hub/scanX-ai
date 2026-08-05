import 'package:flutter_test/flutter_test.dart';
import 'package:scanx_ai/services/qr/qr_service.dart';

void main() {
  group('QRService & Wi-Fi Toolkit Unit Tests', () {
    late QRService qrService;

    setUp(() {
      qrService = QRService();
    });

    test('buildWifiQrString generates standard WIFI QR specification', () {
      final wifiStr = qrService.buildWifiQrString(
        ssid: 'ScanX_5G',
        password: 'SecurePassword123',
        security: 'WPA/WPA2',
        isHidden: false,
      );

      expect(wifiStr, equals('WIFI:S:ScanX_5G;T:WPA;P:SecurePassword123;H:false;;'));
    });

    test('buildVCardString generates standard vCard contact format', () {
      final vcard = qrService.buildVCardString(
        name: 'Sardar Haseeb',
        org: 'Sardar Haseeb Technologies',
        email: 'support@sardarhaseeb.com',
        phone: '+1-800-555-0199',
      );

      expect(vcard, contains('BEGIN:VCARD'));
      expect(vcard, contains('FN:Sardar Haseeb'));
      expect(vcard, contains('ORG:Sardar Haseeb Technologies'));
      expect(vcard, contains('END:VCARD'));
    });

    test('isUrlSafe detects suspicious executable or phishing patterns', () {
      expect(qrService.isUrlSafe('https://sardarhaseeb.com'), isTrue);
      expect(qrService.isUrlSafe('http://malicious-site.com/payload.apk'), isFalse);
      expect(qrService.isUrlSafe('https://example.com/login-phish-test'), isFalse);
    });

    test('detectQRType identifies QR payload schemes accurately', () {
      expect(qrService.detectQRType('WIFI:S:Test;T:WPA;P:pass;;'), equals('wifi'));
      expect(qrService.detectQRType('https://sardarhaseeb.com'), equals('url'));
      expect(qrService.detectQRType('mailto:support@sardarhaseeb.com'), equals('email'));
      expect(qrService.detectQRType('BEGIN:VCARD\nVERSION:3.0\nEND:VCARD'), equals('contact'));
      expect(qrService.detectQRType('Plain note text'), equals('text'));
    });
  });
}
