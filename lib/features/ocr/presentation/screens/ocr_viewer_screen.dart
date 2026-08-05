import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../widgets/ai_badge.dart';
import '../controllers/ocr_controller.dart';

enum OCRViewTab { text, search, translate }

class OCRViewerScreen extends ConsumerStatefulWidget {
  final String documentId;
  const OCRViewerScreen({super.key, required this.documentId});

  @override
  ConsumerState<OCRViewerScreen> createState() => _OCRViewerScreenState();
}

class _OCRViewerScreenState extends ConsumerState<OCRViewerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _editController = TextEditingController();
  OCRViewTab _selectedTab = OCRViewTab.text;

  @override
  void dispose() {
    _searchController.dispose();
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ocrProvider(widget.documentId));
    final controller = ref.read(ocrProvider(widget.documentId).notifier);

    if (state.isEditing && _editController.text != state.editableText) {
      _editController.text = state.editableText;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: CustomAppBar(
        title: state.isEditing ? 'Edit Text' : (state.document?.title ?? 'OCR Result'),
        subtitle: state.isEditing ? 'Manual correction' : 'ML Kit • AI Enhanced',
        actions: [
          if (state.isEditing) ...[
            GestureDetector(onTap: () => controller.toggleEditMode(), child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white, size: 18))),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(gradient: AppColors.scannerGradient, borderRadius: BorderRadius.circular(20)),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                onPressed: state.isSaving ? null : () async { controller.updateEditableText(_editController.text); await controller.saveEditedText(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved!'), backgroundColor: Color(0xFF151D3F))); },
                icon: state.isSaving ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                label: Text(state.isSaving ? 'Saving...' : 'Save', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
      body: state.isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryDark))
          : state.errorMessage != null
              ? Center(child: Text(state.errorMessage!, style: TextStyle(color: AppColors.textSecondaryDark)))
              : Stack(
                  children: [
                    Positioned(top: -40, right: -40, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.neonCyan.withOpacity(0.10), Colors.transparent])))),
                    Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.06))),
                          child: Row(children: [
                            Expanded(child: _TabBtn(label: 'Text', selected: _selectedTab == OCRViewTab.text, onTap: () => setState(() => _selectedTab = OCRViewTab.text))),
                            Expanded(child: _TabBtn(label: 'Search', selected: _selectedTab == OCRViewTab.search, onTap: () => setState(() => _selectedTab = OCRViewTab.search))),
                            Expanded(child: _TabBtn(label: 'Translate', selected: _selectedTab == OCRViewTab.translate, onTap: () { setState(() => _selectedTab = OCRViewTab.translate); _showTranslateModal(context, controller); })),
                          ]),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_selectedTab == OCRViewTab.search)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(color: const Color(0xFF151D3F), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.08))),
                                    child: TextField(
                                      controller: _searchController,
                                      onChanged: controller.setSearchQuery,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(hintText: 'Search within recognized text...', hintStyle: TextStyle(color: AppColors.textSecondaryDark), prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondaryDark), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                                    ),
                                  ),
                                if (state.ocrResult != null) ...[
                                  if (state.ocrResult!.extractedEmails.isNotEmpty) _EntityCard(title: 'Emails Found', icon: Icons.email_rounded, items: state.ocrResult!.extractedEmails, gradient: AppColors.emeraldGradient),
                                  if (state.ocrResult!.extractedPhones.isNotEmpty) _EntityCard(title: 'Phone Numbers', icon: Icons.phone_rounded, items: state.ocrResult!.extractedPhones, gradient: AppColors.goldGradient),
                                  if (state.ocrResult!.extractedDates.isNotEmpty) _EntityCard(title: 'Dates', icon: Icons.calendar_today_rounded, items: state.ocrResult!.extractedDates, gradient: AppColors.scannerGradient),
                                ],
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF151D3F), Color(0xFF121A36)]), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.07)), boxShadow: AppSpacing.cardShadowDark),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const AIBadge(label: 'ML Kit OCR • AI'), Text('Confidence: ${((state.ocrResult?.confidence ?? 0.96) * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark, fontWeight: FontWeight.w600))]),
                                      const SizedBox(height: 14),
                                      Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white.withOpacity(0.08), Colors.transparent]))),
                                      const SizedBox(height: 14),
                                      if (state.isTranslating)
                                        Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Column(children: [CircularProgressIndicator(color: AppColors.primaryDark), const SizedBox(height: 12), GestureDetector(onTap: () => _showTranslateModal(context, controller), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(gradient: AppColors.scannerGradient, borderRadius: BorderRadius.circular(20)), child: const Text('Select Language', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))))])))
                                      else if (state.isEditing)
                                        TextField(controller: _editController, maxLines: null, style: const TextStyle(color: Color(0xFFE0E6FF), fontSize: 14, height: 1.6), decoration: const InputDecoration(border: InputBorder.none), onChanged: (val) => controller.updateEditableText(val))
                                      else
                                        SelectableText((_selectedTab == OCRViewTab.translate && state.translatedText != null) ? state.translatedText! : state.ocrResult?.text ?? 'No OCR text extracted.', style: const TextStyle(color: Color(0xFFE0E6FF), fontSize: 14, height: 1.7)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SafeArea(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            decoration: BoxDecoration(color: const Color(0xFF151D3F), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withOpacity(0.08)), boxShadow: AppSpacing.cardShadowDark),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _BottomAction(icon: Icons.copy_rounded, label: 'Copy', onTap: () async { await controller.copyTextToClipboard(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!'), backgroundColor: Color(0xFF151D3F))); }),
                                _BottomAction(icon: Icons.share_rounded, label: 'Share', onTap: () { final text = state.translatedText ?? state.ocrResult?.text ?? ''; if (text.isNotEmpty) Share.share(text, subject: state.document?.title); }),
                                _BottomAction(icon: Icons.edit_note_rounded, label: 'Edit', onTap: () => controller.toggleEditMode()),
                                _BottomAction(icon: Icons.download_rounded, label: 'Export', onTap: () => _showExportModal(context)),
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

  void _showTranslateModal(BuildContext context, OCRController controller) {
    final languages = ['Spanish', 'French', 'German', 'Chinese', 'Arabic', 'Japanese', 'Urdu', 'Hindi'];
    showModalBottomSheet(context: context, backgroundColor: AppColors.surfaceDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)), side: BorderSide(color: Colors.white.withOpacity(0.06))), builder: (ctx) => SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Translate to', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)), const SizedBox(height: 16), Wrap(spacing: 10, runSpacing: 10, children: languages.map((lang) => GestureDetector(onTap: () { Navigator.pop(ctx); controller.translateText(lang); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.08))), child: Text(lang, style: const TextStyle(color: Colors.white, fontSize: 13))))).toList())]))));
  }

  void _showExportModal(BuildContext context) {
    showModalBottomSheet(context: context, backgroundColor: AppColors.surfaceDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl))), builder: (ctx) => SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Export Options', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)), const SizedBox(height: 16), _ExportTile(icon: Icons.description_rounded, title: 'Export TXT', subtitle: 'Plain text format', gradient: AppColors.scannerGradient), _ExportTile(icon: Icons.article_rounded, title: 'Export DOCX', subtitle: 'Word document', gradient: AppColors.purpleGradient), _ExportTile(icon: Icons.picture_as_pdf_rounded, title: 'Searchable PDF', subtitle: 'PDF with embedded text', gradient: AppColors.goldGradient)]))));
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(gradient: selected ? AppColors.scannerGradient : null, color: selected ? null : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: selected ? [BoxShadow(color: AppColors.primaryDark.withOpacity(0.25), blurRadius: 12)] : null),
        child: Center(child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondaryDark, fontWeight: selected ? FontWeight.w800 : FontWeight.w500, fontSize: 12.5))),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _BottomAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [Container(width: 38, height: 38, decoration: BoxDecoration(gradient: AppColors.scannerGradient, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 18)), const SizedBox(height: 4), Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600))]),
    );
  }
}

class _EntityCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final Gradient gradient;
  const _EntityCard({required this.title, required this.icon, required this.items, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.06))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.white, size: 16)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: gradient.colors.first, fontWeight: FontWeight.w700, fontSize: 12)), const SizedBox(height: 6), Wrap(spacing: 6, runSpacing: 6, children: items.map((e) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(20)), child: Text(e, style: const TextStyle(color: Colors.white, fontSize: 11)))).toList())])),
      ]),
    );
  }
}

class _ExportTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Gradient gradient;
  const _ExportTile({required this.icon, required this.title, required this.subtitle, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.06))),
      child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.white, size: 20)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)), Text(subtitle, style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11.5))])), Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textSecondaryDark)]),
    );
  }
}
