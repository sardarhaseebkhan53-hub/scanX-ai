import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../ai/presentation/screens/ai_tools_screen.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../settings/presentation/screens/profile_screen.dart';
import 'all_documents_screen.dart';
import 'home_screen.dart';

/// Root shell with the product-reference bottom navigation:
/// Home • All Documents • [Scan] • AI Tools • Profile
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _tab = 0;
  String? _docsFilter;

  void _goto(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    if (!settings.hasSeenOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(RouteNames.onboarding);
      });
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.backgroundDark,
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(
            onSeeAllDocs: () => _goto(1),
            onSeeAllTools: () => _goto(2),
            onOpenCategory: (category) {
              setState(() {
                _docsFilter = category;
                _tab = 1;
              });
            },
          ),
          AllDocumentsScreen(key: ValueKey(_docsFilter ?? 'all'), initialFilter: _docsFilter),
          const AiToolsScreen(),
          const ProfileScreen(),
        ],
      ),
      floatingActionButton: _ScanFab(onTap: () => context.push(RouteNames.scanner)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _ShellBar(current: _tab, onSelect: _goto),
    );
  }
}

class _ScanFab extends StatefulWidget {
  final VoidCallback onTap;
  const _ScanFab({required this.onTap});

  @override
  State<_ScanFab> createState() => _ScanFabState();
}

class _ScanFabState extends State<_ScanFab> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) => Container(
            width: 72 + 14 * _pulse.value,
            height: 72 + 14 * _pulse.value,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.neonPurple.withOpacity(0.18 - 0.12 * _pulse.value)),
          ),
        ),
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.brandGradient,
            boxShadow: [
              BoxShadow(color: AppColors.neonPurple.withOpacity(0.45), blurRadius: 22, offset: const Offset(0, 8)),
              BoxShadow(color: AppColors.neonCyan.withOpacity(0.25), blurRadius: 32, offset: const Offset(0, 12)),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.2),
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onTap,
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 26),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShellBar extends StatelessWidget {
  final int current;
  final ValueChanged<int> onSelect;
  const _ShellBar({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1226).withOpacity(0.96),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 28, offset: const Offset(0, 12))],
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded, label: 'Home', selected: current == 0, onTap: () => onSelect(0)),
                _NavItem(icon: Icons.folder_copy_rounded, label: 'All Documents', selected: current == 1, onTap: () => onSelect(1)),
                const SizedBox(width: 56),
                _NavItem(icon: Icons.auto_awesome_rounded, label: 'AI Tools', selected: current == 2, onTap: () => onSelect(2)),
                _NavItem(icon: Icons.person_rounded, label: 'Profile', selected: current == 3, onTap: () => onSelect(3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 66,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  key: ValueKey(selected),
                  color: selected ? Colors.white : AppColors.textSecondaryDark,
                  size: selected ? 21 : 19,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondaryDark,
                  fontSize: 9.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: selected ? 16 : 0,
                height: 3,
                decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
