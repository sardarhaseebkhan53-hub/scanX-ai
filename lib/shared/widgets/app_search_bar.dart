import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';

/// Rounded pill search field shared by Home, PDF Tools, and QR Toolkit.
class AppSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final TextEditingController? controller;

  const AppSearchBar({
    super.key,
    this.hint = 'Search files, folders, tags...',
    this.onChanged,
    this.onFilterTap,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16161E) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded,
              size: 20, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.55)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.45),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (onFilterTap != null)
            GestureDetector(
              onTap: onFilterTap,
              behavior: HitTestBehavior.opaque,
              child: Icon(Icons.tune_rounded,
                  size: 20, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.55)),
            ),
        ],
      ),
    );
  }
}
