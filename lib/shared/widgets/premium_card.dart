import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class PremiumCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final double borderRadius;
  final bool hasGlow;
  final Gradient? gradient;
  final bool enableGlass;

  const PremiumCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(18),
    this.margin = EdgeInsets.zero,
    this.color,
    this.borderRadius = AppSpacing.radiusLg,
    this.hasGlow = false,
    this.gradient,
    this.enableGlass = true,
  });

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _shineCtrl;

  @override
  void initState() {
    super.initState();
    _shineCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  }

  @override
  void dispose() {
    _shineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: widget.margin,
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.onTap != null ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: widget.gradient ??
                  (widget.color != null
                      ? null
                      : isDark
                          ? const LinearGradient(
                              colors: [Color(0xFF151D3F), Color(0xFF121A38)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null),
              color: widget.gradient == null ? (widget.color ?? (isDark ? AppColors.surfaceDarkElevated : Colors.white)) : null,
              border: Border.all(
                color: _isPressed
                    ? AppColors.primaryDark.withOpacity(0.5)
                    : isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06),
                width: _isPressed ? 1.5 : 1,
              ),
              boxShadow: widget.hasGlow
                  ? AppSpacing.glowShadowBlue
                  : (isDark ? AppSpacing.cardShadowDark : AppSpacing.cardShadowLight),
            ),
            child: widget.enableGlass && isDark
                ? Stack(
                    children: [
                      // inner highlight
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white.withOpacity(0.18), Colors.white.withOpacity(0.0)],
                            ),
                          ),
                        ),
                      ),
                      widget.child,
                    ],
                  )
                : widget.child,
          ),
        ),
      ),
    );
  }
}

/// Glassmorphic container with blur
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double blur;
  final double opacity;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = AppSpacing.radiusLg,
    this.padding = const EdgeInsets.all(18),
    this.margin = EdgeInsets.zero,
    this.blur = 18,
    this.opacity = 0.08,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(opacity),
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(opacity + 0.06),
                    Colors.white.withOpacity(opacity - 0.02).clamp(Colors.transparent, Colors.white),
                  ],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
