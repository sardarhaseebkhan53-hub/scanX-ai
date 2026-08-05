import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/injection/injection_container.dart';
import '../../../../domain/repositories/security_repository.dart';

class SecurityState {
  final bool isBiometricAvailable;
  final bool isBiometricEnabled;
  final bool isPinEnabled;
  final bool isPatternEnabled;
  final int autoLockTimeoutMinutes;
  final bool hidePreviewForLockedFiles;
  final bool isUnlocked;
  final String? errorMessage;

  const SecurityState({
    this.isBiometricAvailable = false,
    this.isBiometricEnabled = false,
    this.isPinEnabled = false,
    this.isPatternEnabled = false,
    this.autoLockTimeoutMinutes = 5,
    this.hidePreviewForLockedFiles = true,
    this.isUnlocked = false,
    this.errorMessage,
  });

  SecurityState copyWith({
    bool? isBiometricAvailable,
    bool? isBiometricEnabled,
    bool? isPinEnabled,
    bool? isPatternEnabled,
    int? autoLockTimeoutMinutes,
    bool? hidePreviewForLockedFiles,
    bool? isUnlocked,
    String? errorMessage,
  }) {
    return SecurityState(
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isPinEnabled: isPinEnabled ?? this.isPinEnabled,
      isPatternEnabled: isPatternEnabled ?? this.isPatternEnabled,
      autoLockTimeoutMinutes: autoLockTimeoutMinutes ?? this.autoLockTimeoutMinutes,
      hidePreviewForLockedFiles: hidePreviewForLockedFiles ?? this.hidePreviewForLockedFiles,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      errorMessage: errorMessage,
    );
  }
}

class SecurityController extends StateNotifier<SecurityState> {
  final SecurityRepository _repository;

  SecurityController({SecurityRepository? repository})
      : _repository = repository ?? sl<SecurityRepository>(),
        super(const SecurityState()) {
    init();
  }

  Future<void> init() async {
    final bioAvailable = await _repository.isBiometricAvailable();
    final bioEnabled = await _repository.isBiometricEnabled();
    final pinEnabled = await _repository.isPinEnabled();

    state = state.copyWith(
      isBiometricAvailable: bioAvailable,
      isBiometricEnabled: bioEnabled,
      isPinEnabled: pinEnabled,
    );
  }

  Future<void> toggleBiometric(bool enabled) async {
    await _repository.setBiometricEnabled(enabled);
    state = state.copyWith(isBiometricEnabled: enabled);
  }

  Future<void> setPinCode(String pin) async {
    await _repository.setPinCode(pin);
    state = state.copyWith(isPinEnabled: true, isPatternEnabled: false);
  }

  Future<void> setPatternCode(String pattern) async {
    await _repository.setPinCode('PATTERN_$pattern');
    state = state.copyWith(isPatternEnabled: true, isPinEnabled: true);
  }

  Future<void> clearPinCode() async {
    await _repository.clearPinCode();
    state = state.copyWith(isPinEnabled: false, isPatternEnabled: false);
  }

  Future<bool> unlockWithPin(String pin) async {
    final success = await _repository.verifyPinCode(pin);
    if (success) {
      state = state.copyWith(isUnlocked: true, errorMessage: null);
    } else {
      state = state.copyWith(errorMessage: 'Invalid Vault PIN.');
    }
    return success;
  }

  Future<bool> unlockWithPattern(String pattern) async {
    final success = await _repository.verifyPinCode('PATTERN_$pattern');
    if (success) {
      state = state.copyWith(isUnlocked: true, errorMessage: null);
    } else {
      state = state.copyWith(errorMessage: 'Invalid Vault Pattern.');
    }
    return success;
  }

  Future<bool> unlockWithBiometrics() async {
    final success = await _repository.authenticateWithBiometric();
    if (success) {
      state = state.copyWith(isUnlocked: true, errorMessage: null);
    }
    return success;
  }

  void setTimeoutMinutes(int minutes) {
    state = state.copyWith(autoLockTimeoutMinutes: minutes);
  }

  void toggleHidePreview(bool hide) {
    state = state.copyWith(hidePreviewForLockedFiles: hide);
  }
}

final securityProvider = StateNotifierProvider<SecurityController, SecurityState>((ref) {
  return SecurityController();
});
