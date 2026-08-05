import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class CryptoUtils {
  static String hashPin(String pinCode) {
    final bytes = utf8.encode(pinCode);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool verifyPin(String enteredPin, String storedHash) {
    final enteredHash = hashPin(enteredPin);
    return enteredHash == storedHash;
  }

  static String generateMasterEncryptionKey([int length = 32]) {
    const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890!@#\$%^&*()-_=+';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  static String computeDocumentChecksum(List<int> fileBytes) {
    return sha256.convert(fileBytes).toString();
  }
}
