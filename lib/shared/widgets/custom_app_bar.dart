import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final bool isGlass;
  final String? subtitle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.isGlass = true,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: isGlass ? 20 : 0, sigmaY: isGlass ? 20 : 0),
        child: AppBar(
          backgroundColor: isGlass
              ? (isDark ? AppColors.backgroundDark.withOpacity(0.75) : Colors.white.withOpacity(0.85))
              : Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleSpacing: 0,
          title: leading != null
              ? Row(children: [leading!, const SizedBox(width: 8), _buildTitle(context)])
              : _buildTitle(context),
          leading: leading ??
              (showBackButton && Navigator.of(context).canPop()
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _GlassIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    )
                  : null),
          automaticallyImplyLeading: false,
          actions: [
            if (actions != null) ...actions!,
            const SizedBox(width: 8),
          ],
          bottom: isGlass
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0)],
                      ),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final theme = Theme.of(context);
    if (subtitle != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
          ),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryDark, fontSize: 11.5, letterSpacing: 0.2),
          ),
        ],
      );
    }
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
        ),
        child: Icon(icon, size: 18, color: Colors.white.withOpacity(0.85)),
      ),
    );
  }
}
