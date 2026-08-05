import 'dart:async';
import 'package:local_auth/local_auth.dart';
import '../../core/logger/app_logger.dart';
import '../../core/utils/crypto_utils.dart';
import '../storage/secure_storage_service.dart';

class SecurityService {
  static const String _tag = 'SecurityService';

  final LocalAuthentication _localAuth = LocalAuthentication();
  final SecureStorageService _secureStorage;

  DateTime _lastActiveTime = DateTime.now();
  bool _isAppUnlocked = false;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  SecurityService({required SecureStorageService secureStorage}) : _secureStorage = secureStorage;

  void updateLastActiveTime() {
    _lastActiveTime = DateTime.now();
  }

  bool shouldLockApp(int timeoutMinutes) {
    if (!_isAppUnlocked) return true;
    final diff = DateTime.now().difference(_lastActiveTime);
    return diff.inMinutes >= timeoutMinutes;
  }

  void unlockApp() {
    _isAppUnlocked = true;
    _failedAttempts = 0;
    _lockoutUntil = null;
    updateLastActiveTime();
  }

  void lockApp() {
    _isAppUnlocked = false;
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      AppLogger.e('Error checking biometric availability: $e', tag: _tag);
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics({
    String reason = 'Authenticate to access ScanX AI',
  }) async {
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      AppLogger.w('Authentication locked out due to too many failed attempts.', _tag);
      return false;
    }

    try {
      final isEnabled = await _secureStorage.getBiometricsEnabled();
      if (!isEnabled) return false;

      final result = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (result) {
        unlockApp();
      } else {
        _recordFailedAttempt();
      }
      return result;
    } catch (e) {
      AppLogger.e('Biometric authentication failed: $e', tag: _tag);
      _recordFailedAttempt();
      return false;
    }
  }

  Future<bool> verifyPin(String enteredPin) async {
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      AppLogger.w('PIN entry locked out temporarily.', _tag);
      return false;
    }

    final storedHash = await _secureStorage.getPinHash();
    if (storedHash == null) return false;

    final isValid = CryptoUtils.verifyPin(enteredPin, storedHash);
    if (isValid) {
      unlockApp();
    } else {
      _recordFailedAttempt();
    }
    return isValid;
  }

  Future<bool> verifyPattern(String enteredPattern) async {
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      AppLogger.w('Pattern entry locked out temporarily.', _tag);
      return false;
    }

    final storedHash = await _secureStorage.getPinHash();
    if (storedHash == null) return false;

    final isValid = CryptoUtils.verifyPin('PATTERN_$enteredPattern', storedHash);
    if (isValid) {
      unlockApp();
    } else {
      _recordFailedAttempt();
    }
    return isValid;
  }

  void _recordFailedAttempt() {
    _failedAttempts++;
    AppLogger.w('Failed authentication attempt (#$_failedAttempts)', _tag);
    if (_failedAttempts >= 5) {
      _lockoutUntil = DateTime.now().add(const Duration(seconds: 60));
      AppLogger.e('Too many failed attempts! Locked out for 60 seconds.', tag: _tag);
    }
  }

  Future<void> setPinCode(String pinCode) async {
    final hash = CryptoUtils.hashPin(pinCode);
    await _secureStorage.savePinHash(hash);
    unlockApp();
  }
}
