import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';
import '../../core/logger/app_logger.dart';

class SecureStorageService {
  static const String _tag = 'SecureStorageService';

  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  Future<void> saveSecret(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      AppLogger.e('Failed to write secure key: $key', tag: _tag, error: e);
    }
  }

  Future<String?> readSecret(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      AppLogger.e('Failed to read secure key: $key', tag: _tag, error: e);
      return null;
    }
  }

  Future<void> deleteSecret(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      AppLogger.e('Failed to delete secure key: $key', tag: _tag, error: e);
    }
  }

  Future<void> savePinHash(String hash) async {
    await saveSecret(AppConstants.securePinHashKey, hash);
  }

  Future<String?> getPinHash() async {
    return await readSecret(AppConstants.securePinHashKey);
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await saveSecret(AppConstants.secureBiometricEnabledKey, enabled ? 'true' : 'false');
  }

  Future<bool> getBiometricsEnabled() async {
    final val = await readSecret(AppConstants.secureBiometricEnabledKey);
    return val == 'true';
  }

  Future<void> saveAIKey(String provider, String apiKey) async {
    final key = provider == 'gemini' ? AppConstants.secureGeminiKey : AppConstants.secureOpenAIKey;
    await saveSecret(key, apiKey);
  }

  Future<String?> getAIKey(String provider) async {
    final key = provider == 'gemini' ? AppConstants.secureGeminiKey : AppConstants.secureOpenAIKey;
    return await readSecret(key);
  }
}
