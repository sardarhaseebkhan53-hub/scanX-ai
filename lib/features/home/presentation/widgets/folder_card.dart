import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../models/folder_item.dart';

/// Horizontal-scroll folder card. Fixed width (set by the parent
/// SizedBox in the ListView), intrinsic height, no overflow.
class FolderCard extends StatelessWidget {
  final FolderItem folder;
  final int itemCount;
  final VoidCallback onTap;

  const FolderCard({
    super.key,
    required this.folder,
    required this.itemCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final folderColor = AppColors.fromHex(folder.colorHex);
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          width: 148,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: folderColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: folderColor.withOpacity(0.25), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: folderColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                    ),
                    child: Icon(
                      folder.isLocked ? Icons.folder_shared_rounded : Icons.folder_rounded,
                      color: folderColor,
                      size: 22,
                    ),
                  ),
                  if (folder.isLocked)
                    const Icon(Icons.lock_rounded, size: 15, color: Color(0xFFF59E0B)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                folder.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 3),
              Text(
                '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
