import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../config/injection/injection_container.dart';
import '../../../../config/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/smart_categories.dart';
import '../../../../domain/repositories/document_repository.dart';
import '../../../../models/document_item.dart';
import '../../../../services/pdf/pdf_service.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../../../shared/widgets/document_picker_sheet.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/premium_banner.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../controllers/home_controller.dart';

/// Home dashboard — matches the ScanX AI product reference exactly:
/// brand header w/ premium crown, smart search, AI Document Summary hero,
/// Quick Actions, Recent Documents, Smart Categories.
class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSeeAllDocs;
  final VoidCallback? onSeeAllTools;
  final void Function(String category)? onOpenCategory;

  const HomeScreen({super.key, this.onSeeAllDocs, this.onSeeAllTools, this.onOpenCategory});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _orbController;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final homeController = ref.read(homeProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          Positioned.fill(child: _AmbientOrbs(animation: _orbController)),
          RefreshIndicator(
            color: AppColors.primaryDark,
            backgroundColor: AppColors.surfaceDark,
            onRefresh: () => homeController.loadData(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Row(
                        children: [
                          const ScanXLogoIcon(size: 34),
                          const SizedBox(width: 10),
                          const ScanXWordmark(fontSize: 21),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => context.push(RouteNames.premiumPaywall),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC857).withOpacity(0.12),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFFFC857).withOpacity(0.35)),
                              ),
                              child: const Center(child: PremiumCrownIcon(size: 22)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                    child: _SmartSearchBar(
                      onChanged: homeController.setSearchQuery,
                      onMicTap: () => context.push(RouteNames.aiAssistant),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                    child: _AiSummaryHero(onSummarize: _summarizeNow),
                  ),
                ),

                // ---------- Quick Actions ----------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
                    child: Row(
                      children: [
                        const Text('Quick Actions', style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                        const Spacer(),
                        _SeeAll(onTap: widget.onSeeAllTools),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 96,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      children: [
                        _QuickActionTile(label: 'Scan\nDocument', icon: Icons.document_scanner_rounded, color: const Color(0xFF22D3EE), onTap: () => context.push(RouteNames.scanner)),
                        _QuickActionTile(label: 'Import\nGallery', icon: Icons.photo_library_rounded, color: const Color(0xFFFFC857), onTap: _importGallery),
                        _QuickActionTile(label: 'AI Chat\nwith Docs', icon: Icons.chat_bubble_rounded, color: const Color(0xFFA855F7), onTap: () => context.push(RouteNames.aiAssistant)),
                        _QuickActionTile(label: 'OCR\nExtract Text', icon: Icons.text_snippet_rounded, color: const Color(0xFFFF5A78), onTap: _ocrFlow),
                        _QuickActionTile(label: 'PDF\nTools', icon: Icons.picture_as_pdf_rounded, color: const Color(0xFF8B5CF6), onTap: () => context.push(RouteNames.pdfTools)),
                      ],
                    ),
                  ),
                ),

                // ---------- Recent Documents ----------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                    child: Row(
                      children: [
                        const Text('Recent Documents', style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                        const Spacer(),
                        _SeeAll(onTap: widget.onSeeAllDocs),
                      ],
                    ),
                  ),
                ),
                if (homeState.isLoading)
                  const SliverToBoxAdapter(child: SkeletonLoader())
                else if (homeState.documents.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: EmptyStateWidget(
                        title: 'No Documents Yet',
                        subtitle: 'Capture your first document with AI auto-enhancement, edge detection and ML Kit OCR.',
                        buttonText: 'Start Scanning',
                        onButtonPressed: () => context.push(RouteNames.scanner),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final doc = homeState.documents[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RecentDocRow(doc: doc, onTap: () => context.push(RouteNames.ocrViewer, extra: doc.id)),
                          );
                        },
                        childCount: math.min(homeState.documents.length, 6),
                      ),
                    ),
                  ),

                // ---------- Categories ----------
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                    child: Row(
                      children: [
                        const Text('Categories', style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                        const Spacer(),
                        _SeeAll(onTap: widget.onSeeAllDocs),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 74,
                    child: Builder(builder: (context) {
                      final groups = SmartCategories.group(homeState.documents);
                      const colors = [Color(0xFF3B82F6), Color(0xFFEC4899), Color(0xFFEAB308), Color(0xFF94A3B8)];
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                        itemCount: SmartCategories.names.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, i) {
                          final name = SmartCategories.names[i];
                          final count = groups[name]?.length ?? 0;
                          return GestureDetector(
                            onTap: () => widget.onOpenCategory?.call(name),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: colors[i].withOpacity(0.35)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.folder_rounded, color: colors[i], size: 20),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
                                      Text('$count Files', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 10.5)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),

                SliverToBoxAdapter(child: PremiumBanner(onTap: () => context.push(RouteNames.premiumPaywall))),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
          if (_importing)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: Card(
                  color: AppColors.surfaceDark,
                  child: Padding(
                    padding: EdgeInsets.all(22),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      CircularProgressIndicator(color: AppColors.primaryDark),
                      SizedBox(height: 14),
                      Text('Importing & building PDF…', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _summarizeNow() async {
    final doc = await DocumentPickerSheet.show(context, title: 'Summarize a Document');
    if (doc != null && mounted) {
      context.push(RouteNames.aiAssistant, extra: doc.id);
    }
  }

  Future<void> _ocrFlow() async {
    final doc = await DocumentPickerSheet.show(context, title: 'Extract Text (OCR)');
    if (doc != null && mounted) {
      context.push(RouteNames.ocrViewer, extra: doc.id);
    }
  }

  Future<void> _importGallery() async {
    try {
      final picker = ImagePicker();
      final files = await picker.pickMultiImage(imageQuality: 92);
      if (files.isEmpty || !mounted) return;
      setState(() => _importing = true);

      final paths = files.map((f) => f.path).toList();
      final pdf = await PDFService().createPdfFromImages(
        imagePaths: paths,
        outputFileName: 'import_${DateTime.now().millisecondsSinceEpoch}',
      );

      final title = files.first.name.contains('.')
          ? files.first.name.substring(0, files.first.name.lastIndexOf('.'))
          : files.first.name;
      final doc = DocumentItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: paths.length > 1 ? '$title (+${paths.length - 1})' : title,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        filePaths: paths,
        pdfPath: pdf.path,
        pageCount: paths.length,
        fileSizeBytes: await pdf.exists() ? await pdf.length() : 0,
        tags: const ['Gallery Import'],
      );
      await sl<DocumentRepository>().saveDocument(doc);
      await ref.read(homeProvider.notifier).loadData();

      if (mounted) {
        setState(() => _importing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported ${paths.length} image${paths.length > 1 ? 's' : ''} as PDF'),
            backgroundColor: const Color(0xFF151D3F),
            action: SnackBarAction(label: 'VIEW', textColor: AppColors.neonCyan, onPressed: () => context.push(RouteNames.ocrViewer, extra: doc.id)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _importing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e'), backgroundColor: const Color(0xFF3A1220)));
      }
    }
  }
}

class _SeeAll extends StatelessWidget {
  final VoidCallback? onTap;
  const _SeeAll({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text('See All', style: TextStyle(color: AppColors.neonPurple, fontSize: 12.5, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _AmbientOrbs extends StatelessWidget {
  final Animation<double> animation;
  const _AmbientOrbs({required this.animation});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -80,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) => Transform.translate(offset: Offset(12 * animation.value, 0), child: child),
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.neonPurple.withOpacity(0.20), Colors.transparent])),
            ),
          ),
        ),
        Positioned(
          bottom: 60,
          right: -90,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.neonBlue.withOpacity(0.16), Colors.transparent])),
          ),
        ),
        Positioned(
          top: 300,
          right: 40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.neonCyan.withOpacity(0.08), Colors.transparent])),
          ),
        ),
      ],
    );
  }
}

class _SmartSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback onMicTap;
  const _SmartSearchBar({required this.onChanged, required this.onMicTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF12172E),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(Icons.search_rounded, color: AppColors.textSecondaryDark, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search documents or ask anything...',
                hintStyle: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13.5),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          GestureDetector(
            onTap: onMicTap,
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.neonPurple.withOpacity(0.35), blurRadius: 10)],
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.white, size: 17),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiSummaryHero extends StatelessWidget {
  final VoidCallback onSummarize;
  const _AiSummaryHero({required this.onSummarize});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1.4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.neonPurple.withOpacity(0.55), AppColors.neonCyan.withOpacity(0.35)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF151032), Color(0xFF0D1226)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(22.6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI Document Summary', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                  const SizedBox(height: 8),
                  Text(
                    'Get instant summary, key insights & important points from any document in seconds.',
                    style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: onSummarize,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFA855F7)]),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: AppColors.neonPurple.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 5))],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Summarize Now', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800)),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const CustomPaint(size: Size(112, 112), painter: _AiChipPainter()),
          ],
        ),
      ),
    );
  }
}

/// Glowing "AI chip" artwork with circuit traces (right side of the hero card).
class _AiChipPainter extends CustomPainter {
  const _AiChipPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 100;
    Offset p(double x, double y) => Offset(x * k, y * k);

    // circuit traces
    final traces = [
      [p(50, 22), p(50, 6)], [p(50, 78), p(50, 94)],
      [p(22, 50), p(6, 50)], [p(78, 50), p(94, 50)],
      [p(30, 30), p(16, 16)], [p(70, 30), p(84, 16)],
      [p(30, 70), p(16, 84)], [p(70, 70), p(84, 84)],
    ];
    for (final t in traces) {
      canvas.drawLine(t[0], t[1], Paint()..color = const Color(0xFF22D3EE).withOpacity(0.7)..strokeWidth = 1.6 * k..strokeCap = StrokeCap.round);
      canvas.drawCircle(t[1], 2.4 * k, Paint()..color = const Color(0xFF22D3EE));
    }

    final chipRect = Rect.fromLTRB(26 * k, 26 * k, 74 * k, 74 * k);
    final rrect = RRect.fromRectAndRadius(chipRect, Radius.circular(10 * k));
    canvas.saveLayer(Rect.fromLTRB(0, 0, size.width, size.height), Paint());
    canvas.drawRRect(rrect, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * k
      ..shader = const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF22D3EE)]).createShader(chipRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.restore();

    canvas.drawRRect(rrect, Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF3B1D7A), Color(0xFF1E1B4B)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(chipRect));
    canvas.drawRRect(rrect, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * k
      ..shader = const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF22D3EE)]).createShader(chipRect));

    final tp = TextPainter(
      text: TextSpan(
        text: 'AI',
        style: TextStyle(color: Colors.white, fontSize: 20 * k, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width / 2 - tp.width / 2, size.height / 2 - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _QuickActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionTile({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 9.8, fontWeight: FontWeight.w600, height: 1.25),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentDocRow extends StatelessWidget {
  final DocumentItem doc;
  final VoidCallback onTap;
  const _RecentDocRow({required this.doc, required this.onTap});

  ({String ext, Color color, IconData icon}) _type() {
    final name = doc.title.toLowerCase();
    if (name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png')) {
      return (ext: 'JPG', color: const Color(0xFF10B981), icon: Icons.image_rounded);
    }
    if (name.endsWith('.docx') || name.endsWith('.doc') || name.endsWith('.txt')) {
      return (ext: 'DOCX', color: const Color(0xFF3B82F6), icon: Icons.description_rounded);
    }
    return (ext: 'PDF', color: const Color(0xFFEF4444), icon: Icons.picture_as_pdf_rounded);
  }

  String _when(DateTime d) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final time = DateFormat('hh:mm a').format(d);
    if (d.year == now.year && d.month == now.month && d.day == now.day) return 'Today, $time';
    if (d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day) return 'Yesterday, $time';
    return '${DateFormat('d MMM yyyy').format(d)}, $time';
  }

  @override
  Widget build(BuildContext context) {
    final t = _type();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF10152B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: t.color.withOpacity(0.16), borderRadius: BorderRadius.circular(10)),
                child: Icon(t.icon, color: t.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(_when(doc.createdAt), style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: t.color.withOpacity(0.18), borderRadius: BorderRadius.circular(6)),
                child: Text(t.ext, style: TextStyle(color: t.color, fontSize: 9.5, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: AppColors.textTertiaryDark, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
