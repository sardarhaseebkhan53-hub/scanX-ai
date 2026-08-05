import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/action_button.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/premium_banner.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../controllers/home_controller.dart';
import '../widgets/document_card.dart';
import '../widgets/folder_card.dart';

/// Ultra-premium dark luxury Home dashboard
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  late AnimationController _orbController;

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

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final homeController = ref.read(homeProvider.notifier);
    final isBrowsing = homeState.isTrashView || homeState.isArchiveView || homeState.isSelectionMode;

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Luxury ambient background orbs
          Positioned.fill(
            child: Stack(
              children: [
                Positioned(
                  top: -120,
                  left: -80,
                  child: AnimatedBuilder(
                    animation: _orbController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(10 * _orbController.value, 0),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 340,
                      height: 340,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [AppColors.primaryDark.withOpacity(0.22), AppColors.primaryDark.withOpacity(0)],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 80,
                  right: -80,
                  child: Container(
                    width: 380,
                    height: 380,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [AppColors.secondaryDark.withOpacity(0.18), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 320,
                  right: 60,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [AppColors.neonCyan.withOpacity(0.10), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          RefreshIndicator(
            onRefresh: () => homeController.loadData(),
            color: AppColors.primaryDark,
            backgroundColor: AppColors.surfaceDark,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: isBrowsing
                      ? _BrowsingHeader(homeState: homeState, homeController: homeController)
                      : _GreetingHeader(greeting: _greeting, docCount: homeState.documents.length),
                ),
                if (!isBrowsing)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Column(
                        children: [
                          AppSearchBar(
                            onChanged: homeController.setSearchQuery,
                            onFilterTap: () => _showSortModal(context, homeController, homeState.sortBy),
                          ),
                          const SizedBox(height: 14),
                          _StatsRow(docs: homeState.documents.length),
                        ],
                      ),
                    ),
                  ),

                if (!isBrowsing) ...[
                  const SliverToBoxAdapter(child: SectionHeader(title: 'Quick Actions', icon: Icons.bolt_rounded)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.48,
                      ),
                      delegate: SliverChildListDelegate([
                        ActionButton(
                          label: 'Smart Scanner',
                          subtitle: 'AI edge detection',
                          icon: Icons.document_scanner_rounded,
                          gradient: AppColors.scannerGradient,
                          onTap: () => context.push(RouteNames.scanner),
                        ),
                        ActionButton(
                          label: 'Import & PDF',
                          subtitle: 'Merge, split, compress',
                          icon: Icons.picture_as_pdf_rounded,
                          gradient: AppColors.cyanGradient,
                          onTap: () => context.push(RouteNames.pdfTools),
                        ),
                        ActionButton(
                          label: 'QR Studio',
                          subtitle: 'Scan & generate',
                          icon: Icons.qr_code_2_rounded,
                          gradient: AppColors.emeraldGradient,
                          onTap: () => context.push(RouteNames.qrDashboard),
                        ),
                        ActionButton(
                          label: 'AI Intelligence',
                          subtitle: 'Chat, summary, OCR',
                          icon: Icons.auto_awesome_rounded,
                          gradient: AppColors.aiGradient,
                          onTap: () => context.push(RouteNames.aiAssistant),
                        ),
                      ]),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _AIToolsStrip(onTap: (title) {
                        if (title == 'OCR') context.push(RouteNames.pdfTools);
                        else context.push(RouteNames.aiAssistant);
                      }),
                    ),
                  ),
                ],

                if (!isBrowsing) ...[
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      title: homeState.selectedFolderId != null ? 'Sub-Folders' : 'Smart Folders',
                      actionLabel: 'New',
                      onActionTap: () => _showCreateFolderDialog(context, homeController, homeState.selectedFolderId),
                      icon: Icons.folder_special_rounded,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 112,
                      child: homeState.folders.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                                ),
                                child: Center(
                                  child: Text('No folders yet — tap New to organize', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                                ),
                              ),
                            )
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: homeState.folders.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final folder = homeState.folders[index];
                                final count = homeState.documents.where((d) => d.folderId == folder.id).length;
                                return FolderCard(folder: folder, itemCount: count, onTap: () => homeController.selectFolder(folder.id));
                              },
                            ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                ],

                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: homeState.isTrashView
                        ? 'Trash'
                        : homeState.isArchiveView
                            ? 'Archive Vault'
                            : 'Recent Documents',
                    actionLabel: homeState.documents.isNotEmpty ? '${homeState.documents.length} items' : null,
                    icon: Icons.history_rounded,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 6)),

                if (homeState.isLoading)
                  const SliverToBoxAdapter(child: SkeletonLoader())
                else if (homeState.documents.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateWidget(
                      title: homeState.isTrashView
                          ? 'Trash is Empty'
                          : homeState.isArchiveView
                              ? 'Archive Vault Empty'
                              : 'No Documents Yet',
                      subtitle: homeState.isTrashView
                          ? 'Deleted files will appear here until permanently removed.'
                          : homeState.isArchiveView
                              ? 'Archived documents stay safe here.'
                              : 'Capture your first document with AI auto-enhancement, edge detection and ML Kit OCR.',
                      buttonText: (homeState.isTrashView || homeState.isArchiveView) ? null : 'Start Scanning',
                      onButtonPressed: (homeState.isTrashView || homeState.isArchiveView) ? null : () => context.push(RouteNames.scanner),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final doc = homeState.documents[index];
                          final isSelected = homeState.selectedDocIds.contains(doc.id);
                          String? snippet;
                          if (homeState.searchQuery.trim().isNotEmpty && doc.ocrText != null) {
                            final query = homeState.searchQuery.trim().toLowerCase();
                            final textLower = doc.ocrText!.toLowerCase();
                            final idx = textLower.indexOf(query);
                            if (idx != -1) {
                              final start = (idx - 25).clamp(0, doc.ocrText!.length);
                              final end = (idx + query.length + 55).clamp(0, doc.ocrText!.length);
                              snippet = '"...${doc.ocrText!.substring(start, end).replaceAll('\n', ' ')}..."';
                            }
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: RepaintBoundary(
                              child: DocumentCard(
                                document: doc,
                                matchingSnippet: snippet,
                                isSelectionMode: homeState.isSelectionMode,
                                isSelected: isSelected,
                                onSelectionToggle: () => homeController.toggleDocSelection(doc.id),
                                onLongPress: () {
                                  homeController.toggleSelectionMode(true);
                                  homeController.toggleDocSelection(doc.id);
                                },
                                onTap: () {
                                  if (homeState.isSelectionMode) {
                                    homeController.toggleDocSelection(doc.id);
                                  } else {
                                    context.push(RouteNames.ocrViewer, extra: doc.id);
                                  }
                                },
                                onFavoriteToggle: () => homeController.toggleFavorite(doc),
                                onToggleLock: () {
                                  homeController.toggleLock(doc);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(doc.isLocked ? 'Removed from Vault' : 'Secured in Vault'), backgroundColor: const Color(0xFF1A2348)));
                                },
                                onToggleArchive: () {
                                  homeController.toggleArchive(doc);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(doc.isArchived ? 'Unarchived' : 'Archived'), backgroundColor: const Color(0xFF1A2348)));
                                },
                                onDelete: () => homeController.deleteDocument(doc.id),
                              ),
                            ),
                          );
                        },
                        childCount: homeState.documents.length,
                      ),
                    ),
                  ),

                SliverToBoxAdapter(child: PremiumBanner(onTap: () => context.push(RouteNames.premiumPaywall))),
                const SliverToBoxAdapter(child: SizedBox(height: 140)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _ScanFab(onTap: () => context.push(RouteNames.scanner)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentNavIndex,
        onHomeTap: () => setState(() => _currentNavIndex = 0),
        onPdfTap: () => context.push(RouteNames.pdfTools),
        onAiTap: () => context.push(RouteNames.aiAssistant),
        onSettingsTap: () => context.push(RouteNames.settings),
      ),
    );
  }

  void _showSortModal(BuildContext context, HomeController controller, String currentSort) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)), side: BorderSide(color: Colors.white.withOpacity(0.06))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 18),
              Text('Sort Documents', style: Theme.of(ctx).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _SortOption(title: 'Date Created', subtitle: 'Newest first', value: 'date', group: currentSort, icon: Icons.schedule_rounded, onTap: (v) { controller.setSortBy(v); Navigator.pop(ctx); }),
              _SortOption(title: 'Title', subtitle: 'A-Z alphabetical', value: 'title', group: currentSort, icon: Icons.sort_by_alpha_rounded, onTap: (v) { controller.setSortBy(v); Navigator.pop(ctx); }),
              _SortOption(title: 'File Size', subtitle: 'Largest first', value: 'size', group: currentSort, icon: Icons.data_usage_rounded, onTap: (v) { controller.setSortBy(v); Navigator.pop(ctx); }),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context, HomeController controller, String? parentId) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl), side: BorderSide(color: Colors.white.withOpacity(0.08))),
        title: Text(parentId != null ? 'Create Sub-Folder' : 'New Smart Folder', style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Invoices 2026, Passports',
                hintStyle: TextStyle(color: AppColors.textSecondaryDark),
                filled: true,
                fillColor: const Color(0xFF151D3F),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primaryDark, width: 1.5)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark))),
          Container(
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  controller.createFolder(nameController.text.trim(), '#7C5CFF', parentId: parentId);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final String title, subtitle, value, group;
  final IconData icon;
  final Function(String) onTap;
  const _SortOption({required this.title, required this.subtitle, required this.value, required this.group, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = value == group;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark.withOpacity(0.15) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primaryDark.withOpacity(0.4) : Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(gradient: selected ? AppColors.primaryGradient : null, color: selected ? null : Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: selected ? Colors.white : AppColors.textSecondaryDark, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)), Text(subtitle, style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11.5))])),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primaryDark, size: 20),
          ],
        ),
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  final String greeting;
  final int docCount;
  const _GreetingHeader({required this.greeting, required this.docCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(greeting, style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.2)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(gradient: AppColors.aiGradient, borderRadius: BorderRadius.circular(20)),
                      child: const Row(children: [Icon(Icons.bolt_rounded, size: 10, color: Colors.white), SizedBox(width: 2), Text('AI ON', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Haseeb', style: theme.textTheme.displayMedium?.copyWith(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                const SizedBox(height: 2),
                Text('$docCount documents • Secured & private', style: TextStyle(color: AppColors.textSecondaryDark.withOpacity(0.9), fontSize: 12)),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Icon(Icons.notifications_none_rounded, color: Colors.white.withOpacity(0.8), size: 20),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [BoxShadow(color: AppColors.primaryDark.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF151D3F),
              child: Text('H', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int docs;
  const _StatsRow({required this.docs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(icon: Icons.description_rounded, label: 'Docs', value: '$docs', gradient: AppColors.primaryGradient)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(icon: Icons.auto_awesome_rounded, label: 'AI Scans', value: '${(docs * 1.8).toInt()}', gradient: AppColors.aiGradient)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(icon: Icons.cloud_done_rounded, label: 'Synced', value: '100%', gradient: AppColors.cyanGradient)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Gradient gradient;
  const _StatCard({required this.icon, required this.label, required this.value, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF151D3F), Color(0xFF121A36)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: Colors.white, size: 16)),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
            Text(label, style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 10.5, fontWeight: FontWeight.w500)),
          ]),
        ],
      ),
    );
  }
}

class _AIToolsStrip extends StatelessWidget {
  final Function(String) onTap;
  const _AIToolsStrip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tools = [
      {'label': 'OCR', 'icon': Icons.text_fields_rounded, 'color': AppColors.primaryGradient},
      {'label': 'Summary', 'icon': Icons.summarize_rounded, 'color': AppColors.aiGradient},
      {'label': 'Chat Doc', 'icon': Icons.chat_bubble_rounded, 'color': AppColors.purpleGradient},
      {'label': 'Translate', 'icon': Icons.translate_rounded, 'color': AppColors.cyanGradient},
      {'label': 'Protect', 'icon': Icons.shield_rounded, 'color': AppColors.goldGradient},
    ];

    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tools.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final t = tools[i];
          return GestureDetector(
            onTap: () => onTap(t['label'] as String),
            child: Container(
              width: 68,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(gradient: t['color'] as Gradient, borderRadius: BorderRadius.circular(9)),
                    child: Icon(t['icon'] as IconData, color: Colors.white, size: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(t['label'] as String, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BrowsingHeader extends StatelessWidget {
  final HomeState homeState;
  final HomeController homeController;
  const _BrowsingHeader({required this.homeState, required this.homeController});

  @override
  Widget build(BuildContext context) {
    String title = 'Documents';
    if (homeState.isSelectionMode) title = '${homeState.selectedDocIds.length} Selected';
    else if (homeState.isTrashView) title = 'Trash';
    else if (homeState.isArchiveView) title = 'Archive Vault';
    else if (homeState.selectedFolderId != null) title = 'Folder';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 12, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.10))),
            child: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white), onPressed: () {
              if (homeState.isSelectionMode) homeController.toggleSelectionMode(false);
              else if (homeState.isTrashView) homeController.toggleTrashView();
              else if (homeState.isArchiveView) homeController.toggleArchiveView();
              else homeController.selectFolder(null);
            }),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))),
          if (homeState.isSelectionMode) ...[
            IconButton(icon: const Icon(Icons.select_all_rounded, color: Colors.white70), onPressed: () => homeController.selectAllDocuments()),
            Container(
              decoration: BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
              child: IconButton(icon: const Icon(Icons.archive_rounded, color: Colors.black, size: 18), onPressed: () => homeController.batchArchiveSelected()),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFF5A78), Color(0xFFEF4444)]), shape: BoxShape.circle),
              child: IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 18), onPressed: () => homeController.batchDeleteSelected()),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScanFab extends StatefulWidget {
  final VoidCallback onTap;
  const _ScanFab({required this.onTap});

  @override
  State<_ScanFab> createState() => _ScanFabState();
}

class _ScanFabState extends State<_ScanFab> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            return Container(
              width: 74 + 14 * _pulse.value,
              height: 74 + 14 * _pulse.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryDark.withOpacity(0.18 - 0.12 * _pulse.value),
              ),
            );
          },
        ),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.scannerGradient,
            boxShadow: [
              BoxShadow(color: AppColors.primaryDark.withOpacity(0.45), blurRadius: 22, offset: const Offset(0, 8)),
              BoxShadow(color: AppColors.neonCyan.withOpacity(0.25), blurRadius: 32, offset: const Offset(0, 12)),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onTap,
              child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final VoidCallback onHomeTap;
  final VoidCallback onPdfTap;
  final VoidCallback onAiTap;
  final VoidCallback onSettingsTap;

  const _BottomNav({required this.currentIndex, required this.onHomeTap, required this.onPdfTap, required this.onAiTap, required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF101735).withOpacity(0.92),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 28, offset: const Offset(0, 12))],
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded, label: 'Home', selected: currentIndex == 0, onTap: onHomeTap),
                _NavItem(icon: Icons.picture_as_pdf_rounded, label: 'PDF Tools', selected: false, onTap: onPdfTap),
                const SizedBox(width: 52),
                _NavItem(icon: Icons.auto_awesome_rounded, label: 'AI Chat', selected: false, onTap: onAiTap),
                _NavItem(icon: Icons.settings_rounded, label: 'Settings', selected: false, onTap: onSettingsTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.primaryDark.withOpacity(0.35) : Colors.transparent, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? Colors.white : AppColors.textSecondaryDark, size: 20),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondaryDark, fontSize: 10, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
