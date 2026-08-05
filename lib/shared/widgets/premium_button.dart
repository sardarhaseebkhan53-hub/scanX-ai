import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

enum PremiumButtonVariant { primary, purple, cyan, outlined }

class PremiumButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final PremiumButtonVariant variant;

  const PremiumButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = PremiumButtonVariant.primary,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    LinearGradient? gradient;
    Color? borderSideColor;

    switch (widget.variant) {
      case PremiumButtonVariant.purple:
        gradient = AppColors.purpleGradient;
        break;
      case PremiumButtonVariant.cyan:
        gradient = AppColors.cyanGradient;
        break;
      case PremiumButtonVariant.outlined:
        gradient = null;
        borderSideColor = Theme.of(context).colorScheme.primary;
        break;
      case PremiumButtonVariant.primary:
        gradient = AppColors.primaryGradient;
        break;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeInOut,
        child: Container(
          width: double.infinity,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: gradient,
            color: widget.variant == PremiumButtonVariant.outlined
                ? Colors.transparent
                : null,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: borderSideColor != null
                ? Border.all(color: borderSideColor, width: 2)
                : null,
            boxShadow: widget.variant != PremiumButtonVariant.outlined
                ? AppSpacing.glowShadowBlue
                : null,
          ),
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: widget.variant == PremiumButtonVariant.outlined
                            ? borderSideColor
                            : Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.variant == PremiumButtonVariant.outlined
                            ? borderSideColor
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
