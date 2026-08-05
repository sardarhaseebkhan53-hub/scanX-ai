import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.folder_open_rounded,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1E2750), Color(0xFF151D3F)]),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                boxShadow: [
                  BoxShadow(color: AppColors.primaryDark.withOpacity(0.20), blurRadius: 30, offset: const Offset(0, 10)),
                ],
              ),
              child: Stack(
                children: [
                  Center(child: Icon(icon, size: 38, color: AppColors.textSecondaryDark)),
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [AppColors.primaryDark.withOpacity(0.15), Colors.transparent]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13.5, color: AppColors.textSecondaryDark, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 26),
              GestureDetector(
                onTap: onButtonPressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.scannerGradient,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    boxShadow: [BoxShadow(color: AppColors.primaryDark.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(buttonText!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
