import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Premium glass search bar with neon focus glow
class AppSearchBar extends StatefulWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final TextEditingController? controller;

  const AppSearchBar({
    super.key,
    this.hint = 'Search documents, tags, OCR text...',
    this.onChanged,
    this.onFilterTap,
    this.controller,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  bool _focused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 54,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C3E) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(
          color: _focused ? AppColors.primaryDark.withOpacity(0.6) : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
          width: _focused ? 1.4 : 1,
        ),
        boxShadow: _focused
            ? [BoxShadow(color: AppColors.primaryDark.withOpacity(0.25), blurRadius: 20, spreadRadius: 0, offset: const Offset(0, 6))]
            : isDark
                ? AppSpacing.cardShadowDark
                : AppSpacing.cardShadowLight,
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: _focused
                  ? AppColors.primaryGradient
                  : LinearGradient(colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.04)]),
              shape: BoxShape.circle,
              boxShadow: _focused
                  ? [BoxShadow(color: AppColors.primaryDark.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Icon(Icons.search_rounded, size: 19, color: _focused ? Colors.white : theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14.5),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryDark, fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
            ),
          ),
          if (widget.onFilterTap != null)
            GestureDetector(
              onTap: widget.onFilterTap,
              child: Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Icon(Icons.tune_rounded, size: 18, color: Colors.white.withOpacity(0.7)),
              ),
            ),
        ],
      ),
    );
  }
}
