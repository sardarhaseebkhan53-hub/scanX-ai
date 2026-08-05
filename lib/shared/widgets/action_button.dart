import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Quick-action luxury card used in Home dashboard 2x2 grid
class ActionButton extends StatefulWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            gradient: isDark
                ? LinearGradient(
                    colors: [
                      _pressed ? const Color(0xFF202A55) : const Color(0xFF171F44),
                      _pressed ? const Color(0xFF1A234A) : const Color(0xFF121A38),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isDark ? null : theme.cardTheme.color,
            border: Border.all(
              color: _pressed ? AppColors.primaryDark.withOpacity(0.6) : Colors.white.withOpacity(0.07),
              width: 1.2,
            ),
            boxShadow: _pressed
                ? [
                    BoxShadow(color: widget.gradient.colors.first.withOpacity(0.35), blurRadius: 22, offset: const Offset(0, 10)),
                  ]
                : AppSpacing.cardShadowDark,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: widget.gradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: widget.gradient.colors.first.withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Center(child: Icon(widget.icon, color: Colors.white, size: 24)),
                  ),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Icon(Icons.arrow_outward_rounded, size: 14, color: Colors.white.withOpacity(0.7)),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: -0.2),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryDark, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
