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

/// Home dashboard — greeting app bar, 2x2 quick actions, folders rail,
/// recent files list, floating gradient scan button, and a compact
/// 64px animated bottom nav. Built entirely with slivers so it scrolls as
/// one unit and never produces fixed-height overflow on small screens.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNavIndex = 0;

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBrowsing = homeState.isTrashView || homeState.isArchiveView || homeState.isSelectionMode;

    return Scaffold(
      extendBody: true,
      body: RefreshIndicator(
        onRefresh: () => homeController.loadData(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ---- Top App Bar: greeting, avatar, notifications, search ----
            SliverToBoxAdapter(
              child: isBrowsing
                  ? _BrowsingHeader(
                      homeState: homeState,
                      homeController: homeController,
                    )
                  : _GreetingHeader(greeting: _greeting),
            ),

            if (!isBrowsing)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, AppSpacing.lg),
                sliver: SliverToBoxAdapter(
                  child: AppSearchBar(
                    onChanged: homeController.setSearchQuery,
                    onFilterTap: () => _showSortModal(context, homeController, homeState.sortBy),
                  ),
                ),
              ),

            // ---- Quick Actions 2x2 grid ----
            if (!isBrowsing) ...[
              const SliverToBoxAdapter(
                child: SectionHeader(title: 'Quick Actions'),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, AppSpacing.md, 20, AppSpacing.sm),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.5,
                  ),
                  delegate: SliverChildListDelegate([
                    ActionButton(
                      label: 'Scan Document',
                      subtitle: 'Camera capture',
                      icon: Icons.document_scanner_rounded,
                      gradient: AppColors.primaryGradient,
                      onTap: () => context.push(RouteNames.scanner),
                    ),
                    ActionButton(
                      label: 'Import PDF',
                      subtitle: 'From device',
                      icon: Icons.file_upload_rounded,
                      gradient: AppColors.cyanGradient,
                      onTap: () => context.push(RouteNames.pdfTools),
                    ),
                    ActionButton(
                      label: 'QR Toolkit',
                      subtitle: 'Scan & generate',
                      icon: Icons.qr_code_2_rounded,
                      gradient: AppColors.emeraldGradient,
                      onTap: () => context.push(RouteNames.qrDashboard),
                    ),
                    ActionButton(
                      label: 'AI Assistant',
                      subtitle: 'Ask, summarize',
                      icon: Icons.auto_awesome_rounded,
                      gradient: AppColors.purpleGradient,
                      onTap: () => context.push(RouteNames.aiAssistant),
                    ),
                  ]),
                ),
              ),
            ],

            // ---- Folders rail ----
            if (!isBrowsing) ...[
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: homeState.selectedFolderId != null ? 'Sub-Folders' : 'Folders',
                  actionLabel: 'New folder',
                  onActionTap: () => _showCreateFolderDialog(
                    context,
                    homeController,
                    homeState.selectedFolderId,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 128,
                  child: homeState.folders.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'No folders yet',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: homeState.folders.length,
                          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final folder = homeState.folders[index];
                            final count =
                                homeState.documents.where((d) => d.folderId == folder.id).length;
                            return FolderCard(
                              folder: folder,
                              itemCount: count,
                              onTap: () => homeController.selectFolder(folder.id),
                            );
                          },
                        ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
            ],

            // ---- Recent files / trash / archive header ----
            SliverToBoxAdapter(
              child: SectionHeader(
                title: homeState.isTrashView
                    ? 'Trashed Files'
                    : homeState.isArchiveView
                        ? 'Archived Documents'
                        : 'Recent Files',
                actionLabel: homeState.isTrashView && homeState.documents.isNotEmpty
                    ? 'Empty trash'
                    : (!homeState.isTrashView && !homeState.isArchiveView ? null : null),
                onActionTap: homeState.isTrashView && homeState.documents.isNotEmpty
                    ? () => homeController.emptyTrash()
                    : null,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xs)),

            if (homeState.isLoading)
              const SliverToBoxAdapter(child: SkeletonLoader())
            else if (homeState.documents.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateWidget(
                  title: homeState.isTrashView
                      ? 'Trash is Empty'
                      : homeState.isArchiveView
                          ? 'Archive is Empty'
                          : 'No Documents Yet',
                  subtitle: homeState.isTrashView
                      ? 'Deleted files will appear here until permanently removed.'
                      : homeState.isArchiveView
                          ? 'Archived documents will appear here safely out of your main dashboard.'
                          : 'Tap the scan button below to capture your first document with AI auto-enhancement and ML Kit OCR.',
                  buttonText: (homeState.isTrashView || homeState.isArchiveView) ? null : 'Scan Document',
                  onButtonPressed: (homeState.isTrashView || homeState.isArchiveView)
                      ? null
                      : () => context.push(RouteNames.scanner),
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
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    doc.isLocked
                                        ? 'Removed "${doc.title}" from Hidden Vault'
                                        : 'Moved "${doc.title}" to Hidden Vault (AES-256 shielded)',
                                  ),
                                ),
                              );
                            },
                            onToggleArchive: () {
                              homeController.toggleArchive(doc);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    doc.isArchived
                                        ? 'Unarchived "${doc.title}"'
                                        : 'Archived "${doc.title}" to Archive Vault',
                                  ),
                                ),
                              );
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

            SliverToBoxAdapter(
              child: PremiumBanner(onTap: () => context.push(RouteNames.premiumPaywall)),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sort Documents By', style: Theme.of(ctx).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.md),
              RadioListTile<String>(
                title: const Text('Date Created (Newest First)'),
                value: 'date',
                groupValue: currentSort,
                onChanged: (val) {
                  if (val != null) {
                    controller.setSortBy(val);
                    Navigator.of(ctx).pop();
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Title (A-Z)'),
                value: 'title',
                groupValue: currentSort,
                onChanged: (val) {
                  if (val != null) {
                    controller.setSortBy(val);
                    Navigator.of(ctx).pop();
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('File Size (Largest First)'),
                value: 'size',
                groupValue: currentSort,
                onChanged: (val) {
                  if (val != null) {
                    controller.setSortBy(val);
                    Navigator.of(ctx).pop();
                  }
                },
              ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Text(parentId != null ? 'Create Nested Sub-Folder' : 'Create New Folder'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Folder Name (e.g. Invoices 2026)'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                controller.createFolder(nameController.text.trim(), '#3B82F6', parentId: parentId);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

/// Greeting bar shown on the primary dashboard view.
class _GreetingHeader extends StatelessWidget {
  final String greeting;
  const _GreetingHeader({required this.greeting});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.65),
                  ),
                ),
                Text(
                  'Haseeb',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.displayMedium,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 2),
          CircleAvatar(
            radius: 19,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
            child: Text(
              'H',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header shown while browsing Trash / Archive / multi-select mode.
class _BrowsingHeader extends StatelessWidget {
  final HomeState homeState;
  final HomeController homeController;
  const _BrowsingHeader({required this.homeState, required this.homeController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String title = 'Documents';
    if (homeState.isSelectionMode) {
      title = '${homeState.selectedDocIds.length} Selected';
    } else if (homeState.isTrashView) {
      title = 'Trash';
    } else if (homeState.isArchiveView) {
      title = 'Archive Vault';
    } else if (homeState.selectedFolderId != null) {
      title = 'Folder';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              if (homeState.isSelectionMode) {
                homeController.toggleSelectionMode(false);
              } else if (homeState.isTrashView) {
                homeController.toggleTrashView();
              } else if (homeState.isArchiveView) {
                homeController.toggleArchiveView();
              } else {
                homeController.selectFolder(null);
              }
            },
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineMedium,
            ),
          ),
          if (homeState.isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all_rounded),
              tooltip: 'Select All',
              onPressed: () => homeController.selectAllDocuments(),
            ),
            IconButton(
              icon: const Icon(Icons.archive_rounded, color: Color(0xFFF59E0B)),
              tooltip: 'Archive Selected',
              onPressed: () => homeController.batchArchiveSelected(),
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444)),
              tooltip: 'Delete Selected',
              onPressed: () => homeController.batchDeleteSelected(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Center-docked scan button — blue gradient with a soft glow.
class _ScanFab extends StatelessWidget {
  final VoidCallback onTap;
  const _ScanFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'scan-fab',
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          boxShadow: AppSpacing.glowShadowBlue,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}

/// Compact 64px bottom navigation bar with animated selection pill.
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final VoidCallback onHomeTap;
  final VoidCallback onPdfTap;
  final VoidCallback onAiTap;
  final VoidCallback onSettingsTap;

  const _BottomNav({
    required this.currentIndex,
    required this.onHomeTap,
    required this.onPdfTap,
    required this.onAiTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 8)),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.16),
          width: 1.2,
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Home', selected: currentIndex == 0, onTap: onHomeTap),
              _NavItem(icon: Icons.picture_as_pdf_rounded, label: 'PDF Tools', selected: false, onTap: onPdfTap),
              const SizedBox(width: 48), // reserved space under the docked FAB
              _NavItem(icon: Icons.auto_awesome_rounded, label: 'AI', selected: false, onTap: onAiTap),
              _NavItem(icon: Icons.settings_rounded, label: 'Settings', selected: false, onTap: onSettingsTap),
            ],
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
    final color = selected ? Theme.of(context).colorScheme.primary : Colors.grey;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 10.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
