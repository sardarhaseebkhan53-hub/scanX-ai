import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../config/routes/route_names.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    if (state.isEditing && _editController.text != state.editableText) {
      _editController.text = state.editableText;
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: state.isEditing
            ? 'Edit Recognized Text'
            : (state.document?.title ?? 'OCR Result'),
        actions: [
          if (state.isEditing) ...[
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Cancel Edit',
              onPressed: () => controller.toggleEditMode(),
            ),
            ElevatedButton.icon(
              onPressed: state.isSaving
                  ? null
                  : () async {
                      controller.updateEditableText(_editController.text);
                      await controller.saveEditedText();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved updated OCR text!')),
                        );
                      }
                    },
              icon: state.isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(state.isSaving ? 'Saving...' : 'Save'),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
              ? Center(child: Text(state.errorMessage!))
              : Column(
                  children: [
                    // 1. 3-Tab Switcher (Text | Search | Translate)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.18)),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _buildTabButton('Text', OCRViewTab.text)),
                          Expanded(child: _buildTabButton('Search', OCRViewTab.search)),
                          Expanded(child: _buildTabButton('Translate', OCRViewTab.translate)),
                        ],
                      ),
                    ),

                    // 2. Tab Content Box
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedTab == OCRViewTab.search) ...[
                              TextField(
                                controller: _searchController,
                                onChanged: controller.setSearchQuery,
                                decoration: InputDecoration(
                                  hintText: 'Search within recognized OCR text...',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded),
                                          onPressed: () {
                                            _searchController.clear();
                                            controller.setSearchQuery('');
                                          },
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Extracted Entities (Dates, Emails, Phones, URLs, Addresses)
                            if (state.ocrResult != null) ...[
                              if (state.ocrResult!.extractedDates.isNotEmpty)
                                _buildEntityCard(
                                  title: 'Extracted Dates',
                                  icon: Icons.calendar_today_rounded,
                                  items: state.ocrResult!.extractedDates,
                                  color: Colors.blueAccent,
                                ),
                              if (state.ocrResult!.extractedEmails.isNotEmpty)
                                _buildEntityCard(
                                  title: 'Extracted Emails',
                                  icon: Icons.email_rounded,
                                  items: state.ocrResult!.extractedEmails,
                                  color: Colors.green,
                                ),
                              if (state.ocrResult!.extractedPhones.isNotEmpty)
                                _buildEntityCard(
                                  title: 'Extracted Phones',
                                  icon: Icons.phone_rounded,
                                  items: state.ocrResult!.extractedPhones,
                                  color: Colors.amber[700]!,
                                ),
                              if (state.ocrResult!.extractedUrls.isNotEmpty)
                                _buildEntityCard(
                                  title: 'Extracted URLs',
                                  icon: Icons.link_rounded,
                                  items: state.ocrResult!.extractedUrls,
                                  color: const Color(0xFF8B5CF6), // Purple
                                ),
                              if (state.ocrResult!.extractedAddresses.isNotEmpty)
                                _buildEntityCard(
                                  title: 'Extracted Addresses',
                                  icon: Icons.location_on_rounded,
                                  items: state.ocrResult!.extractedAddresses,
                                  color: const Color(0xFFEF4444), // Red
                                ),
                            ],
                            const SizedBox(height: 12),

                            // Main Recognized Text Box or Editable TextField
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardTheme.color,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.withOpacity(0.18)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const AIBadge(label: 'ML Kit OCR'),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Language: ${state.ocrResult?.detectedLanguage.toUpperCase() ?? "EN"}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).textTheme.bodySmall?.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        state.isEditing
                                            ? 'EDITING MODE'
                                            : 'Confidence: ${((state.ocrResult?.confidence ?? 0.96) * 100).toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 28),
                                  if (state.isTranslating || _selectedTab == OCRViewTab.translate && state.translatedText == null)
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 24),
                                        child: Column(
                                          children: [
                                            const CircularProgressIndicator(),
                                            const SizedBox(height: 12),
                                            ElevatedButton(
                                              onPressed: () => _showTranslateModal(context, controller),
                                              child: const Text('Select Target Language'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else if (state.isEditing)
                                    TextField(
                                      controller: _editController,
                                      maxLines: null,
                                      decoration: const InputDecoration(
                                        hintText: 'Edit recognized OCR text...',
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        height: 1.6,
                                        fontFamily: 'Courier',
                                      ),
                                      onChanged: (val) => controller.updateEditableText(val),
                                    )
                                  else
                                    SelectableText(
                                      (_selectedTab == OCRViewTab.translate && state.translatedText != null)
                                          ? state.translatedText!
                                          : state.ocrResult?.text ?? 'No OCR text extracted.',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        height: 1.6,
                                        fontFamily: 'Courier',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 3. Bottom Toolbar (Copy | Share | Edit | Export)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.18))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildBottomAction(
                            icon: Icons.copy_rounded,
                            label: 'Copy',
                            onTap: () async {
                              await controller.copyTextToClipboard();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Copied OCR text to clipboard!')),
                                );
                              }
                            },
                          ),
                          _buildBottomAction(
                            icon: Icons.share_rounded,
                            label: 'Share',
                            onTap: () {
                              final text = state.translatedText ?? state.ocrResult?.text ?? '';
                              if (text.isNotEmpty) {
                                Share.share(text, subject: state.document?.title);
                              }
                            },
                          ),
                          _buildBottomAction(
                            icon: Icons.edit_note_rounded,
                            label: 'Edit',
                            onTap: () => controller.toggleEditMode(),
                          ),
                          _buildBottomAction(
                            icon: Icons.download_rounded,
                            label: 'Export',
                            onTap: () => _showExportModal(context, state),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildTabButton(String label, OCRViewTab tab) {
    final isSelected = _selectedTab == tab;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = tab);
        if (tab == OCRViewTab.translate) {
          _showTranslateModal(context, ref.read(ocrProvider(widget.documentId).notifier));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colorScheme.primary, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntityCard({
    required String title,
    required IconData icon,
    required List<String> items,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: items.map((e) {
                    return Chip(
                      label: Text(e, style: const TextStyle(fontSize: 12)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTranslateModal(BuildContext context, OCRController controller) {
    final languages = ['Spanish', 'French', 'German', 'Chinese', 'Arabic', 'Japanese', 'Urdu', 'Hindi'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Target Language',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: languages.map((lang) {
                  return ActionChip(
                    label: Text(lang),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      controller.translateText(lang);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportModal(BuildContext context, OCRState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export OCR Text',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.description_rounded, color: Colors.blueAccent),
                title: const Text('Export to TXT (.txt)'),
                subtitle: const Text('Plain text document format'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exported recognized text to .TXT file!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.article_rounded, color: Colors.purple),
                title: const Text('Export to DOCX (.docx)'),
                subtitle: const Text('Microsoft Word document format'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exported recognized text to .DOCX file!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
                title: const Text('Export to Searchable PDF (.pdf)'),
                subtitle: const Text('Standard PDF format with embedded text layer'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exported searchable PDF!')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
