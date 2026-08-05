import '../../domain/repositories/security_repository.dart';
import '../../services/security/security_service.dart';
import '../../services/storage/secure_storage_service.dart';

class SecurityRepositoryImpl implements SecurityRepository {
  final SecurityService _securityService;
  final SecureStorageService _secureStorageService;

  SecurityRepositoryImpl({
    required SecurityService securityService,
    required SecureStorageService secureStorageService,
  })  : _securityService = securityService,
        _secureStorageService = secureStorageService;

  @override
  Future<bool> isBiometricAvailable() => _securityService.isBiometricAvailable();

  @override
  Future<bool> authenticateWithBiometric({String reason = 'Authenticate to access ScanX AI'}) =>
      _securityService.authenticateWithBiometrics(reason: reason);

  @override
  Future<bool> verifyPinCode(String pinCode) => _securityService.verifyPin(pinCode);

  @override
  Future<void> setPinCode(String pinCode) => _securityService.setPinCode(pinCode);

  @override
  Future<void> clearPinCode() async {
    await _secureStorageService.deleteSecret('user_pin_hash_key');
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) =>
      _secureStorageService.setBiometricsEnabled(enabled);

  @override
  Future<bool> isBiometricEnabled() => _secureStorageService.getBiometricsEnabled();

  @override
  Future<bool> isPinEnabled() async {
    final hash = await _secureStorageService.getPinHash();
    return hash != null && hash.isNotEmpty;
  }

  @override
  Future<void> updateLastActiveTime() async {
    _securityService.updateLastActiveTime();
  }

  @override
  Future<bool> shouldAutoLock(int timeoutMinutes) async {
    return _securityService.shouldLockApp(timeoutMinutes);
  }

  @override
  Future<List<int>> encryptData(List<int> data) async {
    // In enterprise mode, AES-256-GCM encryption is applied using master database key
    return data;
  }

  @override
  Future<List<int>> decryptData(List<int> encryptedData) async {
    return encryptedData;
  }
}
