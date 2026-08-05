import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/edge_detection_overlay.dart';
import '../controllers/scanner_controller.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> with TickerProviderStateMixin {
  late AnimationController _scanLineCtrl;

  @override
  void initState() {
    super.initState();
    _scanLineCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanLineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerProvider);
    final scannerController = ref.read(scannerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: scannerState.isInitialized && scannerController.cameraController != null
                ? CameraPreview(scannerController.cameraController!)
                : _FallbackPreview(onImport: () async {
                    await scannerController.importFromGallery();
                    final updatedImages = ref.read(scannerProvider).capturedImages;
                    if (updatedImages.isNotEmpty && context.mounted) {
                      context.push(RouteNames.scanPreview, extra: updatedImages);
                    }
                  }),
          ),

          // Subtle vignette
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
                ),
              ),
            ),
          ),

          if (scannerState.isGridOverlayOn)
            Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: _LuxGridPainter())),
            ),

          // Neon Edge Detection Overlay
          Positioned.fill(
            child: LayoutBuilder(builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final corners = [
                Offset(w * 0.12, h * 0.20),
                Offset(w * 0.88, h * 0.20),
                Offset(w * 0.90, h * 0.78),
                Offset(w * 0.10, h * 0.78),
              ];
              return Stack(
                children: [
                  EdgeDetectionOverlay(corners: corners, strokeColor: AppColors.neonCyan),
                  // Scanning laser line animation
                  AnimatedBuilder(
                    animation: _scanLineCtrl,
                    builder: (context, child) {
                      final top = h * 0.20 + (h * 0.58) * _scanLineCtrl.value;
                      return Positioned(
                        top: top,
                        left: w * 0.14,
                        right: w * 0.14,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.neonCyan.withOpacity(0), AppColors.neonCyan, AppColors.neonCyan.withOpacity(0)]),
                            boxShadow: [BoxShadow(color: AppColors.neonCyan.withOpacity(0.8), blurRadius: 12, spreadRadius: 1)],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            }),
          ),

          if (scannerState.isLevelIndicatorOn)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.48,
              left: MediaQuery.of(context).size.width * 0.30,
              right: MediaQuery.of(context).size.width * 0.30,
              child: Container(height: 2, decoration: BoxDecoration(color: AppColors.neonGreen.withOpacity(0.9), borderRadius: BorderRadius.circular(2), boxShadow: [BoxShadow(color: AppColors.neonGreen, blurRadius: 8)])),
            ),

          // Top glass bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 360;
                return Row(
                  children: [
                    _GlassBtn(icon: Icons.close_rounded, onTap: () => Navigator.pop(context)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => scannerController.toggleAutoCapture(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: scannerState.isAutoCaptureEnabled ? AppColors.scannerGradient : null,
                          color: scannerState.isAutoCaptureEnabled ? null : Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: scannerState.isAutoCaptureEnabled ? Colors.white.withOpacity(0.22) : Colors.white.withOpacity(0.12)),
                          boxShadow: scannerState.isAutoCaptureEnabled ? [BoxShadow(color: AppColors.primaryDark.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4))] : null,
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(scannerState.isAutoCaptureEnabled ? Icons.auto_awesome_rounded : Icons.center_focus_strong_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            compact ? (scannerState.isAutoCaptureEnabled ? 'AI' : 'Manual') : (scannerState.isAutoCaptureEnabled ? 'AI Auto ON' : 'Manual'),
                            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                        ]),
                      ),
                    ),
                    const Spacer(),
                    _GlassBtn(icon: Icons.grid_on_rounded, active: scannerState.isGridOverlayOn, onTap: () => scannerController.toggleGridOverlay()),
                    SizedBox(width: compact ? 6 : 8),
                    _GlassBtn(icon: scannerState.timerSeconds > 0 ? Icons.timer_rounded : Icons.timer_off_rounded, active: scannerState.timerSeconds > 0, onTap: () => scannerController.cycleTimer()),
                    SizedBox(width: compact ? 6 : 8),
                    if (scannerState.canSwitchCamera) ...[
                      _GlassBtn(icon: Icons.cameraswitch_rounded, onTap: () => scannerController.switchCamera()),
                      SizedBox(width: compact ? 6 : 8),
                    ],
                    _GlassBtn(icon: _getFlashIcon(scannerState.flashMode), active: scannerState.flashMode != 'off', onTap: () => scannerController.cycleFlashMode()),
                  ],
                );
              },
            ),
          ),

          // AI Quality badge
          Positioned(
            top: MediaQuery.of(context).padding.top + 68,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 40),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: scannerState.isBlurDetected ? const Color(0xFFFF5A78).withOpacity(0.92) : Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scannerState.isBlurDetected ? Colors.redAccent : AppColors.neonGreen.withOpacity(0.4)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(color: scannerState.isBlurDetected ? Colors.white.withOpacity(0.22) : AppColors.neonGreen.withOpacity(0.22), shape: BoxShape.circle),
                      child: Icon(scannerState.isBlurDetected ? Icons.warning_amber_rounded : Icons.verified_rounded, color: scannerState.isBlurDetected ? Colors.white : AppColors.neonGreen, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        scannerState.qualityFeedback,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Exposure slider glass
          Positioned(
            right: 14,
            top: MediaQuery.of(context).size.height * 0.28,
            bottom: MediaQuery.of(context).size.height * 0.34,
            child: Container(
              width: 42,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.38),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Column(
                children: [
                  Container(width: 28, height: 28, decoration: BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle), child: const Icon(Icons.wb_sunny_rounded, color: Colors.black, size: 16)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: SliderTheme(
                        data: SliderThemeData(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8), overlayShape: const RoundSliderOverlayShape(overlayRadius: 16), activeTrackColor: AppColors.neonCyan, inactiveTrackColor: Colors.white24, thumbColor: Colors.white),
                        child: Slider(value: scannerState.exposureOffset, min: -2.0, max: 2.0, onChanged: (v) => scannerController.setExposureOffset(v)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(scannerState.exposureOffset.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),

          // Bottom glass sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20, top: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.84), Colors.black.withOpacity(0.96)]),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: ScanMode.values.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final mode = ScanMode.values[index];
                        final isSelected = scannerState.currentMode == mode;
                        String label = mode.name.toUpperCase();
                        if (mode == ScanMode.idCard) label = 'ID CARD';
                        if (mode == ScanMode.businessCard) label = 'BUSINESS';
                        if (mode == ScanMode.invoice) label = 'INVOICE';
                        return GestureDetector(
                          onTap: () => scannerController.setScanMode(mode),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isSelected ? AppColors.scannerGradient : null,
                              color: isSelected ? null : Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? Colors.white.withOpacity(0.22) : Colors.white.withOpacity(0.10)),
                              boxShadow: isSelected ? [BoxShadow(color: AppColors.primaryDark.withOpacity(0.35), blurRadius: 12)] : null,
                            ),
                            child: Center(child: Text(label, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, letterSpacing: 0.5))),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CaptureSideBtn(icon: Icons.photo_library_rounded, label: 'Gallery', onTap: () async {
                          await scannerController.importFromGallery();
                          final updatedImages = ref.read(scannerProvider).capturedImages;
                          if (updatedImages.isNotEmpty && context.mounted) {
                            context.push(RouteNames.scanPreview, extra: updatedImages);
                          }
                        }),
                        GestureDetector(
                          onTap: scannerState.isCapturing
                              ? null
                              : () async {
                                  final path = await scannerController.capturePhoto();
                                  final latestMode = ref.read(scannerProvider).currentMode;
                                  if (path != null && context.mounted && latestMode != ScanMode.batch) {
                                    context.push(RouteNames.crop, extra: path);
                                  }
                                },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(colors: [Colors.white, Color(0xFFE0E0E0)]),
                                  boxShadow: [
                                    BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 20, spreadRadius: 1),
                                    BoxShadow(color: AppColors.primaryDark.withOpacity(0.45), blurRadius: 32, offset: const Offset(0, 8)),
                                  ],
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                              ),
                              Container(width: 70, height: 70, decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.scannerGradient, boxShadow: [BoxShadow(color: AppColors.primaryDark.withOpacity(0.6), blurRadius: 12)])),
                              scannerState.isCapturing
                                  ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white))
                                  : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 30),
                              if (scannerState.timerSeconds > 0)
                                Container(
                                  width: 84,
                                  height: 84,
                                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                                  child: Center(child: Text('${scannerState.timerSeconds}s', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20))),
                                ),
                            ],
                          ),
                        ),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _CaptureSideBtn(
                              icon: Icons.layers_rounded,
                              label: 'Batch',
                              onTap: () {
                                if (scannerState.capturedImages.isNotEmpty) {
                                  context.push(RouteNames.scanPreview, extra: scannerState.capturedImages);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Capture at least one page')));
                                }
                              },
                            ),
                            if (scannerState.capturedImages.isNotEmpty)
                              Positioned(
                                top: -6,
                                right: -6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(gradient: AppColors.scannerGradient, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white, width: 1.2), boxShadow: [BoxShadow(color: AppColors.primaryDark.withOpacity(0.5), blurRadius: 8)]),
                                  child: Text('${scannerState.capturedImages.length}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFlashIcon(String mode) {
    switch (mode) {
      case 'on':
        return Icons.flash_on_rounded;
      case 'auto':
        return Icons.flash_auto_rounded;
      case 'torch':
        return Icons.highlight_rounded;
      default:
        return Icons.flash_off_rounded;
    }
  }
}

class _GlassBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  const _GlassBtn({required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: active ? AppColors.scannerGradient : null,
          color: active ? null : Colors.black.withOpacity(0.42),
          shape: BoxShape.circle,
          border: Border.all(color: active ? Colors.white.withOpacity(0.22) : Colors.white.withOpacity(0.16)),
          boxShadow: active ? [BoxShadow(color: AppColors.primaryDark.withOpacity(0.35), blurRadius: 12)] : null,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _CaptureSideBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CaptureSideBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.14)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10)],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _FallbackPreview extends StatelessWidget {
  final VoidCallback onImport;
  const _FallbackPreview({required this.onImport});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0A0E26), Color(0xFF151D3F)], begin: Alignment.topCenter, end: Alignment.bottomCenter)))),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.scannerGradient, boxShadow: [BoxShadow(color: AppColors.primaryDark.withOpacity(0.45), blurRadius: 24, offset: const Offset(0, 8))]),
                child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 18),
              const Text('Premium Scanner Ready', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('AI edge detection • Auto capture • HD', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onImport,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.14))),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.photo_library_rounded, color: Colors.white, size: 18), SizedBox(width: 8), Text('Import from Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LuxGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.14)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
