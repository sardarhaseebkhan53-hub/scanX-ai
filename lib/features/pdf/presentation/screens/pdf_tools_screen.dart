import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/tool_card.dart';

class _ToolSpec {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  const _ToolSpec(this.title, this.subtitle, this.icon, this.gradient);
}

/// PDF Tools dashboard — a single responsive 2-column grid of all 12 tools.
/// Built with SliverGrid.builder (lazy) inside a CustomScrollView so equal
/// card heights, spacing, and text truncation are handled once, centrally,
/// with zero risk of RenderFlex overflow at any screen width.
class PdfToolsScreen extends StatelessWidget {
  const PdfToolsScreen({super.key});

  static final List<_ToolSpec> _tools = [
    _ToolSpec('Merge', 'Combine PDFs', Icons.merge_rounded, AppColors.purpleGradient),
    _ToolSpec('Split', 'Extract pages', Icons.call_split_rounded, AppColors.cyanGradient),
    _ToolSpec('Compress', 'Reduce size', Icons.compress_rounded, AppColors.emeraldGradient),
    _ToolSpec('Convert', 'PDF, Word, JPG', Icons.transform_rounded, AppColors.primaryGradient),
    _ToolSpec('Rotate', 'Rotate pages', Icons.rotate_right_rounded, AppColors.goldGradient),
    _ToolSpec('Delete Pages', 'Remove pages', Icons.delete_outline_rounded, AppColors.purpleGradient),
    _ToolSpec('Watermark', 'Add watermark', Icons.water_drop_rounded, AppColors.cyanGradient),
    _ToolSpec('Protect', 'Lock with password', Icons.lock_rounded, AppColors.goldGradient),
    _ToolSpec('Reorder', 'Rearrange pages', Icons.reorder_rounded, AppColors.primaryGradient),
    _ToolSpec('Extract Images', 'Save embedded images', Icons.image_rounded, AppColors.emeraldGradient),
    _ToolSpec('Signature', 'Sign documents', Icons.draw_rounded, AppColors.purpleGradient),
    _ToolSpec('OCR', 'Extract text', Icons.text_snippet_rounded, AppColors.cyanGradient),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'PDF Tools', showBackButton: true),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'All Tools',
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, AppSpacing.md, 20, AppSpacing.xxxl),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.35,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tool = _tools[index];
                  return RepaintBoundary(
                    child: ToolCard(
                      title: tool.title,
                      subtitle: tool.subtitle,
                      icon: tool.icon,
                      gradient: tool.gradient,
                      onTap: () => _openPdfEditor(context, tool.title),
                    ),
                  );
                },
                childCount: _tools.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPdfEditor(BuildContext context, String tool) {
    context.push(RouteNames.pdfEditor, extra: 'doc_integration_01');
  }
}
