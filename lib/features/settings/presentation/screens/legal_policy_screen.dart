import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

enum LegalPolicyType {
  privacyPolicy,
  termsOfService,
  openSourceLicenses,
  permissionExplanations,
}

class LegalPolicyScreen extends StatelessWidget {
  final LegalPolicyType policyType;

  const LegalPolicyScreen({super.key, required this.policyType});

  @override
  Widget build(BuildContext context) {
    String title;
    String content;

    switch (policyType) {
      case LegalPolicyType.privacyPolicy:
        title = 'Privacy Policy';
        content = _privacyPolicyText;
        break;
      case LegalPolicyType.termsOfService:
        title = 'Terms of Service';
        content = _termsOfServiceText;
        break;
      case LegalPolicyType.openSourceLicenses:
        title = 'Open-Source Licenses';
        content = _openSourceIntroText;
        break;
      case LegalPolicyType.permissionExplanations:
        title = 'Permission Explanations';
        content = _permissionExplanationsText;
        break;
    }

    return Scaffold(
      appBar: CustomAppBar(title: title),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${AppConstants.appName} • ${AppConstants.developerName}',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const Divider(height: 32),
            Text(
              content,
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
            if (policyType == LegalPolicyType.openSourceLicenses) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: AppConstants.appName,
                  applicationVersion: AppConstants.appVersion,
                  applicationIcon: const Icon(Icons.workspace_premium_rounded, size: 36),
                ),
                icon: const Icon(Icons.library_books_rounded),
                label: const Text('View Full Flutter Open-Source Licenses'),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              '${AppConstants.copyrightText}\nSupport: ${AppConstants.supportEmail} • Web: ${AppConstants.websiteUrl}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  static const String _privacyPolicyText = '''
1. INTRODUCTION & SCOPE
ScanX AI is committed to protecting your privacy and complying with Google Play Developer Policies (Android 10+ API Level 29+ Scoped Storage). This Privacy Policy explains how your scanned documents, OCR text, and user data are collected, processed, and safeguarded by Sardar Haseeb Technologies.

2. ON-DEVICE PROCESSING & ZERO DATA SELLING
- All camera scans, edge detection, perspective correction, and Google ML Kit OCR text recognition occur locally on your device.
- ScanX AI does NOT sell, rent, or trade your personal data or scanned document text to advertising networks or data brokers.

3. OPTIONAL CLOUD & AI INTEGRATION
- If you choose to enable Firebase Cloud Sync, Google Drive, Dropbox, or OneDrive backups, your documents are transmitted using TLS 1.3 encryption.
- If you invoke optional AI features (Google Gemini API or OpenAI GPT-4o API), selected OCR text is transmitted securely to your selected provider solely for generating executive summaries, translations, or receipt analysis.

4. ANDROID KEYSTORE & LOCAL DATABASE SECURITY
- ScanX AI utilizes Android Keystore and Flutter Secure Storage to cryptographically secure master database encryption keys, vault PIN hashes, and API keys.
- You may permanently delete your data at any time from Settings or by deleting individual documents.
''';

  static const String _termsOfServiceText = '''
1. ACCEPTANCE OF TERMS
By downloading and using ScanX AI, you agree to these Terms of Service. If you do not agree, do not use the application.

2. SUBSCRIPTIONS & GOOGLE PLAY BILLING
- ScanX Premium offers Monthly Subscriptions, Annual Subscriptions, and Lifetime One-Time Purchases processed securely through Google Play Billing.
- Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current billing period in your Google Play Store account settings.
- Purchasing Premium immediately disables all AdMob advertising banners and unlocks unlimited AI document intelligence.

3. LAWFUL USE
- ScanX AI is designed for legitimate business, academic, and personal document management. You agree not to use ScanX AI to scan or distribute fraudulent, illegal, or infringing materials.

4. DISCLAIMER OF WARRANTIES
- ScanX AI is provided "as is" without warranty of any kind. While our ML Kit OCR and AI engines achieve high accuracy, users should verify legal, financial, or tax calculations before official submission.
''';

  static const String _openSourceIntroText = '''
ScanX AI incorporates open-source software packages under the MIT, BSD, and Apache 2.0 licenses. We gratefully acknowledge the contributions of the Flutter community and package authors including:
- Flutter & Dart SDK (BSD 3-Clause)
- Riverpod (MIT)
- Hive & Hive Flutter (Apache 2.0)
- Google ML Kit Text Recognition (Apache 2.0)
- Google Mobile Ads / AdMob (Apache 2.0)
- Flutter Secure Storage (MIT)

Tap below to inspect the complete legal license notices for every transitive library bundled with ScanX AI.
''';

  static const String _permissionExplanationsText = '''
1. CAMERA PERMISSION (`android.permission.CAMERA`)
- Required for capturing live document scans, receipts, ID cards, books, and reading QR & Barcodes in real-time.

2. BIOMETRIC & FINGERPRINT (`android.permission.USE_BIOMETRIC`)
- Required only if you enable Fingerprint or Face Unlock to protect your AES-256 Keystore Vault and Hidden Vault documents.

3. PHOTO GALLERY & MEDIA (`android.permission.READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE`)
- Required only when you explicitly choose "Import from Gallery" to scan an existing image or QR code photo from your device.
- ScanX AI complies with Android 10+ Scoped Storage policies and never requires broad `MANAGE_EXTERNAL_STORAGE` permissions.

4. NETWORK & BILLING (`android.permission.INTERNET`, `com.android.vending.BILLING`)
- Required for optional Firebase cloud backup synchronization, pluggable cloud AI queries (Google Gemini / OpenAI), and Google Play Billing subscription processing.
''';
}
