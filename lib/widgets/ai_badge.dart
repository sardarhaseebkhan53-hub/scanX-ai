import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class AIBadge extends StatelessWidget {
  final String label;
  final bool compact;

  const AIBadge({super.key, this.label = 'AI Powered', this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        gradient: AppColors.aiGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.neonPurple.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3)),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: compact ? 10 : 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: compact ? 9 : 10, fontWeight: FontWeight.w800, letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }
}
