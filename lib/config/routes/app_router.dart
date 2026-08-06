import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/ai/presentation/screens/ai_assistant_screen.dart';
import '../../features/ai/presentation/screens/receipt_analysis_screen.dart';
import '../../features/cloud/presentation/screens/cloud_sync_screen.dart';
import '../../features/home/presentation/screens/main_shell.dart';
import '../../features/ocr/presentation/screens/ocr_viewer_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/pdf/presentation/screens/pdf_editor_screen.dart';
import '../../features/pdf/presentation/screens/pdf_tools_screen.dart';
import '../../features/qr/presentation/screens/qr_dashboard_screen.dart';
import '../../features/qr/presentation/screens/qr_generator_screen.dart';
import '../../features/qr/presentation/screens/qr_scanner_screen.dart';
import '../../features/home/presentation/screens/notifications_screen.dart';
import '../../features/qr/presentation/screens/wifi_qr_studio_screen.dart';
import '../../features/scanner/presentation/screens/crop_screen.dart';
import '../../features/scanner/presentation/screens/scan_preview_screen.dart';
import '../../features/scanner/presentation/screens/scanner_screen.dart';
import '../../features/security/presentation/screens/app_lock_screen.dart';
import '../../features/security/presentation/screens/hidden_vault_screen.dart';
import '../../features/security/presentation/screens/security_settings_screen.dart';
import '../../features/settings/presentation/screens/legal_policy_screen.dart';
import '../../features/settings/presentation/screens/premium_paywall_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import 'route_names.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.home,
    routes: [
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: RouteNames.scanner,
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: RouteNames.crop,
        builder: (context, state) {
          final imagePath = state.extra as String? ?? '';
          return CropScreen(imagePath: imagePath);
        },
      ),
      GoRoute(
        path: RouteNames.scanPreview,
        builder: (context, state) {
          final imagePaths = state.extra as List<String>? ?? [];
          return ScanPreviewScreen(imagePaths: imagePaths);
        },
      ),
      GoRoute(
        path: RouteNames.ocrViewer,
        builder: (context, state) {
          final docId = state.extra as String? ?? '';
          return OCRViewerScreen(documentId: docId);
        },
      ),
      GoRoute(
        path: RouteNames.aiAssistant,
        builder: (context, state) {
          final docId = state.extra as String?;
          return AIAssistantScreen(documentId: docId);
        },
      ),
      GoRoute(
        path: RouteNames.receiptAnalysis,
        builder: (context, state) {
          final docId = state.extra as String? ?? '';
          return ReceiptAnalysisScreen(documentId: docId);
        },
      ),
      GoRoute(
        path: RouteNames.pdfEditor,
        builder: (context, state) {
          final docId = state.extra as String? ?? '';
          return PdfEditorScreen(documentId: docId);
        },
      ),
      GoRoute(
        path: RouteNames.pdfTools,
        builder: (context, state) => const PdfToolsScreen(),
      ),
      GoRoute(
        path: RouteNames.qrDashboard,
        builder: (context, state) => const QrDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.wifiQrStudio,
        builder: (context, state) => const WifiQrStudioScreen(),
      ),
      GoRoute(
        path: RouteNames.qrGenerator,
        builder: (context, state) => const QrGeneratorScreen(),
      ),
      GoRoute(
        path: RouteNames.qrScanner,
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: RouteNames.cloudSync,
        builder: (context, state) => const CloudSyncScreen(),
      ),
      GoRoute(
        path: RouteNames.securitySettings,
        builder: (context, state) => const SecuritySettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.appLock,
        builder: (context, state) => const AppLockScreen(),
      ),
      GoRoute(
        path: RouteNames.hiddenVault,
        builder: (context, state) => const HiddenVaultScreen(),
      ),
      GoRoute(
        path: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.premiumPaywall,
        builder: (context, state) => const PremiumPaywallScreen(),
      ),
      GoRoute(
        path: RouteNames.legalPolicy,
        builder: (context, state) {
          final type = state.extra as LegalPolicyType? ?? LegalPolicyType.privacyPolicy;
          return LegalPolicyScreen(policyType: type);
        },
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
}
