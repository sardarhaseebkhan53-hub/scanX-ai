import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: Key(document.id),
      direction: isSelectionMode ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: isSelectionMode
            ? (onSelectionToggle ?? onTap)
            : onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withOpacity(0.08)
                : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : Colors.grey.withOpacity(0.15),
              width: isSelected ? 2.2 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox if Selection Mode
                  if (isSelectionMode) ...[
                    IconButton(
                      icon: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: isSelected ? colorScheme.primary : Colors.grey,
                      ),
                      onPressed: onSelectionToggle,
                    ),
                    const SizedBox(width: 4),
                  ] else ...[
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.picture_as_pdf_rounded,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
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
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (document.isLocked) ...[
                              const SizedBox(width: 4),
                              const SecureBadge(),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              DateFormatter.formatRelative(document.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                              ),
                            ),
                            const Text(' • '),
                            Text(
                              '${document.pageCount} ${document.pageCount == 1 ? 'page' : 'pages'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                              ),
                            ),
                            const Text(' • '),
                            Text(
                              FileUtils.formatFileSize(document.fileSizeBytes),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isSelectionMode)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            document.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                            color: document.isFavorite ? Colors.amber : Colors.grey,
                          ),
                          onPressed: onFavoriteToggle,
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded),
                          onSelected: (action) {
                            if (action == 'share') {
                              Share.share(
                                'ScanX AI Document: ${document.title}\nPage count: ${document.pageCount}',
                                subject: document.title,
                              );
                            } else if (action == 'vault' && onToggleLock != null) {
                              onToggleLock!();
                            } else if (action == 'archive' && onToggleArchive != null) {
                              onToggleArchive!();
                            } else if (action == 'delete') {
                              onDelete();
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'share',
                              child: Row(
                                children: [
                                  Icon(Icons.share_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Share Document'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'vault',
                              child: Row(
                                children: [
                                  Icon(
                                    document.isLocked ? Icons.lock_open_rounded : Icons.lock_person_rounded,
                                    size: 18,
                                    color: const Color(0xFF8B5CF6),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    document.isLocked ? 'Remove from Hidden Vault' : 'Move to Hidden Vault',
                                    style: const TextStyle(color: Color(0xFF8B5CF6)),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'archive',
                              child: Row(
                                children: [
                                  Icon(
                                    document.isArchived ? Icons.unarchive_rounded : Icons.archive_rounded,
                                    size: 18,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(document.isArchived ? 'Unarchive Document' : 'Archive Document'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Move to Trash', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
              if (document.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: document.tags.map((t) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        t.startsWith('#') ? t : '#$t',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
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
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withOpacity(0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.saved_search_rounded, color: Colors.amber, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          matchingSnippet!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (document.aiSummary != null && document.aiSummary!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const AIBadge(label: 'AI Summary'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          document.aiSummary!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
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
