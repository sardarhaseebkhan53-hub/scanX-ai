import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../ai/presentation/screens/ai_tools_screen.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../settings/presentation/screens/profile_screen.dart';
import 'all_documents_screen.dart';
import 'home_screen.dart';

/// Root shell — dark glass bottom bar with Home • Documents • [Scan] • AI Tools • Profile
/// plus floating AI assistant robot at bottom-right.
/// Enhanced: floating button respects SafeArea, auto-hides while scrolling,
/// snaps to screen edges with smooth glassmorphism animation.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _tab = 0;
  String? _docsFilter;
  // Each scrollable tab owns its own controller. A single ScrollController must
  // never be attached to two scroll views at once — both tabs are kept mounted
  // simultaneously inside the IndexedStack, so sharing one controller throws
  // "ScrollController attached to multiple scroll views".
  final ScrollController _homeScrollController = ScrollController();
  final ScrollController _docsScrollController = ScrollController();
  bool _isBotVisible = true;
  double _lastScrollOffset = 0;

  ScrollController get _activeScrollController =>
      _tab == 0 ? _homeScrollController : _docsScrollController;

  void _goto(int tab) {
    if (tab == _tab) return;
    // Move the floating-bot auto-hide listener to the newly active scroll view.
    _homeScrollController.removeListener(_onScroll);
    _docsScrollController.removeListener(_onScroll);
    setState(() => _tab = tab);
    _attachActiveListener();
  }

  void _attachActiveListener() {
    _activeScrollController.addListener(_onScroll);
    _lastScrollOffset =
        _activeScrollController.hasClients ? _activeScrollController.offset : 0.0;
  }

  @override
  void initState() {
    super.initState();
    _attachActiveListener();
  }

  @override
  void dispose() {
    _homeScrollController.removeListener(_onScroll);
    _docsScrollController.removeListener(_onScroll);
    _homeScrollController.dispose();
    _docsScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final current =
        _activeScrollController.hasClients ? _activeScrollController.offset : 0.0;
    final delta = current - _lastScrollOffset;
    if (delta > 10 && _isBotVisible) {
      setState(() => _isBotVisible = false);
    } else if (delta < -5 && !_isBotVisible) {
      setState(() => _isBotVisible = true);
    }
    _lastScrollOffset = current;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    if (!settings.hasSeenOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(RouteNames.onboarding);
      });
    }

    final mq = MediaQuery.of(context);
    final bottomPadding = mq.padding.bottom;
    final safeAreaBottom = bottomPadding + 80; // space above bottom nav + fab

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF070A1E),
      body: Stack(
        children: [
          // Main content with scroll controller passed to scrollable pages
          IndexedStack(
            index: _tab,
            children: [
              HomeScreen(
                scrollController: _homeScrollController,
                onSeeAllDocs: () => _goto(1),
                onSeeAllTools: () => _goto(2),
                onOpenCategory: (category) {
                  _homeScrollController.removeListener(_onScroll);
                  _docsScrollController.removeListener(_onScroll);
                  setState(() {
                    _docsFilter = category;
                    _tab = 1;
                  });
                  _attachActiveListener();
                },
              ),
              AllDocumentsScreen(
                key: ValueKey(_docsFilter ?? 'all'),
                initialFilter: _docsFilter,
                scrollController: _docsScrollController,
              ),
              const AiToolsScreen(),
              const ProfileScreen(),
            ],
          ),
          // Floating AI assistant bot button — enhanced
          // Auto-hides while scrolling, smooth slide + fade, snaps to safe bottom-right
          Positioned(
            right: 16,
            bottom: safeAreaBottom,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              offset: Offset(0, _isBotVisible ? 0 : 1.2),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                opacity: _isBotVisible ? 1.0 : 0.0,
                child: _FloatingBotButton(
                  onTap: () => context.push(RouteNames.aiAssistant),
                ),
              ),
            ),
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
// Center Scan Floating Action — refined with smoother pulse
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
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final v = _pulse.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow pulse — softer opacity
            Container(
              width: 70 + 10 * v,
              height: 70 + 10 * v,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonPurple.withOpacity(0.12 - 0.08 * v),
              ),
            ),
            // Main button
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6), Color(0xFF3B82F6), Color(0xFF06B6D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.20),
                  width: 1.3,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  borderRadius: BorderRadius.circular(50),
                  onTap: widget.onTap,
                  splashColor: Colors.white.withOpacity(0.15),
                  highlightColor: Colors.white.withOpacity(0.08),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Subtle top highlight
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.14),
                                Colors.transparent,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                      // Icon
                      const Icon(
                        Icons.center_focus_strong_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      // Corner brackets
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: CustomPaint(
                            painter: _ScanBracketPainter(),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScanBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const d = 5.0;
    // Top-left
    canvas.drawPath(
      Path()..moveTo(0, d)..lineTo(0, 0)..lineTo(d, 0),
      paint,
    );
    // Top-right
    canvas.drawPath(
      Path()..moveTo(size.width - d, 0)..lineTo(size.width, 0)..lineTo(size.width, d),
      paint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()..moveTo(0, size.height - d)..lineTo(0, size.height)..lineTo(d, size.height),
      paint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()..moveTo(size.width - d, size.height)..lineTo(size.width, size.height)..lineTo(size.width, size.height - d),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Premium glass bottom bar — refined spacing, smoother animations
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.50),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0B102A).withOpacity(0.90),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 64,
                child: Row(
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      iconOutlined: Icons.home_outlined,
                      label: 'Home',
                      selected: current == 0,
                      onTap: () => onSelect(0),
                    ),
                    _NavItem(
                      icon: Icons.folder_rounded,
                      iconOutlined: Icons.folder_outlined,
                      label: 'Documents',
                      selected: current == 1,
                      onTap: () => onSelect(1),
                    ),
                    const SizedBox(width: 58),
                    _NavItem(
                      icon: Icons.auto_awesome_rounded,
                      iconOutlined: Icons.auto_awesome_outlined,
                      label: 'AI Tools',
                      selected: current == 2,
                      onTap: () => onSelect(2),
                    ),
                    _NavItem(
                      icon: Icons.person_rounded,
                      iconOutlined: Icons.person_outline_rounded,
                      label: 'Profile',
                      selected: current == 3,
                      onTap: () => onSelect(3),
                    ),
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

  const _NavItem({
    required this.icon,
    required this.iconOutlined,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          splashColor: AppColors.neonPurple.withOpacity(0.15),
          highlightColor: AppColors.neonPurple.withOpacity(0.06),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(
                      opacity: anim,
                      child: child,
                    ),
                  ),
                  child: Icon(
                    selected ? icon : iconOutlined,
                    key: ValueKey<bool>(selected),
                    color: selected ? Colors.white : const Color(0xFF8B94B8),
                    size: selected ? 23 : 20,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF8B94B8),
                    fontSize: selected ? 10.5 : 10,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: selected ? 0.0 : -0.05,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  width: selected ? 20 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withOpacity(0.55),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Floating AI Bot Assistant Button — improved glassmorphism
// ---------------------------------------------------------------------------

class _FloatingBotButton extends StatefulWidget {
  final VoidCallback onTap;
  const _FloatingBotButton({required this.onTap});
  @override
  State<_FloatingBotButton> createState() => _FloatingBotButtonState();
}

class _FloatingBotButtonState extends State<_FloatingBotButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _bob;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
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
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -3 * math.sin(_bob.value * math.pi * 2)),
          child: child,
        );
      },
      child: Semantics(
        label: 'AI Assistant Button',
        button: true,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF1A0F3D), Color(0xFF2A1A5A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: AppColors.neonPurple.withOpacity(0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonPurple.withOpacity(0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glass inner ring
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.neonPurple.withOpacity(0.20),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Robot face
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF5F3FF), Color(0xFFDDD6FE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.85),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Eyes
                      Container(
                        width: 26,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0B2A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.neonPurple.withOpacity(0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.neonPurple,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.neonBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Antenna glow
                      Positioned(
                        top: 5,
                        child: Container(
                          width: 1.5,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.neonPurple.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status dot — online indicator
                Positioned(
                  right: 3,
                  bottom: 3,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF070A1E),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withOpacity(0.5),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
