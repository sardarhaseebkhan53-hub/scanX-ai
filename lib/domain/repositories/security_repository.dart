abstract class SecurityRepository {
  Future<bool> isBiometricAvailable();
  Future<bool> authenticateWithBiometric({String reason = 'Authenticate to access ScanX AI'});
  Future<bool> verifyPinCode(String pinCode);
  Future<void> setPinCode(String pinCode);
  Future<void> clearPinCode();
  Future<void> setBiometricEnabled(bool enabled);
  Future<bool> isBiometricEnabled();
  Future<bool> isPinEnabled();
  Future<void> updateLastActiveTime();
  Future<bool> shouldAutoLock(int timeoutMinutes);
  Future<List<int>> encryptData(List<int> data);
  Future<List<int>> decryptData(List<int> encryptedData);
}
