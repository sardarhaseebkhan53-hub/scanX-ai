import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../../../shared/widgets/document_picker_sheet.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

/// AI Tools hub — every AI capability from the product reference:
/// Chat with Documents, Document Summary, OCR Recognition, Receipt & Invoice
/// AI, Rewrite Assistant and Business Card AI, plus the pluggable engine status.
class AiToolsScreen extends ConsumerWidget {
  const AiToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final engine = settings.aiProvider == 'openai'
        ? 'OpenAI GPT-4o'
        : (settings.aiProvider == 'device' ? 'On-Device AI' : 'Google Gemini');

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 160 + MediaQuery.of(context).padding.bottom),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Tools', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.6)),
                const SizedBox(height: 2),
                Text('Advanced intelligence for your documents', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11.5)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF151032), Color(0xFF0D1226)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.neonPurple.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(gradient: AppColors.aiGradient, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.memory_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pluggable AI Engine', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800)),
                        Text('Active: $engine • On-device fallback ready', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(RouteNames.settings),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withOpacity(0.1))),
                      child: Text('Configure', style: TextStyle(color: AppColors.neonCyan, fontSize: 10.5, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ToolCard(
              icon: Icons.chat_bubble_rounded,
              gradient: AppColors.purpleGradient,
              title: 'AI Chat with Documents',
              subtitle: 'Ask anything — get instant answers & explanations',
              onTap: () => context.push(RouteNames.aiAssistant),
            ),
            _ToolCard(
              icon: Icons.summarize_rounded,
              gradient: AppColors.aiGradient,
              title: 'AI Document Summary',
              subtitle: 'Key insights & important points in seconds',
              onTap: () async {
                final doc = await DocumentPickerSheet.show(context, title: 'Summarize a Document');
                if (doc != null && context.mounted) context.push(RouteNames.aiAssistant, extra: doc.id);
              },
            ),
            _ToolCard(
              icon: Icons.text_fields_rounded,
              gradient: AppColors.cyanGradient,
              title: 'OCR Text Recognition',
              subtitle: '99% accuracy • multiple languages • editable text',
              onTap: () async {
                final doc = await DocumentPickerSheet.show(context, title: 'Extract Text (OCR)');
                if (doc != null && context.mounted) context.push(RouteNames.ocrViewer, extra: doc.id);
              },
            ),
            _ToolCard(
              icon: Icons.receipt_long_rounded,
              gradient: AppColors.emeraldGradient,
              title: 'Receipt & Invoice AI',
              subtitle: 'Structured tables with totals, tax & line items',
              onTap: () async {
                final doc = await DocumentPickerSheet.show(context, title: 'Analyze a Receipt / Invoice');
                if (doc != null && context.mounted) context.push(RouteNames.receiptAnalysis, extra: doc.id);
              },
            ),
            _ToolCard(
              icon: Icons.edit_note_rounded,
              gradient: AppColors.scannerGradient,
              title: 'Rewrite Assistant',
              subtitle: 'Polish any text into professional business English',
              onTap: () => context.push(RouteNames.aiAssistant),
            ),
            _ToolCard(
              icon: Icons.badge_rounded,
              gradient: AppColors.goldGradient,
              title: 'Business Card AI',
              subtitle: 'Parse contacts into structured, savable fields',
              onTap: () => context.push(RouteNames.aiAssistant),
            ),
            const SizedBox(height: 20),
            Center(child: ScanXWordmark(fontSize: 16, showTagline: true)),
          ],
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ToolCard({required this.icon, required this.gradient, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF10152B),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11.5, height: 1.35)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textTertiaryDark, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
