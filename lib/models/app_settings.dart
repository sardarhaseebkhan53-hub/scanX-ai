import 'package:equatable/equatable.dart';
import 'watermark_config.dart';

class AppSettings extends Equatable {
  final String themeMode; // 'light', 'dark', 'system'
  final String languageCode;
  final bool biometricEnabled;
  final bool pinEnabled;
  final String? pinHash;
  final int autoLockTimeoutMinutes;
  final String aiProvider; // 'gemini', 'openai', 'device'
  final bool defaultCameraFlash;
  final bool autoEdgeDetection;
  final bool shadowRemovalEnabled;
  final bool blurDetectionEnabled;
  final bool autoSyncEnabled;
  final bool hidePreviewForLockedFiles;
  final String defaultScanMode; // 'document', 'receipt', 'book', 'passport', 'idCard', 'businessCard', 'whiteboard', 'batch'
  final String defaultEnhancement; // 'autoEnhanced', 'original', 'color', 'blackAndWhite', 'grayscale', ...
  final String defaultExportFormat; // 'pdf', 'jpeg', 'png'
  final String pdfQuality; // 'high', 'lossless', 'balanced', 'compressed'
  final String imageQuality; // 'high', 'balanced'
  final bool autoSaveEnabled;
  final bool autoUploadEnabled;
  final bool autoBackupEnabled;
  final bool hasSeenOnboarding;
  final WatermarkConfig defaultWatermarkConfig;

  const AppSettings({
    this.themeMode = 'system',
    this.languageCode = 'en',
    this.biometricEnabled = false,
    this.pinEnabled = false,
    this.pinHash,
    this.autoLockTimeoutMinutes = 5,
    this.aiProvider = 'gemini',
    this.defaultCameraFlash = false,
    this.autoEdgeDetection = true,
    this.shadowRemovalEnabled = true,
    this.blurDetectionEnabled = true,
    this.autoSyncEnabled = true,
    this.hidePreviewForLockedFiles = true,
    this.defaultScanMode = 'document',
    this.defaultEnhancement = 'autoEnhanced',
    this.defaultExportFormat = 'pdf',
    this.pdfQuality = 'high',
    this.imageQuality = 'high',
    this.autoSaveEnabled = true,
    this.autoUploadEnabled = true,
    this.autoBackupEnabled = true,
    this.hasSeenOnboarding = false,
    this.defaultWatermarkConfig = const WatermarkConfig(),
  });

  AppSettings copyWith({
    String? themeMode,
    String? languageCode,
    bool? biometricEnabled,
    bool? pinEnabled,
    String? pinHash,
    int? autoLockTimeoutMinutes,
    String? aiProvider,
    bool? defaultCameraFlash,
    bool? autoEdgeDetection,
    bool? shadowRemovalEnabled,
    bool? blurDetectionEnabled,
    bool? autoSyncEnabled,
    bool? hidePreviewForLockedFiles,
    String? defaultScanMode,
    String? defaultEnhancement,
    String? defaultExportFormat,
    String? pdfQuality,
    String? imageQuality,
    bool? autoSaveEnabled,
    bool? autoUploadEnabled,
    bool? autoBackupEnabled,
    bool? hasSeenOnboarding,
    WatermarkConfig? defaultWatermarkConfig,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      pinHash: pinHash ?? this.pinHash,
      autoLockTimeoutMinutes: autoLockTimeoutMinutes ?? this.autoLockTimeoutMinutes,
      aiProvider: aiProvider ?? this.aiProvider,
      defaultCameraFlash: defaultCameraFlash ?? this.defaultCameraFlash,
      autoEdgeDetection: autoEdgeDetection ?? this.autoEdgeDetection,
      shadowRemovalEnabled: shadowRemovalEnabled ?? this.shadowRemovalEnabled,
      blurDetectionEnabled: blurDetectionEnabled ?? this.blurDetectionEnabled,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      hidePreviewForLockedFiles: hidePreviewForLockedFiles ?? this.hidePreviewForLockedFiles,
      defaultScanMode: defaultScanMode ?? this.defaultScanMode,
      defaultEnhancement: defaultEnhancement ?? this.defaultEnhancement,
      defaultExportFormat: defaultExportFormat ?? this.defaultExportFormat,
      pdfQuality: pdfQuality ?? this.pdfQuality,
      imageQuality: imageQuality ?? this.imageQuality,
      autoSaveEnabled: autoSaveEnabled ?? this.autoSaveEnabled,
      autoUploadEnabled: autoUploadEnabled ?? this.autoUploadEnabled,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      defaultWatermarkConfig: defaultWatermarkConfig ?? this.defaultWatermarkConfig,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode,
      'languageCode': languageCode,
      'biometricEnabled': biometricEnabled,
      'pinEnabled': pinEnabled,
      'pinHash': pinHash,
      'autoLockTimeoutMinutes': autoLockTimeoutMinutes,
      'aiProvider': aiProvider,
      'defaultCameraFlash': defaultCameraFlash,
      'autoEdgeDetection': autoEdgeDetection,
      'shadowRemovalEnabled': shadowRemovalEnabled,
      'blurDetectionEnabled': blurDetectionEnabled,
      'autoSyncEnabled': autoSyncEnabled,
      'hidePreviewForLockedFiles': hidePreviewForLockedFiles,
      'defaultScanMode': defaultScanMode,
      'defaultEnhancement': defaultEnhancement,
      'defaultExportFormat': defaultExportFormat,
      'pdfQuality': pdfQuality,
      'imageQuality': imageQuality,
      'autoSaveEnabled': autoSaveEnabled,
      'autoUploadEnabled': autoUploadEnabled,
      'autoBackupEnabled': autoBackupEnabled,
      'hasSeenOnboarding': hasSeenOnboarding,
      'defaultWatermarkConfig': defaultWatermarkConfig.toMap(),
    };
  }

  factory AppSettings.fromMap(Map<dynamic, dynamic> map) {
    return AppSettings(
      themeMode: map['themeMode'] as String? ?? 'system',
      languageCode: map['languageCode'] as String? ?? 'en',
      biometricEnabled: map['biometricEnabled'] as bool? ?? false,
      pinEnabled: map['pinEnabled'] as bool? ?? false,
      pinHash: map['pinHash'] as String?,
      autoLockTimeoutMinutes: map['autoLockTimeoutMinutes'] as int? ?? 5,
      aiProvider: map['aiProvider'] as String? ?? 'gemini',
      defaultCameraFlash: map['defaultCameraFlash'] as bool? ?? false,
      autoEdgeDetection: map['autoEdgeDetection'] as bool? ?? true,
      shadowRemovalEnabled: map['shadowRemovalEnabled'] as bool? ?? true,
      blurDetectionEnabled: map['blurDetectionEnabled'] as bool? ?? true,
      autoSyncEnabled: map['autoSyncEnabled'] as bool? ?? true,
      hidePreviewForLockedFiles: map['hidePreviewForLockedFiles'] as bool? ?? true,
      defaultScanMode: map['defaultScanMode'] as String? ?? 'document',
      defaultEnhancement: map['defaultEnhancement'] as String? ?? 'autoEnhanced',
      defaultExportFormat: map['defaultExportFormat'] as String? ?? 'pdf',
      pdfQuality: map['pdfQuality'] as String? ?? 'high',
      imageQuality: map['imageQuality'] as String? ?? 'high',
      autoSaveEnabled: map['autoSaveEnabled'] as bool? ?? true,
      autoUploadEnabled: map['autoUploadEnabled'] as bool? ?? true,
      autoBackupEnabled: map['autoBackupEnabled'] as bool? ?? true,
      hasSeenOnboarding: map['hasSeenOnboarding'] as bool? ?? false,
      defaultWatermarkConfig: map['defaultWatermarkConfig'] != null
          ? WatermarkConfig.fromMap(map['defaultWatermarkConfig'] as Map)
          : const WatermarkConfig(),
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        languageCode,
        biometricEnabled,
        pinEnabled,
        pinHash,
        autoLockTimeoutMinutes,
        aiProvider,
        defaultCameraFlash,
        autoEdgeDetection,
        shadowRemovalEnabled,
        blurDetectionEnabled,
        autoSyncEnabled,
        hidePreviewForLockedFiles,
        defaultScanMode,
        defaultEnhancement,
        defaultExportFormat,
        pdfQuality,
        imageQuality,
        autoSaveEnabled,
        autoUploadEnabled,
        autoBackupEnabled,
        hasSeenOnboarding,
        defaultWatermarkConfig,
      ];
}
