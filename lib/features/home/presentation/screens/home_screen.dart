import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../config/injection/injection_container.dart';
import '../../../../config/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/smart_categories.dart';
import '../../../../domain/repositories/document_repository.dart';
import '../../../../models/document_item.dart';
import '../../../../services/pdf/pdf_service.dart';
import '../../../../shared/widgets/document_picker_sheet.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../settings/presentation/controllers/user_profile_controller.dart';
import '../controllers/home_controller.dart';

// ---------------------------------------------------------------------------
// ScanX AI — Premium Home Landing Page
// Dark space, glassmorphism, neon gradients, glow, subtle blur
// ---------------------------------------------------------------------------

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSeeAllDocs;
  final VoidCallback? onSeeAllTools;
  final void Function(String category)? onOpenCategory;
  final ScrollController? scrollController;

  const HomeScreen({super.key, this.onSeeAllDocs, this.onSeeAllTools, this.onOpenCategory, this.scrollController});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _orbCtrl;
  late AnimationController _entrance;
  late AnimationController _shine;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _shine = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _entrance.forward();
    });
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _entrance.dispose();
    _shine.dispose();
    super.dispose();
  }

  /// Returns a time-appropriate greeting string.
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final homeCtrl = ref.read(homeProvider.notifier);
    final userProfile = ref.watch(userProfileProvider);
    final screenW = MediaQuery.of(context).size.width;
    final isCompact = screenW < 380;
    final hPad = isCompact ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFF070A1E),
      body: Stack(
        children: [
          Positioned.fill(child: _PremiumBackground(anim: _orbCtrl, shine: _shine)),
          const Positioned.fill(child: _DotGrid()),
          RefreshIndicator(
            color: AppColors.neonPurple,
            backgroundColor: const Color(0xFF12172E),
            onRefresh: () => homeCtrl.loadData(),
            child: CustomScrollView(
              controller: widget.scrollController,
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                // ---- Header: Greeting + Pro + Bell + Avatar ----
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: _AnimatedEntrance(
                      controller: _entrance,
                      delay: 0,
                      child: _HomeHeader(
                        greeting: _greeting(),
                        userName: userProfile.isLoggedIn ? userProfile.displayName : null,
                        avatarPath: userProfile.avatarPath,
                        onProTap: () => context.push(RouteNames.premiumPaywall),
                        onBellTap: () => context.push(RouteNames.notifications),
                        onAvatarTap: () => ref.read(userProfileProvider.notifier).pickAvatarFromGallery(),
                      ),
                    ),
                  ),
                ),
                // ---- Search ----
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 10),
                    child: _AnimatedEntrance(
                      controller: _entrance,
                      delay: 80,
                      child: _GlassSearchBar(
                        onChanged: homeCtrl.setSearchQuery,
                        onMicTap: () => context.push(RouteNames.aiAssistant),
                        onCameraTap: () => context.push(RouteNames.scanner),
                        onSparkleTap: () => context.push(RouteNames.aiAssistant),
                      ),
                    ),
                  ),
                ),
                // ---- AI Assistant Hero ----
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, 6, hPad, 10),
                    child: _AnimatedEntrance(
                      controller: _entrance,
                      delay: 140,
                      child: _AiAssistantCard(
                        onStartChat: () => context.push(RouteNames.aiAssistant),
                        onSummarize: () => _goAi(context, 'summarize'),
                        onTranslate: () => _goAi(context, 'translate'),
                        onRewrite: () => _goAi(context, 'rewrite'),
                        onExplain: () => _goAi(context, 'explain'),
                        onChatPdf: () => context.push(RouteNames.aiAssistant),
                        onHomework: () => context.push(RouteNames.aiAssistant),
                      ),
                    ),
                  ),
                ),

                // ---- Quick Actions ----
                SliverToBoxAdapter(
                  child: _AnimatedEntrance(
                    controller: _entrance,
                    delay: 200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SectionHeader(title: 'Quick Actions', actionLabel: 'View All', onTap: widget.onSeeAllTools),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 12,
                            alignment: WrapAlignment.spaceEvenly,
                            children: [
                              _QuickCircle(icon: Icons.document_scanner_rounded, label: 'Scan', color: const Color(0xFFA855F7), glow: const Color(0xFFA855F7), onTap: () => context.push(RouteNames.scanner)),
                              _QuickCircle(icon: Icons.image_rounded, label: 'Gallery', color: const Color(0xFF3B82F6), glow: const Color(0xFF3B82F6), onTap: _importGallery),
                              _QuickCircle(icon: Icons.photo_camera_rounded, label: 'Camera', color: Colors.white, glow: const Color(0xFF6B7280), onTap: () => context.push(RouteNames.scanner)),
                              _QuickCircle(icon: Icons.crop_free_rounded, label: 'OCR', color: const Color(0xFF22C55E), glow: const Color(0xFF22C55E), onTap: _ocrFlow),
                              _QuickCircle(icon: Icons.smart_toy_rounded, label: 'AI Chat', color: const Color(0xFFA855F7), glow: const Color(0xFFA855F7), onTap: () => context.push(RouteNames.aiAssistant)),
                              _QuickCircle(icon: Icons.translate_rounded, label: 'Translate', color: const Color(0xFF94A3B8), glow: const Color(0xFF94A3B8), onTap: () => context.push(RouteNames.aiAssistant)),
                              _QuickCircle(icon: Icons.picture_as_pdf_rounded, label: 'Merge PDF', color: const Color(0xFFFFC857), glow: const Color(0xFFFFC857), onTap: () => context.push(RouteNames.pdfTools)),
                              _QuickCircle(icon: Icons.share_rounded, label: 'Share', color: const Color(0xFFE879F9), glow: const Color(0xFFE879F9), onTap: () => context.push(RouteNames.pdfTools)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ---- AI Suggestions ----
                SliverToBoxAdapter(
                  child: _AnimatedEntrance(
                    controller: _entrance,
                    delay: 260,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SectionHeader(title: 'AI Suggestions', actionLabel: 'See All', onTap: widget.onSeeAllTools),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _SuggestionCard(
                                  title: 'Summarize\nPDF',
                                  icon: Icons.description_rounded,
                                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)]),
                                  borderColor: const Color(0xFFA855F7).withOpacity(0.45),
                                  onTap: () => context.push(RouteNames.aiAssistant),
                                ),
                                _SuggestionCard(
                                  title: 'Translate\nNotes',
                                  icon: Icons.language_rounded,
                                  gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF3B82F6)]),
                                  borderColor: const Color(0xFF3B82F6).withOpacity(0.4),
                                  onTap: () => context.push(RouteNames.aiAssistant),
                                ),
                                _SuggestionCard(
                                  title: 'Explain\nHomework',
                                  icon: Icons.school_rounded,
                                  gradient: const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF15803D)]),
                                  borderColor: const Color(0xFF22C55E).withOpacity(0.4),
                                  onTap: () => context.push(RouteNames.aiAssistant),
                                ),
                                _SuggestionCard(
                                  title: 'Analyze\nReport',
                                  icon: Icons.analytics_rounded,
                                  gradient: const LinearGradient(colors: [Color(0xFFEA580C), Color(0xFFF97316)]),
                                  borderColor: const Color(0xFFF97316).withOpacity(0.4),
                                  onTap: () => context.push(RouteNames.receiptAnalysis),
                                ),
                                _SuggestionCard(
                                  title: 'Extract\nTable',
                                  icon: Icons.table_chart_rounded,
                                  gradient: const LinearGradient(colors: [Color(0xFF1E3A5F), Color(0xFF2B4A7A)]),
                                  borderColor: const Color(0xFF60A5FA).withOpacity(0.35),
                                  onTap: () => _ocrFlow(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ---- Recent Documents + Continue Working + Cloud Sync ----
                SliverToBoxAdapter(
                  child: _AnimatedEntrance(
                    controller: _entrance,
                    delay: 320,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 6, hPad, 0),
                      child: LayoutBuilder(builder: (context, c) {
                        final isWide = c.maxWidth > 600;
                        final recentList = _buildRecentList(homeState);
                        final sideColumn = Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ContinueWorkingCard(
                              docTitle: homeState.documents.isNotEmpty ? homeState.documents.first.title : 'Physics Notes.pdf',
                              progress: 0.73,
                              onContinue: () {
                                if (homeState.documents.isNotEmpty) {
                                  context.push(RouteNames.ocrViewer, extra: homeState.documents.first.id);
                                } else {
                                  context.push(RouteNames.scanner);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            _CloudSyncCard(onView: () => context.push(RouteNames.cloudSync)),
                          ],
                        );

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 58, child: recentList),
                              const SizedBox(width: 12),
                              Expanded(flex: 42, child: sideColumn),
                            ],
                          );
                        }
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            recentList,
                            const SizedBox(height: 12),
                            sideColumn,
                          ],
                        );
                      }),
                    ),
                  ),
                ),

                // ---- Stats Pills Row ----
                SliverToBoxAdapter(
                  child: _AnimatedEntrance(
                    controller: _entrance,
                    delay: 380,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                      child: _StatsPillsRow(counts: _computeCounts(homeState)),
                    ),
                  ),
                ),

                // ---- Bottom 4 cards ----
                SliverToBoxAdapter(
                  child: _AnimatedEntrance(
                    controller: _entrance,
                    delay: 440,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 8),
                      child: LayoutBuilder(builder: (context, c) {
                        final w = c.maxWidth;
                        if (w < 560) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IntrinsicHeight(
                                child: Row(children: [
                                  Expanded(child: _TodayScansCard(count: _todayCount(homeState))),
                                  const SizedBox(width: 10),
                                  Expanded(child: _OcrAccuracyCard()),
                                ]),
                              ),
                              const SizedBox(height: 10),
                              IntrinsicHeight(
                                child: Row(children: [
                                  Expanded(child: _AiTokensCard()),
                                  const SizedBox(width: 10),
                                  Expanded(child: _DailyTipCard()),
                                ]),
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: _TodayScansCard(count: _todayCount(homeState))),
                            const SizedBox(width: 10),
                            Expanded(child: _OcrAccuracyCard()),
                            const SizedBox(width: 10),
                            Expanded(child: _AiTokensCard()),
                            const SizedBox(width: 10),
                            Expanded(child: _DailyTipCard()),
                          ],
                        );
                      }),
                    ),
                  ),
                ),

                // ---- Premium Upgrade Banner ----
                SliverToBoxAdapter(
                  child: _AnimatedEntrance(
                    controller: _entrance,
                    delay: 500,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 6, hPad, 0),
                      child: _PremiumUpgradeBanner(onTap: () => context.push(RouteNames.premiumPaywall)),
                    ),
                  ),
                ),

                // bottom padding for nav + fab + floating bot
                SliverToBoxAdapter(child: SafeArea(top: false, child: SizedBox(height: 160))),
              ],
            ),
          ),
          if (_importing)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withOpacity(0.55),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF12172E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 12))],
                      ),
                      child: const Column(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFFA855F7))),
                        SizedBox(height: 14),
                        Text('Importing & building PDF…', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        SizedBox(height: 4),
                        Text('Optimizing with AI enhancement', style: TextStyle(color: Color(0xFF8B94B8), fontSize: 11)),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentList(HomeState homeState) {
    if (homeState.isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1330).withOpacity(0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        padding: const EdgeInsets.all(10),
        child: const SkeletonLoader(itemCount: 3),
      );
    }
    if (homeState.documents.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1330).withOpacity(0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: EmptyStateWidget(
          title: 'No Documents Yet',
          subtitle: 'Capture your first document with AI auto-enhancement.',
          buttonText: 'Start Scanning',
          onButtonPressed: () => context.push(RouteNames.scanner),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent Documents',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.2),
              ),
            ),
            _SeeAll(onTap: widget.onSeeAllDocs),
          ],
        ),
        const SizedBox(height: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(math.min(homeState.documents.length, 3), (i) {
            final doc = homeState.documents[i];
            return Padding(
              padding: EdgeInsets.only(bottom: i == 2 ? 0 : 10),
              child: _RecentDocRowNew(doc: doc, onTap: () => context.push(RouteNames.ocrViewer, extra: doc.id)),
            );
          }),
        ),
      ],
    );
  }

  int _todayCount(HomeState s) {
    final now = DateTime.now();
    return s.documents.where((d) => d.createdAt.year == now.year && d.createdAt.month == now.month && d.createdAt.day == now.day).length;
  }

  Map<String, int> _computeCounts(HomeState s) {
    return {
      'docs': s.documents.length,
      'chats': 48,
      'scans': s.documents.fold<int>(0, (a, b) => a + b.pageCount),
      'gb': 8,
    };
  }

  void _goAi(BuildContext ctx, String type) => ctx.push(RouteNames.aiAssistant);

  Future<void> _ocrFlow() async {
    final doc = await DocumentPickerSheet.show(context, title: 'Extract Text (OCR)');
    if (doc != null && mounted) context.push(RouteNames.ocrViewer, extra: doc.id);
  }

  Future<void> _importGallery() async {
    try {
      final picker = ImagePicker();
      final files = await picker.pickMultiImage(imageQuality: 92);
      if (files.isEmpty || !mounted) return;
      setState(() => _importing = true);
      final paths = files.map((f) => f.path).toList();
      final pdf = await PDFService().createPdfFromImages(imagePaths: paths, outputFileName: 'import_${DateTime.now().millisecondsSinceEpoch}');
      final title = files.first.name.contains('.') ? files.first.name.substring(0, files.first.name.lastIndexOf('.')) : files.first.name;
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Imported ${paths.length} image${paths.length > 1 ? 's' : ''} as PDF'),
          backgroundColor: const Color(0xFF151D3F),
          action: SnackBarAction(label: 'VIEW', textColor: const Color(0xFF22D3EE), onPressed: () => context.push(RouteNames.ocrViewer, extra: doc.id)),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _importing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e'), backgroundColor: const Color(0xFF3A1220)));
      }
    }
  }
}

// ===========================================================================
// Background + effects
// ===========================================================================

class _PremiumBackground extends StatelessWidget {
  final Animation<double> anim;
  final Animation<double> shine;
  const _PremiumBackground({required this.anim, required this.shine});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([anim, shine]),
      builder: (context, _) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF070A1E), Color(0xFF080C24), Color(0xFF070A1E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(children: [
            Positioned(
              top: -90 + 10 * anim.value,
              left: -80,
              child: Container(
                width: 420,
                height: 420,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [const Color(0xFFA855F7).withOpacity(0.22), Colors.transparent], center: Alignment.center, radius: 0.7),
                ),
              ),
            ),
            Positioned(
              top: 280,
              right: -90,
              child: Container(
                width: 420,
                height: 420,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [const Color(0xFF3B82F6).withOpacity(0.14), Colors.transparent]),
                ),
              ),
            ),
            Positioned(
              bottom: 180,
              left: -40,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [const Color(0xFF06B6D4).withOpacity(0.09), Colors.transparent]),
                ),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.04 + 0.02 * math.sin(shine.value * 2 * math.pi),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.white.withOpacity(0.05), Colors.transparent],
                      begin: Alignment(-1 - shine.value, -1),
                      end: Alignment(1 - shine.value, 1),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [Colors.transparent, const Color(0xFF050714).withOpacity(0.55)],
                  ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _DotGrid extends StatelessWidget {
  const _DotGrid();
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _DotGridPainter(), size: Size.infinite),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = Colors.white.withOpacity(0.018);
    const gap = 22.0;
    for (double y = 16; y < size.height; y += gap) {
      for (double x = 16; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 0.9, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnimatedEntrance extends StatelessWidget {
  final AnimationController controller;
  final int delay;
  final Widget child;
  const _AnimatedEntrance({required this.controller, required this.delay, required this.child});

  @override
  Widget build(BuildContext context) {
    final start = (delay / 900).clamp(0.0, 1.0);
    final end = (start + 0.42).clamp(0.0, 1.0);
    final curved = CurvedAnimation(parent: controller, curve: Interval(start, end, curve: Curves.easeOutCubic));
    return AnimatedBuilder(
      animation: curved,
      builder: (context, c) {
        final t = curved.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 18 * (1 - t)), child: c),
        );
      },
      child: child,
    );
  }
}

// ===========================================================================
// Header — dynamic greeting, clickable avatar with image picker, notification
// ===========================================================================

class _HomeHeader extends StatelessWidget {
  final String greeting;
  final String? userName;
  final String? avatarPath;
  final VoidCallback onProTap;
  final VoidCallback onBellTap;
  final VoidCallback onAvatarTap;
  const _HomeHeader({
    required this.greeting,
    required this.userName,
    required this.avatarPath,
    required this.onProTap,
    required this.onBellTap,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 380;
          final btnSize = isCompact ? 46.0 : 54.0;
          final gap = isCompact ? 6.0 : 10.0;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Greeting column
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  ShaderMask(
                    shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFE879F9), Color(0xFFA855F7), Color(0xFFC084FC)]).createShader(r),
                    child: Text(
                      '$greeting,',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? 12 : 14,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          userName ?? 'Guest',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isCompact ? 20 : 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                            height: 1.05,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('👋', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userName != null ? 'Welcome back to ScanX AI' : 'Scan smarter with AI',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withOpacity(0.62), fontSize: 12.5, fontWeight: FontWeight.w500),
                  ),
                ]),
              ),
              SizedBox(width: gap),
              // PRO button
              _HeaderButton(
                size: btnSize,
                onTap: onProTap,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFC857), size: 20),
                    const SizedBox(height: 1),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.2),
                      decoration: BoxDecoration(color: const Color(0xFFFFC857), borderRadius: BorderRadius.circular(5)),
                      child: const Text('PRO', style: TextStyle(color: Color(0xFF2A1B00), fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                    ),
                  ],
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [Color(0xFF3A2A0A), Color(0xFF1A1405)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  border: Border.all(color: const Color(0xFFFFC857).withOpacity(0.5), width: 1.2),
                  boxShadow: [BoxShadow(color: const Color(0xFFFFC857).withOpacity(0.18), blurRadius: 14, offset: const Offset(0, 6))],
                ),
              ),
              SizedBox(width: gap),
              // Bell notification button
              _HeaderButton(
                size: btnSize,
                onTap: onBellTap,
                child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 22),
                decoration: BoxDecoration(
                  color: const Color(0xFF12172E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                badge: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFA855F7),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF070A1E), width: 1.8),
                    boxShadow: [BoxShadow(color: const Color(0xFFA855F7).withOpacity(0.5), blurRadius: 8)],
                  ),
                  child: const Center(child: Text('3', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
                ),
              ),
              SizedBox(width: gap),
              // Avatar — clickable, shows picked image or default
              GestureDetector(
                onTap: onAvatarTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: btnSize,
                  height: btnSize,
                  padding: const EdgeInsets.all(1.6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFFE879F9), Color(0xFF8B5CF6), Color(0xFF3B82F6)]),
                    boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: ClipOval(
                    child: avatarPath != null && File(avatarPath!).existsSync()
                        ? Image.file(File(avatarPath!), fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const _DefaultAvatar())
                        : const _DefaultAvatar(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Default avatar shown when no profile picture is set.
class _DefaultAvatar extends StatelessWidget {
  const _DefaultAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1B2348),
      child: const Icon(Icons.person_rounded, color: Colors.white70, size: 26),
    );
  }
}

/// Reusable header button with press animation and optional badge overlay.
class _HeaderButton extends StatefulWidget {
  final double size;
  final VoidCallback onTap;
  final Widget child;
  final BoxDecoration decoration;
  final Widget? badge;

  const _HeaderButton({
    required this.size,
    required this.onTap,
    required this.child,
    required this.decoration,
    this.badge,
  });

  @override
  State<_HeaderButton> createState() => _HeaderButtonState();
}

class _HeaderButtonState extends State<_HeaderButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: widget.decoration,
              child: Center(child: widget.child),
            ),
            if (widget.badge != null)
              Positioned(
                top: -2,
                right: -2,
                child: widget.badge!,
              ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Search bar - glass pill with 3 actions
// ===========================================================================

class _GlassSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback onMicTap;
  final VoidCallback onCameraTap;
  final VoidCallback onSparkleTap;
  const _GlassSearchBar({required this.onChanged, required this.onMicTap, required this.onCameraTap, required this.onSparkleTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(colors: [const Color(0xFFA855F7).withOpacity(0.55), const Color(0xFF3B82F6).withOpacity(0.45)]),
        boxShadow: [BoxShadow(color: const Color(0xFFA855F7).withOpacity(0.22), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(1.2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF11152E).withOpacity(0.96),
              borderRadius: BorderRadius.circular(27),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(children: [
              const SizedBox(width: 14),
              Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.55), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  onChanged: onChanged,
                  style: const TextStyle(color: Colors.white, fontSize: 13.8, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Search documents, AI tools or ask anything...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.42), fontSize: 13, fontWeight: FontWeight.w500),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SearchAction(icon: Icons.mic_rounded, onTap: onMicTap),
              const SizedBox(width: 6),
              _SearchAction(icon: Icons.photo_camera_rounded, onTap: onCameraTap),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onSparkleTap,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6), Color(0xFF06B6D4)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.45), blurRadius: 10, offset: const Offset(0, 4))],
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 6),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SearchAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SearchAction({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.85), size: 17),
      ),
    );
  }
}

// ===========================================================================
// AI Assistant Card
// ===========================================================================

class _AiAssistantCard extends StatelessWidget {
  final VoidCallback onStartChat;
  final VoidCallback onSummarize;
  final VoidCallback onTranslate;
  final VoidCallback onRewrite;
  final VoidCallback onExplain;
  final VoidCallback onChatPdf;
  final VoidCallback onHomework;
  const _AiAssistantCard({
    required this.onStartChat,
    required this.onSummarize,
    required this.onTranslate,
    required this.onRewrite,
    required this.onExplain,
    required this.onChatPdf,
    required this.onHomework,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6), Color(0xFF7C3AED)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [
          BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.30), blurRadius: 28, offset: const Offset(0, 12)),
          BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 22, offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(1.4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22.6),
        child: Stack(children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1B1340), Color(0xFF120E2E), Color(0xFF0F0B2A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
          ),
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFF8B5CF6).withOpacity(0.22), Colors.transparent])),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFF3B82F6).withOpacity(0.18), Colors.transparent])),
            ),
          ),
          Positioned(top: 22, right: 110, child: _Star(size: 7)),
          Positioned(top: 78, left: 164, child: _Star(size: 5, opacity: 0.7)),
          Positioned(bottom: 34, left: 198, child: _Star(size: 9, opacity: 0.9)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 340;
                if (isNarrow) {
                  // Stack vertically on very narrow screens
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLeftContent(),
                      const SizedBox(height: 12),
                      const Center(child: SizedBox(height: 140, child: _RobotIllustration())),
                    ],
                  );
                }
                return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(flex: 62, child: _buildLeftContent()),
                  const SizedBox(width: 8),
                  const Expanded(flex: 38, child: _RobotIllustration()),
                ]);
              },
            ),
          ),
          Positioned(top: 0, left: 18, right: 18, child: Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.white.withOpacity(0.18), Colors.transparent])))),
        ]),
      ),
    );
  }

  Widget _buildLeftContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFA855F7).withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.25)),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.auto_awesome_rounded, color: Color(0xFFD8B4FE), size: 11),
            SizedBox(width: 5),
            Flexible(child: Text('AI ASSISTANT', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Color(0xFFD8B4FE), fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.8))),
          ]),
        ),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(colors: [Colors.white, Color(0xFFD8B4FE)]).createShader(r),
          child: const Text('Your AI Document Assistant', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w900, height: 1.15, letterSpacing: -0.3)),
        ),
        const SizedBox(height: 6),
        Text('Summarize, translate, explain and chat with any document using the power of AI.', maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.68), fontSize: 11.2, height: 1.5, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          _AiPill(icon: Icons.article_rounded, label: 'Summarize', onTap: onSummarize),
          _AiPill(icon: Icons.translate_rounded, label: 'Translate', onTap: onTranslate),
          _AiPill(icon: Icons.edit_note_rounded, label: 'Rewrite', onTap: onRewrite),
          _AiPill(icon: Icons.menu_book_rounded, label: 'Explain', onTap: onExplain),
          _AiPill(icon: Icons.picture_as_pdf_rounded, label: 'Chat with PDF', onTap: onChatPdf),
          _AiPill(icon: Icons.school_rounded, label: 'Homework Helper', onTap: onHomework),
        ]),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onStartChat,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.45), blurRadius: 16, offset: const Offset(0, 6))],
              border: Border.all(color: Colors.white.withOpacity(0.14)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Flexible(child: Text('Start AI Chat', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800))),
              const SizedBox(width: 16),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 8)]),
                child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF7C3AED), size: 14),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _Star extends StatelessWidget {
  final double size;
  final double opacity;
  const _Star({required this.size, this.opacity = 1});
  @override
  Widget build(BuildContext context) {
    return Opacity(opacity: opacity, child: Icon(Icons.auto_awesome_rounded, color: const Color(0xFFC4B5FD), size: size));
  }
}

class _AiPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AiPill({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5.5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 11),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class _RobotIllustration extends StatelessWidget {
  const _RobotIllustration();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            height: 152,
            width: 152,
            child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
              Positioned(
                bottom: 6,
                child: Container(
                  width: 96,
                  height: 22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: RadialGradient(colors: [const Color(0xFF8B5CF6).withOpacity(0.55), Colors.transparent]),
                    boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.5), blurRadius: 22, spreadRadius: 2)],
                  ),
                ),
              ),
              Positioned(bottom: 10, child: Container(width: 84, height: 28, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.7), width: 1.2)))),
              Positioned(bottom: 16, child: Container(width: 66, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.65), width: 1)))),
              Positioned(left: 2, top: 18, child: _FloatingDoc(icon: Icons.picture_as_pdf_rounded, color: const Color(0xFFEF4444), label: 'PDF', rotation: -12)),
              Positioned(right: -2, top: 22, child: _FloatingDoc(icon: Icons.description_rounded, color: const Color(0xFF3B82F6), label: 'W', rotation: 10)),
              Positioned(right: 6, bottom: 56, child: _FloatingDoc(icon: Icons.description_rounded, color: const Color(0xFF8B94B8), label: '', rotation: 12, small: true)),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Stack(clipBehavior: Clip.none, children: [
                  Container(width: 2.5, height: 10, color: const Color(0xFFC4B5FD).withOpacity(0.9)),
                  Positioned(top: -6, left: -4, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: const Color(0xFF22D3EE), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.8), width: 1), boxShadow: [BoxShadow(color: const Color(0xFF22D3EE).withOpacity(0.6), blurRadius: 8)]))),
                ]),
                const SizedBox(height: 2),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE), Color(0xFFC4B5FD)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.2),
              boxShadow: [
                BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8)),
                BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Stack(children: [
              Center(
                child: Container(
                  width: 72,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0B2A),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.5)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    Container(width: 18, height: 18, decoration: BoxDecoration(color: const Color(0xFFA855F7), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFFA855F7).withOpacity(0.8), blurRadius: 10)])),
                    Container(width: 18, height: 18, decoration: BoxDecoration(color: const Color(0xFFC084FC), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFFC084FC).withOpacity(0.7), blurRadius: 10)])),
                  ]),
                ),
              ),
              Positioned(bottom: 12, left: 14, child: Container(width: 10, height: 4, decoration: BoxDecoration(color: const Color(0xFF60A5FA).withOpacity(0.5), borderRadius: BorderRadius.circular(4)))),
              Positioned(bottom: 12, right: 14, child: Container(width: 10, height: 4, decoration: BoxDecoration(color: const Color(0xFF60A5FA).withOpacity(0.5), borderRadius: BorderRadius.circular(4)))),
              Positioned(left: -6, top: 34, child: Container(width: 12, height: 18, decoration: BoxDecoration(color: const Color(0xFFC4B5FD), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white.withOpacity(0.7))))),
              Positioned(right: -6, top: 34, child: Container(width: 12, height: 18, decoration: BoxDecoration(color: const Color(0xFFC4B5FD), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white.withOpacity(0.7))))),
            ]),
          ),
          const SizedBox(height: 6),
          Container(
            width: 64,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF5F3FF), Color(0xFFDDD6FE)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.85)),
              boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 26, height: 4, decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.45), borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
              ]),
            ]),
          ),
        ]),
      ]),
      ),
    );
      },
    );
  }
}

class _FloatingDoc extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final double rotation;
  final bool small;
  const _FloatingDoc({required this.icon, required this.color, required this.label, required this.rotation, this.small = false});
  @override
  Widget build(BuildContext context) {
    final w = small ? 34.0 : 44.0;
    final h = small ? 38.0 : 48.0;
    return Transform.rotate(
      angle: rotation * math.pi / 180,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.9)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 6)), BoxShadow(color: color.withOpacity(0.25), blurRadius: 10)],
        ),
        child: Stack(children: [
          Positioned(
            top: 4,
            left: 6,
            right: 6,
            child: Container(
              height: 14,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
              child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900))),
            ),
          ),
          Center(child: Padding(padding: const EdgeInsets.only(top: 14), child: Icon(icon, color: color.withOpacity(0.9), size: small ? 14 : 18))),
          if (!small) ...[
            Positioned(bottom: 5, left: 6, right: 6, child: Container(height: 2, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)))),
            Positioned(bottom: 9, left: 6, right: 10, child: Container(height: 2, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)))),
          ],
        ]),
      ),
    );
  }
}

// ===========================================================================
// Quick Actions circles
// ===========================================================================

class _QuickCircle extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color glow;
  final VoidCallback onTap;
  const _QuickCircle({required this.icon, required this.label, required this.color, required this.glow, required this.onTap});
  @override
  State<_QuickCircle> createState() => _QuickCircleState();
}

class _QuickCircleState extends State<_QuickCircle> with SingleTickerProviderStateMixin {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 74,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF12172E),
                shape: BoxShape.circle,
                border: Border.all(color: widget.color.withOpacity(_down ? 0.85 : 0.55), width: 1.3),
                boxShadow: [
                  BoxShadow(color: widget.glow.withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 6)),
                  BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6)),
                ],
              ),
              child: Stack(children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [Colors.white.withOpacity(0.10), Colors.transparent], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                  ),
                ),
                Center(child: Icon(widget.icon, color: widget.color, size: 24)),
              ]),
            ),
            const SizedBox(height: 7),
            Text(widget.label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: -0.1)),
          ]),
        ),
      ),
    );
  }
}

// ===========================================================================
// AI Suggestions cards
// ===========================================================================

class _SuggestionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Gradient gradient;
  final Color borderColor;
  final VoidCallback onTap;
  const _SuggestionCard({required this.title, required this.icon, required this.gradient, required this.borderColor, required this.onTap});
  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 160),
        child: Container(
          width: 106,
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1330),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.borderColor, width: 1.1),
            boxShadow: [BoxShadow(color: widget.borderColor.withOpacity(0.18), blurRadius: 14, offset: const Offset(0, 6)), BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 8))],
            gradient: LinearGradient(colors: [const Color(0xFF0F1330), const Color(0xFF0F1330).withOpacity(0.96)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(gradient: widget.gradient, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: widget.borderColor.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Stack(children: [
                Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: [Colors.white.withOpacity(0.18), Colors.transparent])))),
                Center(child: Icon(widget.icon, color: Colors.white, size: 20)),
              ]),
            ),
            const SizedBox(height: 12),
            Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, height: 1.25, letterSpacing: -0.1)),
          ]),
        ),
      ),
    );
  }
}

// ===========================================================================
// Section header reusable
// ===========================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback? onTap;
  const _SectionHeader({required this.title, required this.actionLabel, this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w800, letterSpacing: -0.2),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(actionLabel, style: TextStyle(color: Colors.white.withOpacity(0.62), fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.62), size: 16),
          ]),
        ),
      ]),
    );
  }
}

class _SeeAll extends StatelessWidget {
  final VoidCallback? onTap;
  const _SeeAll({this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('See All', style: TextStyle(color: Colors.white.withOpacity(0.62), fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(width: 2),
        Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.62), size: 14),
      ]),
    );
  }
}

// ===========================================================================
// Recent Document row - glass style with badges
// ===========================================================================

class _RecentDocRowNew extends StatelessWidget {
  final DocumentItem doc;
  final VoidCallback onTap;
  const _RecentDocRowNew({required this.doc, required this.onTap});

  String _when(DateTime d) {
    final now = DateTime.now();
    final yday = now.subtract(const Duration(days: 1));
    final time = DateFormat('h:mm a').format(d);
    if (d.year == now.year && d.month == now.month && d.day == now.day) return 'Today  •  $time';
    if (d.year == yday.year && d.month == yday.month && d.day == yday.day) return 'Yesterday  •  $time';
    return '${DateFormat('MMM d').format(d)}  •  $time';
  }

  ({Color bg, Color fg, IconData icon, String label, String badge}) _type() {
    final n = doc.title.toLowerCase();
    if (n.endsWith('.docx') || n.endsWith('.doc')) {
      return (bg: const Color(0xFF1E3A8A), fg: const Color(0xFF60A5FA), icon: Icons.description_rounded, label: 'DOCX', badge: '');
    }
    if (n.endsWith('.jpg') || n.endsWith('.jpeg') || n.endsWith('.png')) {
      return (bg: const Color(0xFF3F2A12), fg: const Color(0xFFFB923C), icon: Icons.image_rounded, label: 'JPG', badge: 'OCR Ready');
    }
    return (bg: const Color(0xFF7F1D1D), fg: const Color(0xFFFCA5A5), icon: Icons.picture_as_pdf_rounded, label: 'PDF', badge: 'OCR Ready');
  }

  @override
  Widget build(BuildContext context) {
    final t = _type();
    final when = _when(doc.createdAt);
    final size = doc.fileSizeBytes > 0 ? '${(doc.fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB' : '2.3 MB';
    final badge = t.badge;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1330).withOpacity(0.88),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.30), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: t.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: t.fg.withOpacity(0.45)),
              ),
              child: Icon(t.icon, color: t.fg, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Expanded(child: Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13.2, fontWeight: FontWeight.w800, letterSpacing: -0.1))),
                  const SizedBox(width: 6),
                  Icon(doc.isFavorite ? Icons.star_rounded : Icons.star_border_rounded, color: doc.isFavorite ? const Color(0xFFFFC857) : Colors.white.withOpacity(0.35), size: 16),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  Flexible(child: Text('$when  •  $size', style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                  if (badge.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(badge, style: const TextStyle(color: Color(0xFF22C55E), fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ]),
              ]),
            ),
            const SizedBox(width: 6),
            Icon(Icons.more_vert_rounded, color: Colors.white.withOpacity(0.35), size: 18),
          ]),
        ),
      ),
    );
  }
}

// ===========================================================================
// Continue Working card
// ===========================================================================

class _ContinueWorkingCard extends StatelessWidget {
  final String docTitle;
  final double progress;
  final VoidCallback onContinue;
  const _ContinueWorkingCard({required this.docTitle, required this.progress, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1330).withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.32), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Text('Continue Working', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.88), fontSize: 13.5, fontWeight: FontWeight.w800, letterSpacing: -0.1)),
          ),
          Icon(Icons.more_horiz_rounded, color: Colors.white.withOpacity(0.35), size: 16),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: const Color(0xFF7F1D1D), borderRadius: BorderRadius.circular(9), border: Border.all(color: const Color(0xFFFCA5A5).withOpacity(0.35))),
            child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFFCA5A5), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(docTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12.8, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Stack(children: [
                Container(height: 6, decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(6))),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)]),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.45), blurRadius: 8)],
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                  child: Text('Last opened 2 min ago', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.48), fontSize: 10.5, fontWeight: FontWeight.w500)),
                ),
                Text('${(progress * 100).toInt()}%', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11, fontWeight: FontWeight.w800)),
              ]),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onContinue,
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Continue', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.18))),
                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ===========================================================================
// Cloud Sync card
// ===========================================================================

class _CloudSyncCard extends StatelessWidget {
  final VoidCallback onView;
  const _CloudSyncCard({required this.onView});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1330).withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.32), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: const Color(0xFF052E1A), borderRadius: BorderRadius.circular(9), border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.4))),
            child: const Icon(Icons.cloud_done_rounded, color: Color(0xFF22C55E), size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('Cloud Sync', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
              SizedBox(height: 2),
              Text('All files are backed up', style: TextStyle(color: Color(0xFF22C55E), fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
          Container(width: 22, height: 22, decoration: BoxDecoration(color: const Color(0xFF22C55E), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF0F1330), width: 2)), child: const Icon(Icons.check_rounded, color: Colors.white, size: 13)),
        ]),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _CloudIcon(color: const Color(0xFFFBBC05), icon: Icons.cloud_rounded),
          const SizedBox(width: 10),
          _CloudIcon(color: const Color(0xFF007EE5), icon: Icons.cloud_rounded),
          const SizedBox(width: 10),
          _CloudIcon(color: const Color(0xFF3B82F6), icon: Icons.cloud_rounded),
        ]),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: onView,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.08))),
              child: Text('View Details', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _CloudIcon extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _CloudIcon({required this.color, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(9), border: Border.all(color: Colors.white.withOpacity(0.07))),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// ===========================================================================
// Stats pills row
// ===========================================================================

class _StatsPillsRow extends StatelessWidget {
  final Map<String, int> counts;
  const _StatsPillsRow({required this.counts});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1330).withOpacity(0.74),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Expanded(child: _StatPill(icon: Icons.folder_copy_rounded, value: '${counts['docs'] ?? 158}', label: 'Documents', color: const Color(0xFF8B5CF6))),
        const SizedBox(width: 6),
        Expanded(child: _StatPill(icon: Icons.chat_bubble_rounded, value: '${counts['chats'] ?? 48}', label: 'AI Chats', color: const Color(0xFFA78BFA))),
        const SizedBox(width: 6),
        Expanded(child: _StatPill(icon: Icons.text_snippet_rounded, value: '${counts['scans'] ?? 312}', label: 'OCR Scans', color: const Color(0xFF22C55E))),
        const SizedBox(width: 6),
        Expanded(child: _StatPill(icon: Icons.cloud_rounded, value: '8.3 GB', label: 'Cloud Storage', color: const Color(0xFF3B82F6))),
      ]),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatPill({required this.icon, required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(13), border: Border.all(color: Colors.white.withOpacity(0.06))),
      child: Row(children: [
        Container(width: 28, height: 28, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(7), border: Border.all(color: color.withOpacity(0.35))), child: Icon(icon, color: color, size: 14)),
        const SizedBox(width: 7),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w900, letterSpacing: -0.2)),
            const SizedBox(height: 1),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.50), fontSize: 9.5, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

// ===========================================================================
// Bottom 4 mini cards — flexible height, no fixed height
// ===========================================================================

class _TodayScansCard extends StatelessWidget {
  final int count;
  const _TodayScansCard({required this.count});
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF140F2E).withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.22)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text("Today's Scans", style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 10.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('$count', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1)),
          const SizedBox(height: 2),
          Text('+4 from yesterday', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
        Positioned(right: 0, bottom: 6, child: SizedBox(width: 54, height: 22, child: CustomPaint(painter: _SparklinePainter()))),
      ]),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF8B5CF6)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    final pts = [0.7, 0.4, 0.6, 0.2, 0.45, 0.55, 0.3];
    for (int i = 0; i < pts.length; i++) {
      final x = size.width * i / (pts.length - 1);
      final y = size.height * pts[i];
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    canvas.drawPath(path, p);
    final glow = Paint()
      ..color = const Color(0xFF8B5CF6).withOpacity(0.35)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OcrAccuracyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F1A).withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.22)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('OCR Accuracy', style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 10.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('99%', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 22, fontWeight: FontWeight.w900, height: 1)),
            const SizedBox(height: 2),
            const Text('Excellent', style: TextStyle(color: Color(0xFF22C55E), fontSize: 10.5, fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          height: 44,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(width: 44, height: 44, child: CircularProgressIndicator(value: 0.99, strokeWidth: 3.2, backgroundColor: Colors.white.withOpacity(0.08), valueColor: const AlwaysStoppedAnimation(Color(0xFF22C55E)))),
            const Icon(Icons.check_rounded, color: Color(0xFF4ADE80), size: 14),
          ]),
        ),
      ]),
    );
  }
}

class _AiTokensCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172E).withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.22)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('AI Tokens', style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 10.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Unlimited', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 14, fontWeight: FontWeight.w900, height: 1)),
            const SizedBox(height: 4),
            Text('ScanX Pro', style: TextStyle(color: Colors.white.withOpacity(0.42), fontSize: 10, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(width: 6),
        const Text('∞', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 28, fontWeight: FontWeight.w300, height: 1)),
      ]),
    );
  }
}

class _DailyTipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1330).withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Container(width: 22, height: 22, decoration: BoxDecoration(color: const Color(0xFFfacc15).withOpacity(0.18), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFfacc15).withOpacity(0.35))), child: const Icon(Icons.lightbulb_rounded, color: Color(0xFFfacc15), size: 13)),
          const SizedBox(width: 6),
          const Text('Daily Tip', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 6),
        Text('Use AI Chat to ask questions directly from your PDF.', style: TextStyle(color: Colors.white.withOpacity(0.60), fontSize: 10.2, height: 1.45, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ===========================================================================
// Premium upgrade banner bottom
// ===========================================================================

class _PremiumUpgradeBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _PremiumUpgradeBanner({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(colors: [Color(0xFF1A1040), Color(0xFF1E1248), Color(0xFF0F0B2A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.35)),
          boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.22), blurRadius: 20, offset: const Offset(0, 8)), BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 360;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFFF8C00), Color(0xFFFFC857), Color(0xFFFFE08A)]),
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: [BoxShadow(color: const Color(0xFFFFC857).withOpacity(0.35), blurRadius: 10)],
                          ),
                          child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF2A1B00), size: 24),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Flexible(child: Text('Unlock Unlimited Power', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.72), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.2))),
                              const SizedBox(width: 4),
                              const Icon(Icons.auto_awesome_rounded, color: Color(0xFFC4B5FD), size: 10),
                            ]),
                            const SizedBox(height: 1),
                            Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                              const Text('Scan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                              ShaderMask(
                                shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFE879F9), Color(0xFF8B5CF6), Color(0xFF3B82F6)]).createShader(r),
                                child: const Text('X', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF8C00), Color(0xFFFFC857)]), borderRadius: BorderRadius.circular(6)),
                                child: const Text('PRO', style: TextStyle(color: Color(0xFF2A1B00), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
                              ),
                            ]),
                            const SizedBox(height: 4),
                            if (!isNarrow)
                              Wrap(spacing: 8, runSpacing: 4, children: const [
                                _MiniFeature(icon: Icons.all_inclusive_rounded, label: 'Unlimited AI'),
                                _MiniFeature(icon: Icons.text_snippet_rounded, label: 'Unlimited OCR'),
                                _MiniFeature(icon: Icons.cloud_rounded, label: 'Cloud\nBackup'),
                              ]),
                          ]),
                        ),
                        if (!isNarrow) ...[
                          const SizedBox(width: 8),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                            const Wrap(spacing: 8, children: [
                              _MiniFeature(icon: Icons.block_rounded, label: 'No Ads'),
                              _MiniFeature(icon: Icons.support_agent_rounded, label: 'Priority\nSupport'),
                            ]),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)]),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.35), blurRadius: 10)],
                              ),
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                Text('Upgrade Now', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 13),
                              ]),
                            ),
                          ]),
                        ],
                      ],
                    );
                  },
        ),
      ),
    );
  }
}

class _MiniFeature extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniFeature({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.08))),
        child: Icon(icon, color: Colors.white.withOpacity(0.85), size: 11),
      ),
      const SizedBox(height: 3),
      Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.58), fontSize: 7.5, fontWeight: FontWeight.w600, height: 1.1)),
    ]);
  }
}
