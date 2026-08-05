import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';

class PremiumCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final double borderRadius;
  final bool hasGlow;

  const PremiumCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.color,
    this.borderRadius = AppSpacing.radiusMd,
    this.hasGlow = false,
  });

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.margin,
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.onTap != null ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeInOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.color ?? Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: _isPressed
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.4)
                    : Colors.grey.withOpacity(0.16),
                width: _isPressed ? 1.8 : 1.2,
              ),
              boxShadow: widget.hasGlow
                  ? AppSpacing.glowShadowBlue
                  : (Theme.of(context).brightness == Brightness.dark
                      ? AppSpacing.cardShadowDark
                      : AppSpacing.cardShadowLight),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
