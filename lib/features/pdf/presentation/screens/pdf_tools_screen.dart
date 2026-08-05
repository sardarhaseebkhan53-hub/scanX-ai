import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/document_picker_sheet.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/tool_card.dart';

class _ToolSpec {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final bool isPro;
  const _ToolSpec(this.title, this.subtitle, this.icon, this.gradient, {this.isPro = false});
}

class PdfToolsScreen extends StatefulWidget {
  const PdfToolsScreen({super.key});

  @override
  State<PdfToolsScreen> createState() => _PdfToolsScreenState();
}

class _PdfToolsScreenState extends State<PdfToolsScreen> {
  String _filter = 'All';

  static final List<_ToolSpec> _tools = [
    _ToolSpec('Merge PDFs', 'Combine multiple PDFs', Icons.merge_rounded, AppColors.primaryGradient),
    _ToolSpec('Split PDF', 'Extract pages easily', Icons.call_split_rounded, AppColors.purpleGradient),
    _ToolSpec('Compress', 'Reduce file size', Icons.compress_rounded, AppColors.emeraldGradient),
    _ToolSpec('Convert', 'PDF ↔ Word ↔ JPG', Icons.transform_rounded, AppColors.scannerGradient),
    _ToolSpec('Rotate', 'Rotate pages', Icons.rotate_right_rounded, AppColors.goldGradient),
    _ToolSpec('Delete Pages', 'Remove unwanted', Icons.delete_sweep_rounded, AppColors.purpleGradient, isPro: true),
    _ToolSpec('Watermark', 'Add custom mark', Icons.water_drop_rounded, AppColors.cyanGradient),
    _ToolSpec('Protect PDF', 'Lock with password', Icons.lock_rounded, AppColors.goldGradient, isPro: true),
    _ToolSpec('Reorder', 'Rearrange pages', Icons.reorder_rounded, AppColors.scannerGradient),
    _ToolSpec('Extract Images', 'Save embedded pics', Icons.image_rounded, AppColors.emeraldGradient),
    _ToolSpec('E-Signature', 'Sign documents', Icons.draw_rounded, AppColors.aiGradient, isPro: true),
    _ToolSpec('OCR Scan', 'Extract text AI', Icons.text_snippet_rounded, AppColors.aiGradient),
  ];

  Future<void> _openTool(_ToolSpec tool) async {
    final doc = await DocumentPickerSheet.show(context, title: '${tool.title}: Choose a document');
    if (!mounted) return;
    if (doc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select or scan a document first.'), backgroundColor: Color(0xFF151D3F)),
      );
      return;
    }
    context.push(RouteNames.pdfEditor, extra: doc.id);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'All' ? _tools : _tools.where((t) => _filter == 'Pro' ? t.isPro : !t.isPro).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: const CustomAppBar(
        title: 'PDF Tools',
        subtitle: '12 premium tools • Offline ready',
        showBackButton: true,
      ),
      body: Stack(
        children: [
          // Ambient orbs
          Positioned(top: -80, left: -60, child: Container(width: 280, height: 280, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.neonBlue.withOpacity(0.14), Colors.transparent])))),
          Positioned(bottom: -40, right: -40, child: Container(width: 260, height: 260, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.neonPurple.withOpacity(0.12), Colors.transparent])))),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.06))),
                    child: Row(
                      children: [
                        _FilterChip(label: 'All', selected: _filter == 'All', onTap: () => setState(() => _filter = 'All')),
                        _FilterChip(label: 'Free', selected: _filter == 'Free', onTap: () => setState(() => _filter = 'Free')),
                        _FilterChip(label: 'Pro', selected: _filter == 'Pro', onTap: () => setState(() => _filter = 'Pro')),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF151D3F), Color(0xFF111936)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(color: Colors.white.withOpacity(0.07)),
                    ),
                    child: Row(
                      children: [
                        Container(width: 44, height: 44, decoration: BoxDecoration(gradient: AppColors.scannerGradient, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22)),
                        const SizedBox(width: 12),
                        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Batch Processing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)), SizedBox(height: 2), Text('Select multiple PDFs for merge, compress, convert', style: TextStyle(color: Color(0xFF8B94B8), fontSize: 11.5))])),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(20)), child: const Text('NEW', style: TextStyle(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.w800))),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              const SliverToBoxAdapter(child: SectionHeader(title: 'All Tools', icon: Icons.dashboard_customize_rounded)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.crossAxisExtent;
                    final columns = width >= 900 ? 4 : (width >= 620 ? 3 : 2);
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: width < 360 ? 1.12 : 1.35,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final tool = filtered[index];
                          return ToolCard(title: tool.title, subtitle: tool.subtitle, icon: tool.icon, gradient: tool.gradient, isPro: tool.isPro, onTap: () => _openTool(tool));
                        },
                        childCount: filtered.length,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.primaryGradient : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected ? [BoxShadow(color: AppColors.primaryDark.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : null,
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondaryDark, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ),
    );
  }
}
