import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../core/logger/app_logger.dart';

class FirebaseConfig {
  static const String _tag = 'FirebaseConfig';

  static FirebaseAnalytics? analytics;
  static FirebaseRemoteConfig? remoteConfig;

  static bool get isInitialized => Firebase.apps.isNotEmpty;

  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      AppLogger.i('Firebase app initialized.', _tag);

      if (!kDebugMode && isInitialized) {
        FlutterError.onError = (errorDetails) {
          try {
            FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
          } catch (_) {}
        };
        PlatformDispatcher.instance.onError = (error, stack) {
          try {
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          } catch (_) {}
          return true;
        };
      }

      if (isInitialized) {
        try {
          analytics = FirebaseAnalytics.instance;
        } catch (_) {}

        try {
          remoteConfig = FirebaseRemoteConfig.instance;
          await remoteConfig!.setConfigSettings(RemoteConfigSettings(
            fetchTimeout: const Duration(seconds: 10),
            minimumFetchInterval: const Duration(hours: 1),
          ));
          await remoteConfig!.setDefaults({
            'enable_openai_fallback': true,
            'max_free_scans': 15,
            'banner_ads_enabled': true,
          });
          await remoteConfig!.fetchAndActivate();
        } catch (e) {
          AppLogger.w('Remote config fetch failed (offline mode): $e', _tag);
        }

        await _setupNotifications();
      }
    } catch (e) {
      AppLogger.w('Firebase initialization not available (Running in Local-First Offline Mode): $e', _tag);
    }
  }

  static Future<void> _setupNotifications() async {
    if (!isInitialized) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      AppLogger.i('FCM permission status: ${settings.authorizationStatus}', _tag);
    } catch (e) {
      AppLogger.w('FCM permission request failed: $e', _tag);
    }
  }

  static Future<void> logScanCompleted({required String mode, required int pageCount}) async {
    if (!isInitialized || analytics == null) return;
    try {
      await analytics!.logEvent(
        name: 'scan_completed',
        parameters: {
          'scan_mode': mode,
          'page_count': pageCount,
        },
      );
    } catch (_) {}
  }

  static Future<void> logQrGenerated({required String type}) async {
    if (!isInitialized || analytics == null) return;
    try {
      await analytics!.logEvent(
        name: 'qr_generated',
        parameters: {
          'qr_type': type,
        },
      );
    } catch (_) {}
  }

  static Future<void> logPdfExported({required String format}) async {
    if (!isInitialized || analytics == null) return;
    try {
      await analytics!.logEvent(
        name: 'pdf_exported',
        parameters: {
          'export_format': format,
        },
      );
    } catch (_) {}
  }

  static Future<void> logPremiumTrialStarted() async {
    if (!isInitialized || analytics == null) return;
    try {
      await analytics!.logEvent(name: 'premium_trial_started');
    } catch (_) {}
  }

  static Future<void> logError(Object error, StackTrace stackTrace) async {
    if (!isInitialized) return;
    try {
      if (!kDebugMode) {
        await FirebaseCrashlytics.instance.recordError(error, stackTrace);
      }
    } catch (_) {}
  }
}
