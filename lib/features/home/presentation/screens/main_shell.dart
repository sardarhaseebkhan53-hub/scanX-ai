import 'dart:ui';

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

/// Root shell — dark glass bottom bar with Home • Documents • [Scan] • AI Tools • Profile
/// plus floating AI assistant robot at bottom-right.
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

    // Calculate safe bottom offset so FAB + bottom bar don't overlap content.
    final mq = MediaQuery.of(context);
    final bottomPadding = mq.padding.bottom;

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF070A1E),
      body: Stack(
        children: [
          IndexedStack(
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
          // floating AI assistant bot button — bottom right
          Positioned(
            right: 12,
            bottom: 92 + bottomPadding,
            child: _FloatingBotButton(onTap: () => context.push(RouteNames.aiAssistant)),
          ),
        ],
      ),
      floatingActionButton: _ScanFab(onTap: () => context.push(RouteNames.scanner)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _PremiumBottomBar(current: _tab, onSelect: _goto),
    );
  }
}

// ---------------------------------------------------------------------------
// Center Scan Floating Action
// ---------------------------------------------------------------------------

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
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
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
          builder: (context, _) {
            final v = _pulse.value;
            return Stack(alignment: Alignment.center, children: [
              Container(
                width: 78 + 18 * v,
                height: 78 + 18 * v,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF8B5CF6).withOpacity(0.16 - 0.13 * v)),
              ),
              Container(
                width: 68 + 10 * v,
                height: 68 + 10 * v,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF3B82F6).withOpacity(0.10 - 0.08 * v)),
              ),
            ]);
          },
        ),
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6), Color(0xFF3B82F6), Color(0xFF06B6D4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.45), blurRadius: 22, offset: const Offset(0, 8)),
              BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.35), blurRadius: 30, offset: const Offset(0, 12)),
              BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6)),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.6),
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onTap,
              child: Stack(alignment: Alignment.center, children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.white.withOpacity(0.18), Colors.transparent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                const Icon(Icons.center_focus_strong_rounded, color: Colors.white, size: 30),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CustomPaint(painter: _ScanBracketPainter(), size: Size.infinite),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const d = 6.0;
    canvas.drawPath(Path()..moveTo(0, d)..lineTo(0, 0)..lineTo(d, 0), p);
    canvas.drawPath(Path()..moveTo(size.width - d, 0)..lineTo(size.width, 0)..lineTo(size.width, d), p);
    canvas.drawPath(Path()..moveTo(0, size.height - d)..lineTo(0, size.height)..lineTo(d, size.height), p);
    canvas.drawPath(Path()..moveTo(size.width - d, size.height)..lineTo(size.width, size.height)..lineTo(size.width, size.height - d), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Premium glass bottom bar
// ---------------------------------------------------------------------------

class _PremiumBottomBar extends StatelessWidget {
  final int current;
  final ValueChanged<int> onSelect;
  const _PremiumBottomBar({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.55), blurRadius: 30, offset: const Offset(0, 14))],
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0B102A).withOpacity(0.94),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 66,
                child: Row(
                  children: [
                    _NavItem(icon: Icons.home_rounded, iconOutlined: Icons.home_outlined, label: 'Home', selected: current == 0, onTap: () => onSelect(0)),
                    _NavItem(icon: Icons.folder_rounded, iconOutlined: Icons.folder_outlined, label: 'Documents', selected: current == 1, onTap: () => onSelect(1)),
                    const SizedBox(width: 64),
                    _NavItem(icon: Icons.auto_awesome_rounded, iconOutlined: Icons.auto_awesome_outlined, label: 'AI Tools', selected: current == 2, onTap: () => onSelect(2)),
                    _NavItem(icon: Icons.person_rounded, iconOutlined: Icons.person_outline_rounded, label: 'Profile', selected: current == 3, onTap: () => onSelect(3)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData iconOutlined;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.iconOutlined, required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: 66,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  selected ? icon : iconOutlined,
                  key: ValueKey(selected),
                  color: selected ? Colors.white : const Color(0xFF8B94B8),
                  size: selected ? 22 : 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF8B94B8),
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: -0.05,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: selected ? 18 : 0,
                height: 3,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)]),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: selected ? [BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.6), blurRadius: 6)] : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Floating AI Bot Assistant Button
// ---------------------------------------------------------------------------

class _FloatingBotButton extends StatefulWidget {
  final VoidCallback onTap;
  const _FloatingBotButton({required this.onTap});
  @override
  State<_FloatingBotButton> createState() => _FloatingBotButtonState();
}

class _FloatingBotButtonState extends State<_FloatingBotButton> with SingleTickerProviderStateMixin {
  late AnimationController _bob;
  @override
  void initState() {
    super.initState();
    _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bob,
      builder: (context, child) => Transform.translate(offset: Offset(0, -3 * _bob.value), child: child),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF312E81)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.6), width: 1.4),
            boxShadow: [
              BoxShadow(color: const Color(0xFF8B5CF6).withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8)),
              BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6)),
            ],
          ),
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFF8B5CF6).withOpacity(0.25), Colors.transparent]),
              ),
            ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFF5F3FF), Color(0xFFDDD6FE)]),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
              ),
              child: Stack(alignment: Alignment.center, children: [
                Container(
                  width: 28,
                  height: 16,
                  decoration: BoxDecoration(color: const Color(0xFF0F0B2A), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.4))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF8B5CF6), shape: BoxShape.circle)),
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle)),
                  ]),
                ),
                Positioned(top: 6, child: Container(width: 2, height: 4, decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.9), borderRadius: BorderRadius.circular(2)))),
              ]),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0B102A), width: 2),
                  boxShadow: [BoxShadow(color: const Color(0xFF22C55E).withOpacity(0.6), blurRadius: 6)],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
