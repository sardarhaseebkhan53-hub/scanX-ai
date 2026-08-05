import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/smart_categories.dart';
import '../../../../shared/widgets/app_search_bar.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../controllers/home_controller.dart';
import '../widgets/document_card.dart';
import '../widgets/folder_card.dart';

/// Smart File Manager — every document, folder, tag, favorite, vault item,
/// archive and the trash, with search, sorting and batch operations.
class AllDocumentsScreen extends ConsumerStatefulWidget {
  final String? initialFilter;
  const AllDocumentsScreen({super.key, this.initialFilter});

  @override
  ConsumerState<AllDocumentsScreen> createState() => _AllDocumentsScreenState();
}

class _AllDocumentsScreenState extends ConsumerState<AllDocumentsScreen> {
  late String _filter;

  static const List<String> _filters = ['All', 'Work', 'Study', 'Personal', 'Others', 'Favorites', 'Vault', 'Archive', 'Trash'];

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter ?? 'All';
  }

  @override
  void didUpdateWidget(covariant AllDocumentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilter != null && widget.initialFilter != oldWidget.initialFilter) {
      setState(() => _filter = widget.initialFilter!);
    }
  }

  void _setFilter(String f) {
    final controller = ref.read(documentsBrowserProvider.notifier);
    final st = ref.read(documentsBrowserProvider);
    if (f == 'Trash' && !st.isTrashView) controller.toggleTrashView();
    if (f != 'Trash' && st.isTrashView) controller.toggleTrashView();
    if (f == 'Archive' && !st.isArchiveView) controller.toggleArchiveView();
    if (f != 'Archive' && st.isArchiveView) controller.toggleArchiveView();
    if (st.isSelectionMode) controller.toggleSelectionMode(false);
    setState(() => _filter = f);
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(documentsBrowserProvider);
    final controller = ref.read(documentsBrowserProvider.notifier);

    var docs = st.documents;
    if (_filter == 'Favorites') docs = docs.where((d) => d.isFavorite).toList();
    if (_filter == 'Vault') docs = docs.where((d) => d.isLocked).toList();
    if (SmartCategories.names.contains(_filter)) docs = SmartCategories.filter(docs, _filter);

    final showFolders = (_filter == 'All' || SmartCategories.names.contains(_filter)) && !st.isTrashView && !st.isArchiveView;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          st.isSelectionMode ? '${st.selectedDocIds.length} Selected' : (_filter == 'All' ? 'All Documents' : _filter),
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.6),
                        ),
                        const SizedBox(height: 2),
                        Text('${docs.length} item${docs.length == 1 ? '' : 's'} • Smart File Manager', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11.5)),
                      ],
                    ),
                  ),
                  if (st.isSelectionMode) ...[
                    IconButton(icon: const Icon(Icons.select_all_rounded, color: Colors.white70, size: 20), onPressed: () => controller.selectAllDocuments()),
                    const SizedBox(width: 4),
                    _BatchButton(icon: Icons.merge_rounded, color: AppColors.neonCyan, onTap: () async {
                      final id = await controller.batchMergeSelected();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(id == null ? 'Select at least 2 documents to merge' : 'Documents merged into one PDF'),
                          backgroundColor: const Color(0xFF151D3F),
                          action: id == null ? null : SnackBarAction(label: 'VIEW', textColor: AppColors.neonCyan, onPressed: () => context.push(RouteNames.ocrViewer, extra: id)),
                        ));
                      }
                    }),
                    const SizedBox(width: 6),
                    _BatchButton(icon: Icons.lock_rounded, color: AppColors.neonPurple, onTap: () async {
                      await controller.batchLockSelected();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Secured in AES-256 Hidden Vault'), backgroundColor: Color(0xFF151D3F)));
                    }),
                    const SizedBox(width: 6),
                    _BatchButton(icon: Icons.archive_rounded, color: AppColors.neonAmber, onTap: () async {
                      await controller.batchArchiveSelected();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Archived to Archive Vault'), backgroundColor: Color(0xFF151D3F)));
                    }),
                    const SizedBox(width: 6),
                    _BatchButton(icon: Icons.delete_sweep_rounded, color: AppColors.error, onTap: () async {
                      await controller.batchDeleteSelected();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'), backgroundColor: Color(0xFF151D3F)));
                    }),
                    const SizedBox(width: 6),
                    GestureDetector(onTap: () => controller.toggleSelectionMode(false), child: Container(width: 34, height: 34, decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white70, size: 16))),
                  ] else
                    GestureDetector(
                      onTap: () => _showCreateFolderDialog(controller),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.create_new_folder_rounded, color: Colors.white, size: 16), SizedBox(width: 6), Text('New Folder', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700))]),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
              child: AppSearchBar(onChanged: controller.setSearchQuery, onFilterTap: () => _showSortModal(controller, st.sortBy)),
            ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final f = _filters[i];
                  final sel = f == _filter;
                  return GestureDetector(
                    onTap: () => _setFilter(f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: sel ? AppColors.brandGradient : null,
                        color: sel ? null : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? Colors.transparent : Colors.white.withOpacity(0.09)),
                      ),
                      child: Text(f, style: TextStyle(color: sel ? Colors.white : AppColors.textSecondaryDark, fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryDark,
                backgroundColor: AppColors.surfaceDark,
                onRefresh: () => controller.loadData(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    if (showFolders) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 2),
                          child: Text('Folders', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: st.folders.isEmpty ? 0 : 112,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                            itemCount: st.folders.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final folder = st.folders[index];
                              final count = st.documents.where((d) => d.folderId == folder.id).length;
                              return FolderCard(folder: folder, itemCount: count, onTap: () => controller.selectFolder(folder.id));
                            },
                          ),
                        ),
                      ),
                    ],
                    if (st.isLoading)
                      const SliverToBoxAdapter(child: SkeletonLoader())
                    else if (docs.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyStateWidget(
                          title: _filter == 'Trash' ? 'Trash is Empty' : (_filter == 'Vault' ? 'Vault is Empty' : 'Nothing Here'),
                          subtitle: _filter == 'Trash'
                              ? 'Deleted files will appear here until permanently removed.'
                              : 'Documents matching this view will appear here.',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final doc = docs[index];
                              final isSelected = st.selectedDocIds.contains(doc.id);
                              String? snippet;
                              if (st.searchQuery.trim().isNotEmpty && doc.ocrText != null) {
                                final q = st.searchQuery.trim().toLowerCase();
                                final tl = doc.ocrText!.toLowerCase();
                                final idx = tl.indexOf(q);
                                if (idx != -1) {
                                  final s = (idx - 25).clamp(0, doc.ocrText!.length);
                                  final e = (idx + q.length + 55).clamp(0, doc.ocrText!.length);
                                  snippet = '"...${doc.ocrText!.substring(s, e).replaceAll('\n', ' ')}..."';
                                }
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: DocumentCard(
                                  document: doc,
                                  matchingSnippet: snippet,
                                  isSelectionMode: st.isSelectionMode,
                                  isSelected: isSelected,
                                  onSelectionToggle: () => controller.toggleDocSelection(doc.id),
                                  onLongPress: () {
                                    controller.toggleSelectionMode(true);
                                    controller.toggleDocSelection(doc.id);
                                  },
                                  onTap: () {
                                    if (st.isSelectionMode) {
                                      controller.toggleDocSelection(doc.id);
                                    } else if (st.isTrashView) {
                                      controller.restoreDocument(doc.id);
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document restored'), backgroundColor: Color(0xFF151D3F)));
                                    } else {
                                      context.push(RouteNames.ocrViewer, extra: doc.id);
                                    }
                                  },
                                  onFavoriteToggle: () => controller.toggleFavorite(doc),
                                  onToggleLock: () => controller.toggleLock(doc),
                                  onToggleArchive: () => controller.toggleArchive(doc),
                                  onDelete: () => controller.deleteDocument(doc.id),
                                ),
                              );
                            },
                            childCount: docs.length,
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 110)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortModal(HomeController controller, String currentSort) {
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
              const Text('Sort Documents', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              ...[
                {'t': 'Date Created', 's': 'Newest first', 'v': 'date', 'i': Icons.schedule_rounded},
                {'t': 'Title', 's': 'A-Z alphabetical', 'v': 'title', 'i': Icons.sort_by_alpha_rounded},
                {'t': 'File Size', 's': 'Largest first', 'v': 'size', 'i': Icons.data_usage_rounded},
              ].map((o) => GestureDetector(
                    onTap: () {
                      controller.setSortBy(o['v'] as String);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: currentSort == o['v'] ? AppColors.primaryDark.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: currentSort == o['v'] ? AppColors.primaryDark.withOpacity(0.4) : Colors.white.withOpacity(0.06)),
                      ),
                      child: Row(
                        children: [
                          Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(10)), child: Icon(o['i'] as IconData, color: AppColors.textSecondaryDark, size: 18)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(o['t'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)), Text(o['s'] as String, style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11.5))])),
                          if (currentSort == o['v']) const Icon(Icons.check_circle_rounded, color: AppColors.primaryDark, size: 20),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateFolderDialog(HomeController controller) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl), side: BorderSide(color: Colors.white.withOpacity(0.08))),
        title: const Text('New Smart Folder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: TextField(
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
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primaryDark, width: 1.5)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark))),
          Container(
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  controller.createFolder(nameController.text.trim(), '#7C5CFF');
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

class _BatchButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _BatchButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: color.withOpacity(0.16), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.4))),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
