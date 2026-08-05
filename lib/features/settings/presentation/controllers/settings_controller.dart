import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/injection/injection_container.dart';
import '../../../../models/app_settings.dart';
import '../../../../models/watermark_config.dart';
import '../../../../services/ai/ai_service.dart';
import '../../../../services/storage/local_storage_service.dart';
import '../../../../services/storage/secure_storage_service.dart';

class SettingsController extends StateNotifier<AppSettings> {
  final LocalStorageService _localStorage;
  final SecureStorageService _secureStorage;

  SettingsController({
    LocalStorageService? localStorage,
    SecureStorageService? secureStorage,
  })  : _localStorage = localStorage ?? sl<LocalStorageService>(),
        _secureStorage = secureStorage ?? sl<SecureStorageService>(),
        super(const AppSettings()) {
    unawaited(_loadSettings());
  }

  Future<void> _loadSettings() async {
    final s = await _localStorage.getSettings();
    if (mounted) state = s;
  }

  Future<void> setThemeMode(String mode) async {
    final updated = state.copyWith(themeMode: mode);
    state = updated;
    await _localStorage.saveSettings(updated);
  }

  Future<void> setLanguage(String langCode) async {
    final updated = state.copyWith(languageCode: langCode);
    state = updated;
    await _localStorage.saveSettings(updated);
  }

  Future<void> setAIProvider(String provider, {String? apiKey}) async {
    final updated = state.copyWith(aiProvider: provider);
    state = updated;
    await _localStorage.saveSettings(updated);

    if (apiKey != null && apiKey.isNotEmpty) {
      await _secureStorage.saveAIKey(provider, apiKey);
    }

    final aiService = sl<AIService>();
    if (aiService is PluggableAIService) {
      aiService.setProvider(provider, apiKey: apiKey);
    }
  }

  Future<void> toggleAutoEdge(bool val) async {
    final updated = state.copyWith(autoEdgeDetection: val);
    state = updated;
    await _localStorage.saveSettings(updated);
  }

  Future<void> setDefaultScanMode(String mode) async {
    final updated = state.copyWith(defaultScanMode: mode);
    state = updated;
    await _localStorage.saveSettings(updated);
  }

  Future<void> setDefaultEnhancement(String enhancement) async {
    final updated = state.copyWith(defaultEnhancement: enhancement);
    state = updated;
    await _localStorage.saveSettings(updated);
  }

  Future<void> setPdfQuality(String quality) async {
    final updated = state.copyWith(pdfQuality: quality);
    state = updated;
    await _localStorage.saveSettings(updated);
  }

  Future<void> updateWatermarkConfig(WatermarkConfig config) async {
    final updated = state.copyWith(defaultWatermarkConfig: config);
    state = updated;
    await _localStorage.saveSettings(updated);
  }

  Future<void> completeOnboarding() async {
    final updated = state.copyWith(hasSeenOnboarding: true);
    state = updated;
    await _localStorage.saveSettings(updated);
  }
}

final settingsProvider = StateNotifierProvider<SettingsController, AppSettings>((ref) {
  return SettingsController();
});
