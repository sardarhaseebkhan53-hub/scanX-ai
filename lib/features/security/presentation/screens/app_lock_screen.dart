import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/route_names.dart';
import '../controllers/security_controller.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  String _enteredPin = '';
  List<int> _selectedPatternDots = [];
  bool _isPatternMode = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _triggerBiometrics());
  }

  Future<void> _triggerBiometrics() async {
    final success = await ref.read(securityProvider.notifier).unlockWithBiometrics();
    if (success && mounted) {
      context.go(RouteNames.home);
    }
  }

  void _onNumberPressed(String digit) async {
    if (_enteredPin.length < 4) {
      setState(() => _enteredPin += digit);
      if (_enteredPin.length == 4) {
        final success = await ref.read(securityProvider.notifier).unlockWithPin(_enteredPin);
        if (success && mounted) {
          context.go(RouteNames.home);
        } else {
          setState(() => _enteredPin = '');
        }
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
    }
  }

  void _onDotTapped(int index) async {
    if (_selectedPatternDots.contains(index)) return;
    setState(() => _selectedPatternDots.add(index));

    if (_selectedPatternDots.length >= 4) {
      final patternStr = _selectedPatternDots.join('-');
      final success = await ref.read(securityProvider.notifier).unlockWithPattern(patternStr);
      if (success && mounted) {
        context.go(RouteNames.home);
      } else if (_selectedPatternDots.length >= 6) {
        setState(() => _selectedPatternDots.clear());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(securityProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shield_outlined, color: colorScheme.primary, size: 48),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ScanX AI Vault',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isPatternMode
                        ? 'Connect dots to unlock secure vault'
                        : 'Enter 4-digit PIN or authenticate with biometrics',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isPatternMode = !_isPatternMode;
                        _enteredPin = '';
                        _selectedPatternDots.clear();
                      });
                    },
                    icon: Icon(
                      _isPatternMode ? Icons.pin_outlined : Icons.pattern_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _isPatternMode ? 'Switch to PIN Keypad' : 'Switch to Pattern Lock',
                    ),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),

              // Mode display: Pattern Grid vs PIN Dots + Keypad
              if (_isPatternMode)
                _buildPatternGrid(colorScheme)
              else ...[
                // PIN dots display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < _enteredPin.length;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? colorScheme.primary : Colors.grey.withOpacity(0.3),
                      ),
                    );
                  }),
                ),

                // Numeric Keypad
                Column(
                  children: [
                    _buildKeypadRow(['1', '2', '3']),
                    const SizedBox(height: 14),
                    _buildKeypadRow(['4', '5', '6']),
                    const SizedBox(height: 14),
                    _buildKeypadRow(['7', '8', '9']),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(Icons.fingerprint_rounded,
                              color: colorScheme.primary, size: 36),
                          onPressed: _triggerBiometrics,
                        ),
                        _buildKeypadButton('0'),
                        IconButton(
                          icon: const Icon(Icons.backspace_outlined, size: 28),
                          onPressed: _onBackspace,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatternGrid(ColorScheme colorScheme) {
    return Container(
      width: 240,
      height: 240,
      alignment: Alignment.center,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final isSelected = _selectedPatternDots.contains(index);
          return GestureDetector(
            onTap: () => _onDotTapped(index),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.primary.withOpacity(0.15),
                border: Border.all(
                  color: isSelected ? colorScheme.primary : Colors.grey.withOpacity(0.4),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? const Icon(Icons.circle, size: 14, color: Colors.white)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildKeypadButton(d)).toList(),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return InkWell(
      onTap: () => _onNumberPressed(digit),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        alignment: Alignment.center,
        child: Text(
          digit,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
