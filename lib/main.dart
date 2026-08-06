import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/env.dart';
import 'config/firebase/firebase_config.dart';
import 'config/injection/injection_container.dart';
import 'config/routes/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/logger/app_logger.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/controllers/settings_controller.dart';
import 'services/ai/ai_service.dart';
import 'services/storage/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Do not force a fixed orientation. ScanX AI must adapt cleanly to phones,
  // tablets, foldables, portrait, and landscape using responsive layouts.

  try {
    // Initialize Firebase Enterprise Stack (Analytics, Crashlytics, FCM, Remote Config)
    await FirebaseConfig.initialize();
  } catch (e) {
    AppLogger.w('Firebase enterprise initialization skipped (offline mode): $e', 'Main');
  }

  try {
    // Initialize Clean Architecture Dependency Injection (GetIt & Hive Local Storage)
    await initDependencies();
  } catch (e) {
    AppLogger.e('Fatal dependency initialization error: $e', tag: 'Main');
  }

  try {
    // Provision the Groq API key (from local env.dart) into secure storage on
    // first run. The key is then read from the hardware-backed keystore.
    final secureStorage = sl<SecureStorageService>();
    final existing = await secureStorage.getAIKey('groq');
    if ((existing == null || existing.isEmpty) && EnvSecrets.groqApiKey.isNotEmpty) {
      await secureStorage.saveAIKey('groq', EnvSecrets.groqApiKey);
      AppLogger.i('Groq API key provisioned to secure storage.', 'Main');
    }
    final aiService = sl<AIService>();
    final key = await secureStorage.getAIKey('groq');
    if (aiService is PluggableAIService && key != null && key.isNotEmpty) {
      aiService.setProvider('groq', apiKey: key);
    }
  } catch (e) {
    AppLogger.w('Could not provision Groq key to secure storage: $e', 'Main');
  }

  AppLogger.i('Starting ScanX AI Application v${AppConstants.appVersion}', 'Main');

  runApp(
    const ProviderScope(
      child: ScanXAIApp(),
    ),
  );
}

class ScanXAIApp extends ConsumerWidget {
  const ScanXAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);

    ThemeMode themeMode;
    switch (settingsState.themeMode) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
    }

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
