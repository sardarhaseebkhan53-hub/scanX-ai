import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../models/folder_item.dart';

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          width: 156,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [folderColor.withOpacity(0.18), folderColor.withOpacity(0.06)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: folderColor.withOpacity(0.22), width: 1.2),
            boxShadow: [
              BoxShadow(color: folderColor.withOpacity(0.18), blurRadius: 14, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: folderColor.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: folderColor.withOpacity(0.25)),
                    ),
                    child: Icon(folder.isLocked ? Icons.folder_special_rounded : Icons.folder_rounded, color: folderColor, size: 20),
                  ),
                  if (folder.isLocked)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: const Color(0xFFFFC857).withOpacity(0.22), shape: BoxShape.circle),
                      child: const Icon(Icons.lock_rounded, size: 12, color: Color(0xFFFFC857)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(folder.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 13.5)),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: folderColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: folderColor.withOpacity(0.6), blurRadius: 6)]),
                  ),
                  const SizedBox(width: 6),
                  Text('$itemCount ${itemCount == 1 ? 'doc' : 'docs'}', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondaryDark)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
