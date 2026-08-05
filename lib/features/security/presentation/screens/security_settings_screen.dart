import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../controllers/security_controller.dart';

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(securityProvider);
    final controller = ref.read(securityProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: const CustomAppBar(title: 'Security', subtitle: 'AES-256 • Keystore shield'),
      body: Stack(
        children: [
          Positioned(top: -60, left: -40, child: Container(width: 260, height: 260, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.neonPurple.withOpacity(0.14), Colors.transparent])))),
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF1E2750)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.neonPurple.withOpacity(0.22)),
                  boxShadow: [BoxShadow(color: AppColors.neonPurple.withOpacity(0.20), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: Column(
                  children: [
                    Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(gradient: AppColors.purpleGradient, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.neonPurple.withOpacity(0.4), blurRadius: 20)]), child: const Icon(Icons.shield_rounded, color: Colors.white, size: 42)),
                    const SizedBox(height: 14),
                    const Text('Documents Protected', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('AES-256 Keystore Shield Active', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SecRow(title: 'App Lock', subtitle: 'PIN, Pattern, Fingerprint', icon: Icons.lock_rounded, gradient: AppColors.purpleGradient, onTap: () => _showPinDialog(context, controller)),
              _SecRow(title: 'Biometric', subtitle: state.isBiometricEnabled ? 'Enabled • Face / Finger' : 'Disabled', icon: Icons.fingerprint_rounded, gradient: AppColors.scannerGradient, trailing: Switch(value: state.isBiometricEnabled, activeColor: AppColors.primaryDark, onChanged: state.isBiometricAvailable ? (v) => controller.toggleBiometric(v) : null)),
              _SecRow(title: 'Auto Lock', subtitle: 'After ${state.autoLockTimeoutMinutes} min', icon: Icons.timer_rounded, gradient: AppColors.cyanGradient, trailing: DropdownButton<int>(value: state.autoLockTimeoutMinutes, dropdownColor: const Color(0xFF151D3F), underline: const SizedBox(), style: const TextStyle(color: Colors.white, fontSize: 13), items: const [DropdownMenuItem(value: 1, child: Text('1 min')), DropdownMenuItem(value: 5, child: Text('5 min')), DropdownMenuItem(value: 15, child: Text('15 min'))], onChanged: (v) { if (v != null) controller.setTimeoutMinutes(v); })),
              _SecRow(title: 'Hidden Vault', subtitle: 'Private AES-256 folder', icon: Icons.lock_person_rounded, gradient: AppColors.goldGradient, onTap: () => context.push(RouteNames.hiddenVault)),
              _SecRow(title: 'Pattern Lock', subtitle: state.isPatternEnabled ? '3x3 Grid active' : 'Set visual pattern', icon: Icons.pattern_rounded, gradient: AppColors.aiGradient, onTap: () => _showPatternDialog(context, controller)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.06))),
                child: Row(children: [Icon(Icons.visibility_off_rounded, color: AppColors.textSecondaryDark, size: 18), const SizedBox(width: 10), const Expanded(child: Text('Hide previews for locked files', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))), Switch(value: state.hidePreviewForLockedFiles, activeColor: AppColors.primaryDark, onChanged: (v) => controller.toggleHidePreview(v))]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void _showPinDialog(BuildContext context, SecurityController controller) {
    final pinController = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: AppColors.surfaceDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.08))), title: const Text('Set Vault PIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), content: TextField(controller: pinController, keyboardType: TextInputType.number, maxLength: 4, obscureText: true, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: '4 digits', hintStyle: TextStyle(color: AppColors.textSecondaryDark), filled: true, fillColor: const Color(0xFF101735), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AppColors.textSecondaryDark))), Container(decoration: BoxDecoration(gradient: AppColors.scannerGradient, borderRadius: BorderRadius.circular(10)), child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent), onPressed: () { final v = pinController.text.trim(); if (v.length == 4) { controller.setPinCode(v); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN secured in Keystore'), backgroundColor: Color(0xFF151D3F))); } }, child: const Text('Save', style: TextStyle(color: Colors.white))))]));
  }

  static void _showPatternDialog(BuildContext context, SecurityController controller) {
    final pat = TextEditingController(text: '0-1-2-5-8');
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: AppColors.surfaceDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('Pattern', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), content: TextField(controller: pat, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: '0-1-2-5-8', filled: true, fillColor: const Color(0xFF101735), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))), actions: [Container(decoration: BoxDecoration(gradient: AppColors.scannerGradient, borderRadius: BorderRadius.circular(10)), child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent), onPressed: () { controller.setPatternCode(pat.text.trim()); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pattern secured'), backgroundColor: Color(0xFF151D3F))); }, child: const Text('Save', style: TextStyle(color: Colors.white))))]));
  }
}

class _SecRow extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback? onTap;
  final Widget? trailing;
  const _SecRow({required this.title, required this.subtitle, required this.icon, required this.gradient, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF151D3F), Color(0xFF121A36)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.07))),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(width: 42, height: 42, decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: Colors.white, size: 20)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11.5)),
        trailing: trailing ?? Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.08))), child: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white54)),
        onTap: onTap,
      ),
    );
  }
}
