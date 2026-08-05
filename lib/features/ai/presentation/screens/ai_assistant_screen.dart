import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/monetization/ad_service.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../widgets/ai_badge.dart';
import '../controllers/ai_controller.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  final String? documentId;

  const AIAssistantScreen({super.key, this.documentId});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final TextEditingController _chatController = TextEditingController();

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    ref.read(aiProvider(widget.documentId).notifier).sendChatMessage(text);
    _chatController.clear();
  }

  void _showRewardedAdForFreeAI() {
    AdService().showRewardedAd(
      onEarnedReward: (reward) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🎉 Earned ${reward.amount} Free AI Analysis Pass! You can now run unlimited queries.',
              ),
            ),
          );
        }
      },
      onAdClosed: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiProvider(widget.documentId));
    final controller = ref.read(aiProvider(widget.documentId).notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: state.document?.title ?? 'AI Assistant',
        actions: [
          IconButton(
            icon: const Icon(Icons.card_giftcard_rounded, color: Colors.orange),
            tooltip: 'Earn 1 Free AI Pass (Watch Ad)',
            onPressed: _showRewardedAdForFreeAI,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Regenerate Summary',
            onPressed: () => controller.runAnalysis('summary'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 1. Greeting Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Good Morning, John 🖐️',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'How can I help you today?',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const AIBadge(label: 'GPT-4o / Gemini'),
                    ],
                  ),
                ),

                // 2. 8 Premium Colorful Action Grid Cards (4 columns x 2 rows or 3 columns)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.95,
                    children: [
                      _buildActionGridCard(
                        title: 'Summarize',
                        subtitle: 'Get summary',
                        icon: Icons.article_outlined,
                        color: const Color(0xFF06B6D4), // Cyan
                        onTap: () => controller.runAnalysis('summary'),
                      ),
                      _buildActionGridCard(
                        title: 'Chat PDF',
                        subtitle: 'Ask anything',
                        icon: Icons.chat_bubble_outline_rounded,
                        color: const Color(0xFF8B5CF6), // Purple
                        onTap: () {
                          controller.sendChatMessage('Provide a comprehensive breakdown of all clauses in this document.');
                        },
                      ),
                      _buildActionGridCard(
                        title: 'Translate',
                        subtitle: 'Translate text',
                        icon: Icons.translate_rounded,
                        color: const Color(0xFFEF4444), // Red/Orange
                        onTap: () => controller.runAnalysis('translate'),
                      ),
                      _buildActionGridCard(
                        title: 'Explain',
                        subtitle: 'Explain terms',
                        icon: Icons.lightbulb_outline_rounded,
                        color: const Color(0xFF3B82F6), // Blue
                        onTap: () => controller.runAnalysis('explain'),
                      ),
                      _buildActionGridCard(
                        title: 'Re-write',
                        subtitle: 'Polish writing',
                        icon: Icons.auto_fix_high_rounded,
                        color: const Color(0xFF10B981), // Green
                        onTap: () => controller.runAnalysis('rewrite'),
                      ),
                      _buildActionGridCard(
                        title: 'Extract Card',
                        subtitle: 'Contact info',
                        icon: Icons.table_chart_outlined,
                        color: const Color(0xFFEC4899), // Pink
                        onTap: () => controller.runAnalysis('business_card'),
                      ),
                      _buildActionGridCard(
                        title: 'Risk Audit',
                        subtitle: 'Check liability',
                        icon: Icons.security_rounded,
                        color: const Color(0xFFF59E0B), // Amber
                        onTap: () => controller.runAnalysis('audit_risks'),
                      ),
                      _buildActionGridCard(
                        title: 'Tasks',
                        subtitle: 'Action items',
                        icon: Icons.checklist_rounded,
                        color: const Color(0xFF10B981), // Green
                        onTap: () => controller.runAnalysis('action_items'),
                      ),
                    ],
                  ),
                ),

                // 3. Main Analysis Output Card & Semantic Keyword Tags
                if (state.analysisResult?.summary != null ||
                    state.analysisResult?.explanation != null ||
                    state.analysisResult?.rewrittenText != null ||
                    (state.analysisResult?.items.isNotEmpty == true &&
                        state.analysisResult?.vendorName == 'Sardar Haseeb Technologies'))
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AIBadge(
                              label: state.analysisResult?.rewrittenText != null
                                  ? 'Executive Rewrite'
                                  : (state.analysisResult?.items.isNotEmpty == true &&
                                          state.analysisResult?.vendorName ==
                                              'Sardar Haseeb Technologies')
                                      ? 'Extracted Contact Card'
                                      : 'AI Analysis Result',
                            ),
                            if (state.suggestedFolderName != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Folder: ${state.suggestedFolderName}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (state.analysisResult?.items.isNotEmpty == true &&
                            state.analysisResult?.vendorName == 'Sardar Haseeb Technologies') ...[
                          for (final item in state.analysisResult!.items)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Text(
                                    '${item['description']}: ',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item['value']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            )
                        ] else
                          Text(
                            state.analysisResult?.summary ??
                                state.analysisResult?.explanation ??
                                state.analysisResult?.rewrittenText ??
                                '',
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        if (state.autoTags.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: state.autoTags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                // 4. "Recent Conversations" Section & Chat Messages ListView
                Expanded(
                  child: state.chatMessages.isEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                              child: Text(
                                'Recent Conversations',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _buildConversationRow('Summarize Invoice.pdf', 'Today, 10:30 AM', Icons.article_outlined),
                            _buildConversationRow('Explain Contract Terms', 'Yesterday, 4:20 PM', Icons.lightbulb_outline_rounded),
                            _buildConversationRow('Translate Document', '12 May, 9:15 AM', Icons.translate_rounded),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.chatMessages.length,
                          itemBuilder: (context, index) {
                            final msg = state.chatMessages[index];
                            final isUser = msg['role'] == 'user';
                            return Align(
                              alignment:
                                  isUser ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                                ),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? colorScheme.primary
                                      : Theme.of(context).cardTheme.color,
                                  borderRadius: BorderRadius.circular(16).copyWith(
                                    bottomRight: isUser ? const Radius.circular(0) : null,
                                    bottomLeft: !isUser ? const Radius.circular(0) : null,
                                  ),
                                  border: isUser
                                      ? null
                                      : Border.all(color: Colors.grey.withOpacity(0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isUser) ...[
                                      const AIBadge(label: 'ScanX AI'),
                                      const SizedBox(height: 6),
                                    ],
                                    Text(
                                      msg['content'] ?? '',
                                      style: TextStyle(
                                        color: isUser ? Colors.white : null,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                if (state.isAnalyzing)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(),
                  ),

                // 5. Bottom Chat Bar
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: const InputDecoration(
                              hintText: 'Ask AI about this document...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _sendMessage,
                          icon: Icon(Icons.send_rounded, color: colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActionGridCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withOpacity(0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationRow(String title, String time, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        time,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded conversation: "$title"')),
        );
      },
    );
  }
}
