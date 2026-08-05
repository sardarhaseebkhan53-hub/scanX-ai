class AppConstants {
  static const String appName = 'ScanX AI';
  static const String appVersion = '1.0.0';
  static const String googlePlayBundleId = 'com.scanxai.enterprise.scanner';

  static const String developerName = 'Developed by Sardar Haseeb';
  static const String copyrightText = '© Sardar Haseeb. All Rights Reserved.';
  static const String companyName = 'Sardar Haseeb Technologies';
  static const String websiteUrl = 'https://sardarhaseeb.com';
  static const String supportEmail = 'support@sardarhaseeb.com';

  // Hive Boxes
  static const String hiveDocumentBox = 'documents_box_v1';
  static const String hiveFolderBox = 'folders_box_v1';
  static const String hiveSettingsBox = 'settings_box_v1';

  // Secure Storage Keys
  static const String securePinHashKey = 'user_pin_hash_key';
  static const String secureBiometricEnabledKey = 'biometrics_enabled_key';
  static const String secureEncryptionKey = 'master_database_encryption_key';
  static const String secureOpenAIKey = 'openai_api_secret_key';
  static const String secureGeminiKey = 'gemini_api_secret_key';

  // AI Default Prompts
  static const String aiSummarizePrompt =
      'Analyze this scanned document text and provide a concise, professional executive summary with bullet points highlighting key deliverables, dates, and amounts.';
  static const String aiReceiptPrompt =
      'Extract receipt metadata into JSON format: merchant name, transaction date, items array with prices, subtotal, tax, and total amount.';
  static const String aiInvoicePrompt =
      'Extract invoice metadata into JSON format: invoice number, vendor, client, dates, total amount due, currency, and line items.';

  // Google Play Billing Product IDs
  static const String monthlySubscriptionId = 'scanx_ai_premium_monthly';
  static const String annualSubscriptionId = 'scanx_ai_premium_annual';
  static const String lifetimePurchaseId = 'scanx_ai_premium_lifetime';

  // AdMob Test Unit IDs (Production ready: replace with Google Play prod IDs)
  static const String adMobBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String adMobInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
}
