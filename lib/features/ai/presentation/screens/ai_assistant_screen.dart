import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiProvider(widget.documentId));
    final controller = ref.read(aiProvider(widget.documentId).notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: CustomAppBar(
        title: state.document?.title ?? 'AI Studio',
        subtitle: 'GPT-4o • Gemini • Offline OCR',
        actions: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.08))),
            child: IconButton(icon: const Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.white70), onPressed: () => controller.runAnalysis('summary')),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(top: -80, left: -40, child: Container(width: 260, height: 260, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.neonPurple.withOpacity(0.14), Colors.transparent])))),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('ScanX AI Intelligence', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                      const SizedBox(height: 2),
                      Text('Ask, summarize, translate, audit', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12.5)),
                    ]),
                    const Spacer(),
                    const AIBadge(label: 'GPT-4o + Gemini'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.90,
                  children: [
                    _ActionCard(title: 'Summary', icon: Icons.summarize_rounded, gradient: AppColors.scannerGradient, onTap: () => controller.runAnalysis('summary')),
                    _ActionCard(title: 'Chat PDF', icon: Icons.chat_bubble_rounded, gradient: AppColors.purpleGradient, onTap: () => controller.sendChatMessage('Provide comprehensive breakdown of clauses')),
                    _ActionCard(title: 'Translate', icon: Icons.translate_rounded, gradient: AppColors.cyanGradient, onTap: () => controller.runAnalysis('translate')),
                    _ActionCard(title: 'Explain', icon: Icons.lightbulb_rounded, gradient: AppColors.primaryGradient, onTap: () => controller.runAnalysis('explain')),
                    _ActionCard(title: 'Re-write', icon: Icons.auto_fix_high_rounded, gradient: AppColors.emeraldGradient, onTap: () => controller.runAnalysis('rewrite')),
                    _ActionCard(title: 'Extract', icon: Icons.contact_page_rounded, gradient: AppColors.aiGradient, onTap: () => controller.runAnalysis('business_card')),
                    _ActionCard(title: 'Risk Audit', icon: Icons.security_rounded, gradient: AppColors.goldGradient, onTap: () => controller.runAnalysis('audit_risks')),
                    _ActionCard(title: 'Tasks', icon: Icons.checklist_rounded, gradient: AppColors.emeraldGradient, onTap: () => controller.runAnalysis('action_items')),
                  ],
                ),
              ),
              if (state.analysisResult?.summary != null || state.analysisResult?.explanation != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1A2348), Color(0xFF151D3F)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: AppColors.neonPurple.withOpacity(0.18)),
                    boxShadow: [BoxShadow(color: AppColors.neonPurple.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const AIBadge(label: 'AI Result', compact: false),
                        const Spacer(),
                        if (state.suggestedFolderName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.success.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.success.withOpacity(0.25))),
                            child: Text('Folder: ${state.suggestedFolderName}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success)),
                          ),
                      ]),
                      const SizedBox(height: 12),
                      Text(state.analysisResult?.summary ?? state.analysisResult?.explanation ?? '', style: const TextStyle(color: Color(0xFFE0E6FF), fontSize: 13.5, height: 1.6)),
                      if (state.autoTags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: state.autoTags.map((tag) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.primaryDark.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primaryDark.withOpacity(0.25))), child: Text(tag, style: const TextStyle(fontSize: 10, color: Color(0xFF9BA3FF), fontWeight: FontWeight.w700)))).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              Expanded(
                child: state.chatMessages.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        children: [
                          Text('Recent Conversations', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          _ConvRow(title: 'Summarize Invoice.pdf', time: 'Today, 10:30 AM', icon: Icons.article_rounded, gradient: AppColors.scannerGradient),
                          _ConvRow(title: 'Explain Contract Terms', time: 'Yesterday, 4:20 PM', icon: Icons.lightbulb_rounded, gradient: AppColors.goldGradient),
                          _ConvRow(title: 'Translate Document', time: '12 May, 9:15 AM', icon: Icons.translate_rounded, gradient: AppColors.cyanGradient),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: state.chatMessages.length,
                        itemBuilder: (context, index) {
                          final msg = state.chatMessages[index];
                          final isUser = msg['role'] == 'user';
                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(14),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.80),
                              decoration: BoxDecoration(
                                gradient: isUser ? AppColors.scannerGradient : const LinearGradient(colors: [Color(0xFF151D3F), Color(0xFF121A36)]),
                                borderRadius: BorderRadius.circular(18).copyWith(bottomRight: isUser ? const Radius.circular(4) : null, bottomLeft: !isUser ? const Radius.circular(4) : null),
                                border: Border.all(color: isUser ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.08)),
                                boxShadow: isUser ? [BoxShadow(color: AppColors.primaryDark.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))] : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isUser) ...[const AIBadge(label: 'ScanX AI'), const SizedBox(height: 8)],
                                  Text(msg['content'] ?? '', style: TextStyle(color: isUser ? Colors.white : const Color(0xFFE0E6FF), fontSize: 13.5, height: 1.5)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (state.isAnalyzing) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark))),
              SafeArea(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151D3F),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    boxShadow: AppSpacing.cardShadowDark,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.08))),
                        child: const Icon(Icons.add_rounded, color: Colors.white70, size: 20),
                      ),
                      Expanded(child: TextField(controller: _chatController, onSubmitted: (_) => _sendMessage(), style: const TextStyle(color: Colors.white, fontSize: 14), decoration: InputDecoration(hintText: 'Ask AI about this document...', hintStyle: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 14)))),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(gradient: AppColors.scannerGradient, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.primaryDark.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]),
                          child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;
  const _ActionCard({required this.title, required this.icon, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF151D3F), Color(0xFF121A36)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.white, size: 16)),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _ConvRow extends StatelessWidget {
  final String title, time;
  final IconData icon;
  final Gradient gradient;
  const _ConvRow({required this.title, required this.time, required this.icon, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.white, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)), const SizedBox(height: 2), Text(time, style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11))])),
          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textSecondaryDark),
        ],
      ),
    );
  }
}
