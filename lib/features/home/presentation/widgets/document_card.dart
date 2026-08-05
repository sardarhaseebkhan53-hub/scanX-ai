import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../models/document_item.dart';
import '../../../../widgets/ai_badge.dart';
import '../../../../widgets/secure_badge.dart';

class DocumentCard extends StatelessWidget {
  final DocumentItem document;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onDelete;
  final VoidCallback? onAIAnalyze;
  final VoidCallback? onToggleLock;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelectionToggle;
  final bool isSelectionMode;
  final bool isSelected;
  final String? matchingSnippet;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onDelete,
    this.onAIAnalyze,
    this.onToggleLock,
    this.onToggleArchive,
    this.onLongPress,
    this.onSelectionToggle,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.matchingSnippet,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(document.id),
      direction: isSelectionMode ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF5A78), Color(0xFFEF4444)]),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: isSelectionMode ? (onSelectionToggle ?? onTap) : onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    colors: isSelected
                        ? [const Color(0xFF242E5E), const Color(0xFF1A234A)]
                        : [const Color(0xFF151D3F), const Color(0xFF121A36)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isDark ? null : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryDark.withOpacity(0.6)
                  : isDark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.black.withOpacity(0.06),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: AppColors.primaryDark.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8))]
                : (isDark ? AppSpacing.cardShadowDark : AppSpacing.cardShadowLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (isSelectionMode) ...[
                    GestureDetector(
                      onTap: onSelectionToggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? AppColors.primaryDark : Colors.transparent,
                          border: Border.all(color: isSelected ? AppColors.primaryDark : Colors.white.withOpacity(0.22), width: 1.5),
                          boxShadow: isSelected
                              ? [BoxShadow(color: AppColors.primaryDark.withOpacity(0.4), blurRadius: 10)]
                              : null,
                        ),
                        child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  // Thumbnail with gradient
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.primaryGradient : AppColors.darkSurfaceGradient,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Stack(
                      children: [
                        Center(child: Icon(Icons.picture_as_pdf_rounded, color: isSelected ? Colors.white : AppColors.textSecondaryDark, size: 24)),
                        if (document.isLocked)
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(color: Color(0xFFFFC857), shape: BoxShape.circle),
                              child: const Icon(Icons.lock_rounded, size: 8, color: Colors.black),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                document.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 14.5),
                              ),
                            ),
                            if (document.isLocked) ...[
                              const SizedBox(width: 6),
                              const SecureBadge(),
                            ],
                            if (document.aiSummary != null && document.aiSummary!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: AppColors.aiGradient,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('AI', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              DateFormatter.formatRelative(document.createdAt),
                              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondaryDark, fontWeight: FontWeight.w500),
                            ),
                            Container(
                              width: 3,
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(color: AppColors.textSecondaryDark.withOpacity(0.5), shape: BoxShape.circle),
                            ),
                            Text(
                              '${document.pageCount} pgs',
                              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondaryDark),
                            ),
                            Container(
                              width: 3,
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(color: AppColors.textSecondaryDark.withOpacity(0.5), shape: BoxShape.circle),
                            ),
                            Text(
                              FileUtils.formatFileSize(document.fileSizeBytes),
                              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondaryDark),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isSelectionMode) ...[
                    IconButton(
                      icon: Icon(
                        document.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: document.isFavorite ? const Color(0xFFFFC857) : Colors.white.withOpacity(0.22),
                        size: 20,
                      ),
                      onPressed: onFavoriteToggle,
                      visualDensity: VisualDensity.compact,
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz_rounded, size: 18, color: Colors.white.withOpacity(0.4)),
                      color: const Color(0xFF1A2348),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.white.withOpacity(0.08))),
                      onSelected: (action) {
                        if (action == 'share') {
                          Share.share('ScanX AI Document: ${document.title}\nPage count: ${document.pageCount}', subject: document.title);
                        } else if (action == 'vault' && onToggleLock != null) {
                          onToggleLock!();
                        } else if (action == 'archive' && onToggleArchive != null) {
                          onToggleArchive!();
                        } else if (action == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share_rounded, size: 18, color: Colors.white70), SizedBox(width: 10), Text('Share', style: TextStyle(color: Colors.white)) ])),
                        PopupMenuItem(
                          value: 'vault',
                          child: Row(children: [Icon(document.isLocked ? Icons.lock_open_rounded : Icons.lock_person_rounded, size: 18, color: AppColors.neonPurple), const SizedBox(width: 10), Text(document.isLocked ? 'Unhide' : 'Hide in Vault', style: const TextStyle(color: Colors.white)) ]),
                        ),
                        const PopupMenuItem(value: 'archive', child: Row(children: [Icon(Icons.archive_rounded, size: 18, color: Color(0xFFFFC857)), SizedBox(width: 10), Text('Archive', style: TextStyle(color: Colors.white)) ])),
                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent), SizedBox(width: 10), Text('Move to Trash', style: TextStyle(color: Colors.redAccent)) ])),
                      ],
                    ),
                  ],
                ],
              ),
              if (document.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: document.tags.take(4).map((t) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryDark.withOpacity(0.22)),
                      ),
                      child: Text(
                        t.startsWith('#') ? t : '#$t',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF9BA3FF)),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (matchingSnippet != null && matchingSnippet!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC857).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFC857).withOpacity(0.18)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.saved_search_rounded, color: Color(0xFFFFC857), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(matchingSnippet!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Color(0xFFE8DCC0))),
                      ),
                    ],
                  ),
                ),
              ] else if (document.aiSummary != null && document.aiSummary!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.neonPurple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.neonPurple.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      const AIBadge(label: 'AI'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          document.aiSummary!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFFB8B5D0)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
