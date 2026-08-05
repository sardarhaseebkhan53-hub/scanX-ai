import 'package:flutter_test/flutter_test.dart';
import 'package:scanx_ai/core/utils/crypto_utils.dart';

void main() {
  group('CryptoUtils Unit Tests', () {
    test('hashPin returns consistent SHA-256 hash for identical PINs', () {
      final hash1 = CryptoUtils.hashPin('1234');
      final hash2 = CryptoUtils.hashPin('1234');
      expect(hash1, equals(hash2));
    });

    test('hashPin returns different hashes for different PINs', () {
      final hash1 = CryptoUtils.hashPin('1234');
      final hash2 = CryptoUtils.hashPin('4321');
      expect(hash1, isNot(equals(hash2)));
    });

    test('verifyPin correctly validates stored SHA-256 hash', () {
      const pin = '9876';
      final hash = CryptoUtils.hashPin(pin);
      expect(CryptoUtils.verifyPin(pin, hash), isTrue);
      expect(CryptoUtils.verifyPin('0000', hash), isFalse);
    });

    test('generateMasterEncryptionKey creates key of requested length', () {
      final key = CryptoUtils.generateMasterEncryptionKey(32);
      expect(key.length, equals(32));
    });
  });
}
