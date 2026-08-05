import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../widgets/secure_badge.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../home/presentation/widgets/document_card.dart';

class HiddenVaultScreen extends ConsumerWidget {
  const HiddenVaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final homeController = ref.read(homeProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    // Filter documents that have been marked as locked / hidden vault items
    final hiddenDocs = homeState.documents.where((d) => d.isLocked).toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Hidden Vault (${hiddenDocs.length})',
        actions: [
          const Center(child: SecureBadge(isEncrypted: true)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.shield_rounded, color: Color(0xFF8B5CF6)),
            tooltip: 'AES-256 Keystore Active',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All documents in Hidden Vault are encrypted with Android Keystore AES-256.'),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Vault Shield Explanation Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.15),
                  colorScheme.primary.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Documents in Hidden Vault are concealed from recent files and require biometric or PIN verification to access.',
                    style: TextStyle(fontSize: 13, height: 1.45, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // 2. Hidden Vault Document List
          Expanded(
            child: hiddenDocs.isEmpty
                ? EmptyStateWidget(
                    title: 'Hidden Vault is Empty',
                    subtitle:
                        'Tap the 3-dot action menu on any document and choose "Move to Hidden Vault" to conceal private files securely.',
                    icon: Icons.lock_outline_rounded,
                    buttonText: 'Browse My Documents',
                    onButtonPressed: () => context.pop(),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: hiddenDocs.length,
                    itemBuilder: (context, index) {
                      final doc = hiddenDocs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DocumentCard(
                          document: doc,
                          onTap: () => context.push(
                            RouteNames.ocrViewer,
                            extra: doc.id,
                          ),
                          onFavoriteToggle: () => homeController.toggleFavorite(doc),
                          onDelete: () => homeController.deleteDocument(doc.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
