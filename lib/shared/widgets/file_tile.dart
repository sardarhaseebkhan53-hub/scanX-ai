import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';

/// Recent-file row: thumbnail, name, date + size, and a trailing "more" menu.
/// Built with Row/Expanded/Flexible only, so it never overflows regardless
/// of file-name length or screen width.
class FileTile extends StatelessWidget {
  final String title;
  final String dateLabel;
  final String sizeLabel;
  final String? thumbnailPath;
  final IconData fallbackIcon;
  final bool isFavorite;
  final bool isLocked;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;

  const FileTile({
    super.key,
    required this.title,
    required this.dateLabel,
    required this.sizeLabel,
    this.thumbnailPath,
    this.fallbackIcon = Icons.description_rounded,
    this.isFavorite = false,
    this.isLocked = false,
    required this.onTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasThumb = thumbnailPath != null && File(thumbnailPath!).existsSync();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Container(
                  width: 48,
                  height: 56,
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  child: hasThumb
                      ? Image.file(File(thumbnailPath!), fit: BoxFit.cover)
                      : Icon(fallbackIcon, color: theme.colorScheme.primary, size: 22),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        if (isLocked) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.lock_rounded,
                              size: 13, color: theme.textTheme.bodySmall?.color?.withOpacity(0.6)),
                        ],
                        if (isFavorite) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$dateLabel  ·  $sizeLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(isDark ? 0.6 : 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              if (onMoreTap != null)
                IconButton(
                  onPressed: onMoreTap,
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  splashRadius: 20,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
