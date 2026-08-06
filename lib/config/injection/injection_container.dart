import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../data/datasources/firebase_cloud_datasource.dart';
import '../../data/datasources/hive_local_datasource.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../data/repositories/document_repository_impl.dart';
import '../../data/repositories/security_repository_impl.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/repositories/document_repository.dart';
import '../../domain/repositories/security_repository.dart';
import '../../services/ai/ai_service.dart';
import '../../services/cloud/cloud_sync_service.dart';
import '../../services/monetization/ad_service.dart';
import '../../services/monetization/billing_service.dart';
import '../../services/ocr/ocr_service.dart';
import '../../services/pdf/pdf_service.dart';
import '../../services/security/security_service.dart';
import '../../services/storage/local_storage_service.dart';
import '../../services/storage/secure_storage_service.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // External
  sl.registerLazySingleton<Dio>(() => Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      )));

  // Core Storage & Services
  final localStorage = LocalStorageService();
  await localStorage.init();
  sl.registerSingleton<LocalStorageService>(localStorage);

  sl.registerLazySingleton<SecureStorageService>(() => SecureStorageService());

  sl.registerLazySingleton<OCRService>(() => OCRService());
  sl.registerLazySingleton<PDFService>(() => PDFService());

  // AI engine defaults to Groq (super-fast OpenAI-compatible inference).
  // The API key is read from the device secure storage at resolution time.
  sl.registerLazySingleton<AIService>(() {
    final secureStorage = sl<SecureStorageService>();
    final service = PluggableAIService(dio: sl<Dio>(), provider: 'groq');
    // Best-effort: load the stored Groq key so AI features work after restart.
    // If the user picks another provider in Settings that wins at runtime.
    secureStorage.getAIKey('groq').then((key) {
      if (key != null && key.isNotEmpty) {
        service.setProvider('groq', apiKey: key);
      }
    });
    return service;
  });

  sl.registerLazySingleton<CloudSyncService>(
      () => CloudSyncService(localStorage: sl<LocalStorageService>()));

  sl.registerLazySingleton<SecurityService>(
      () => SecurityService(secureStorage: sl<SecureStorageService>()));

  // Register monetization services immediately and initialize them in the
  // background. This keeps cold start/home rendering fast while still allowing
  // the paywall/ad surfaces to observe live readiness when Google Play services
  // finish loading.
  final billingService = BillingService();
  sl.registerSingleton<BillingService>(billingService);
  unawaited(billingService.init());

  final adService = AdService();
  sl.registerSingleton<AdService>(adService);
  unawaited(adService.init());

  // Data Sources
  sl.registerLazySingleton<HiveLocalDataSource>(
      () => HiveLocalDataSource(localStorageService: sl<LocalStorageService>()));
  sl.registerLazySingleton<FirebaseCloudDataSource>(
      () => FirebaseCloudDataSource(cloudSyncService: sl<CloudSyncService>()));

  // Repositories
  sl.registerLazySingleton<DocumentRepository>(() => DocumentRepositoryImpl(
        localDataSource: sl<HiveLocalDataSource>(),
        cloudDataSource: sl<FirebaseCloudDataSource>(),
      ));

  sl.registerLazySingleton<AIRepository>(() => AIRepositoryImpl(
        aiService: sl<AIService>(),
        ocrService: sl<OCRService>(),
      ));

  sl.registerLazySingleton<SecurityRepository>(() => SecurityRepositoryImpl(
        securityService: sl<SecurityService>(),
        secureStorageService: sl<SecureStorageService>(),
      ));
}
