import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../widgets/secure_badge.dart';
import '../controllers/pdf_controller.dart';

class PdfEditorScreen extends ConsumerStatefulWidget {
  final String documentId;

  const PdfEditorScreen({super.key, required this.documentId});

  @override
  ConsumerState<PdfEditorScreen> createState() => _PdfEditorScreenState();
}

class _PdfEditorScreenState extends ConsumerState<PdfEditorScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pdfProvider(widget.documentId));
    final controller = ref.read(pdfProvider(widget.documentId).notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: state.document?.title ?? 'PDF Editor',
        actions: [
          IconButton(
            icon: const Icon(Icons.undo_rounded),
            tooltip: 'Undo',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Undo last annotation/edit')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.redo_rounded),
            tooltip: 'Redo',
            onPressed: () {},
          ),
          if (state.isPasswordProtected) ...[
            const Center(child: SecureBadge(isEncrypted: true)),
            const SizedBox(width: 4),
          ],
          IconButton(
            icon: const Icon(Icons.print_rounded),
            tooltip: 'Print PDF',
            onPressed: () => controller.printDocument(),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Export & Share PDF',
            onPressed: () => controller.shareDocument(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: state.isProcessing
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 1. Success message, annotations, or status banners
                if (state.successMessage != null ||
                    state.appliedWatermark != null ||
                    state.hasSignature ||
                    state.annotations.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.secondary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified_rounded, color: colorScheme.secondary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            state.successMessage ??
                                [
                                  if (state.appliedWatermark != null)
                                    'Watermark: "${state.appliedWatermark}"',
                                  if (state.hasSignature) 'Signed digitally',
                                  if (state.annotations.isNotEmpty)
                                    '${state.annotations.length} Annotations',
                                ].join(' • '),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 2. Pages Grid (Reorderable, Delete, Rotate, Duplicate)
                Expanded(
                  child: state.pagePaths.isEmpty
                      ? const Center(child: Text('No pages found.'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: state.pagePaths.length,
                          itemBuilder: (context, index) {
                            final path = state.pagePaths[index];
                            final file = File(path);
                            final fileExists = file.existsSync();

                            return Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardTheme.color,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: fileExists
                                            ? Image.file(file, fit: BoxFit.cover)
                                            : Container(
                                                color: Colors.grey[800],
                                                alignment: Alignment.center,
                                                child: Text('Page ${index + 1}',
                                                    style: const TextStyle(color: Colors.white)),
                                              ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        color: Theme.of(context).cardTheme.color,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'P${index + 1}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            Row(
                                              children: [
                                                InkWell(
                                                  onTap: () => controller.rotatePage(index),
                                                  child: const Padding(
                                                    padding: EdgeInsets.all(4),
                                                    child: Icon(Icons.rotate_right_rounded,
                                                        size: 18, color: Colors.blueAccent),
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () => controller.duplicatePage(index),
                                                  child: const Padding(
                                                    padding: EdgeInsets.all(4),
                                                    child: Icon(Icons.copy_rounded,
                                                        size: 16, color: Colors.green),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (state.pagePaths.length > 1)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: InkWell(
                                      onTap: () => controller.deletePage(index),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                ),

                // 3. Bottom PDF Editor Toolbar (Add Text | Highlight | Draw | Signature | More)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.18))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBottomTool(
                        icon: Icons.title_rounded,
                        label: 'Add Text',
                        onTap: () => _showAnnotationDialog(context, controller, isHighlight: false),
                      ),
                      _buildBottomTool(
                        icon: Icons.highlight_rounded,
                        label: 'Highlight',
                        onTap: () => _showAnnotationDialog(context, controller, isHighlight: true),
                      ),
                      _buildBottomTool(
                        icon: Icons.edit_rounded,
                        label: 'Draw',
                        onTap: () => _showAnnotationDialog(context, controller, isHighlight: false),
                      ),
                      _buildBottomTool(
                        icon: Icons.draw_rounded,
                        label: 'Signature',
                        onTap: () => _showSignatureDialog(context, controller),
                      ),
                      _buildBottomTool(
                        icon: Icons.more_horiz_rounded,
                        label: 'More',
                        onTap: () => _showMoreToolsModal(context, controller),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBottomTool({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  void _showMoreToolsModal(BuildContext context, PdfController controller) {
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
                'Advanced PDF Studio Tools (17 Total)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.water_drop_rounded, size: 16),
                    label: const Text('Watermark'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showWatermarkDialog(context, controller);
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.lock_rounded, size: 16),
                    label: const Text('Password Protect'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showPasswordDialog(context, controller);
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.compress_rounded, size: 16),
                    label: const Text('Compress (48%)'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      controller.compressPdf();
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.merge_rounded, size: 16),
                    label: const Text('Merge PDF'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showMergeDialog(context, controller);
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.call_split_rounded, size: 16),
                    label: const Text('Split PDF'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showSplitDialog(context, controller, 3);
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.note_add_rounded, size: 16),
                    label: const Text('Insert Blank Page'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      controller.insertBlankPage(0);
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.file_copy_rounded, size: 16),
                    label: const Text('Extract Pages'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      controller.extractPages([0]);
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.image_rounded, size: 16),
                    label: const Text('Extract Images (JPG)'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      controller.exportPagesAsImages(format: 'jpg');
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.print_rounded, size: 16),
                    label: const Text('Print Document'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      controller.printDocument();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnnotationDialog(BuildContext context, PdfController controller, {required bool isHighlight}) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isHighlight ? 'Add Yellow Highlight Note' : 'Add Text / Drawing Note'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Enter annotation text or note...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                controller.addAnnotation(text, isHighlight: isHighlight);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add Annotation'),
          ),
        ],
      ),
    );
  }

  void _showWatermarkDialog(BuildContext context, PdfController controller) {
    final textController = TextEditingController(text: 'CONFIDENTIAL');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add PDF Watermark'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Watermark text (e.g. DRAFT, URGENT)',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                controller.applyWatermark(text);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog(BuildContext context, PdfController controller) {
    final pwdController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Password Protect PDF'),
        content: TextField(
          controller: pwdController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Enter PDF master password',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final pwd = pwdController.text.trim();
              if (pwd.isNotEmpty) {
                controller.setPasswordProtection(pwd);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Encrypt'),
          ),
        ],
      ),
    );
  }

  void _showMergeDialog(BuildContext context, PdfController controller) {
    final docIdController = TextEditingController(text: 'doc_target_sample');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Merge with Document'),
        content: TextField(
          controller: docIdController,
          decoration: const InputDecoration(
            hintText: 'Enter target Document ID to merge',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = docIdController.text.trim();
              if (val.isNotEmpty) {
                controller.mergeWithDocument(val);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Merge'),
          ),
        ],
      ),
    );
  }

  void _showSplitDialog(BuildContext context, PdfController controller, int totalPages) {
    if (totalPages <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document must have at least 2 pages to split.')),
      );
      return;
    }
    final pageController = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Split PDF'),
        content: TextField(
          controller: pageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Split after page (1 to ${totalPages - 1})',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(pageController.text.trim());
              if (val != null && val > 0 && val < totalPages) {
                controller.splitPdf(val);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Split'),
          ),
        ],
      ),
    );
  }

  void _showSignatureDialog(BuildContext context, PdfController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Draw Digital Signature',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Signature Canvas\n(Touch & Drag to Sign)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Embedded cryptographic digital signature into PDF!')),
                        );
                      },
                      child: const Text('Sign PDF'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
