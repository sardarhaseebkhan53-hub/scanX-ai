import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../widgets/edge_detection_overlay.dart';
import '../controllers/scanner_controller.dart';

class ScannerScreen extends ConsumerWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerState = ref.watch(scannerProvider);
    final scannerController = ref.read(scannerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview or Fallback
          Positioned.fill(
            child: scannerState.isInitialized && scannerController.cameraController != null
                ? CameraPreview(scannerController.cameraController!)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'Camera Preview Mode',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap below to capture or import from gallery',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await scannerController.importFromGallery();
                            if (scannerState.capturedImages.isNotEmpty && context.mounted) {
                              context.push(
                                RouteNames.scanPreview,
                                extra: scannerState.capturedImages,
                              );
                            }
                          },
                          icon: const Icon(Icons.photo_library_rounded),
                          label: const Text('Import from Gallery'),
                        ),
                      ],
                    ),
                  ),
          ),

          // 2. Grid Lines Overlay (if enabled)
          if (scannerState.isGridOverlayOn)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _GridOverlayPainter(),
                ),
              ),
            ),

          // 3. Auto Edge Detection Bounding Polygon Overlay
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                // Default bounding corners simulating auto-detected document edges
                final corners = [
                  Offset(width * 0.15, height * 0.22),
                  Offset(width * 0.85, height * 0.22),
                  Offset(width * 0.88, height * 0.75),
                  Offset(width * 0.12, height * 0.75),
                ];
                return EdgeDetectionOverlay(corners: corners);
              },
            ),
          ),

          // 4. Horizon Level Crosshair Indicator (if enabled)
          if (scannerState.isLevelIndicatorOn)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.48,
              left: MediaQuery.of(context).size.width * 0.35,
              right: MediaQuery.of(context).size.width * 0.35,
              child: IgnorePointer(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.85),
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
                  ),
                ),
              ),
            ),

          // 5. Top Control Bar (Back, Flash, Auto-Detect Pill, Grid, Timer, Level)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircleButton(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
                // Orange "Auto Detect" Pill Button
                GestureDetector(
                  onTap: () => scannerController.toggleAutoCapture(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: scannerState.isAutoCaptureEnabled
                          ? const Color(0xFFF97316) // Vibrant Orange
                          : Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_mode_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          scannerState.isAutoCaptureEnabled
                              ? 'Auto Detect ON'
                              : 'Manual Shutter',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    _buildCircleButton(
                      icon: Icons.grid_on_rounded,
                      color: scannerState.isGridOverlayOn ? Colors.amber : Colors.white,
                      onTap: () => scannerController.toggleGridOverlay(),
                    ),
                    const SizedBox(width: 8),
                    _buildCircleButton(
                      icon: scannerState.timerSeconds > 0 ? Icons.timer_rounded : Icons.timer_off_rounded,
                      color: scannerState.timerSeconds > 0 ? Colors.amber : Colors.white,
                      onTap: () => scannerController.cycleTimer(),
                    ),
                    const SizedBox(width: 8),
                    _buildCircleButton(
                      icon: _getFlashIcon(scannerState.flashMode),
                      color: scannerState.flashMode != 'off' ? Colors.amber : Colors.white,
                      onTap: () => scannerController.cycleFlashMode(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 6. Live AI Quality Score & Blur Warning Badge
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: scannerState.isBlurDetected
                    ? Colors.redAccent.withOpacity(0.92)
                    : Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: scannerState.isBlurDetected
                      ? Colors.red
                      : const Color(0xFF10B981).withOpacity(0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    scannerState.isBlurDetected
                        ? Icons.warning_amber_rounded
                        : Icons.verified_rounded,
                    color: scannerState.isBlurDetected ? Colors.white : const Color(0xFF10B981),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      scannerState.qualityFeedback,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 7. Right Vertical Manual Exposure Slider (-2.0 to +2.0)
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.3,
            bottom: MediaQuery.of(context).size.height * 0.32,
            child: Container(
              width: 36,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 16),
                  Expanded(
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Slider(
                        value: scannerState.exposureOffset,
                        min: -2.0,
                        max: 2.0,
                        activeColor: Colors.amber,
                        inactiveColor: Colors.white24,
                        onChanged: (val) => scannerController.setExposureOffset(val),
                      ),
                    ),
                  ),
                  Text(
                    scannerState.exposureOffset.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // 8. Bottom Capture & Mode Selector Bar (All 9 Modes)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                top: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.88)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mode Selector across all 9 modes
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: ScanMode.values.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final mode = ScanMode.values[index];
                        final isSelected = scannerState.currentMode == mode;
                        String label = mode.name.toUpperCase();
                        if (mode == ScanMode.idCard) label = 'ID CARD';
                        if (mode == ScanMode.businessCard) label = 'BUSINESS CARD';
                        if (mode == ScanMode.invoice) label = 'INVOICE';

                        return ChoiceChip(
                          label: Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.white,
                          backgroundColor: Colors.black54,
                          onSelected: (_) => scannerController.setScanMode(mode),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Capture Controls Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Import Gallery
                        _buildCircleButton(
                          icon: Icons.photo_library_rounded,
                          size: 48,
                          onTap: () async {
                            await scannerController.importFromGallery();
                            if (scannerState.capturedImages.isNotEmpty && context.mounted) {
                              context.push(
                                RouteNames.scanPreview,
                                extra: scannerState.capturedImages,
                              );
                            }
                          },
                        ),

                        // Large Shutter Capture Button
                        GestureDetector(
                          onTap: () async {
                            final path = await scannerController.capturePhoto();
                            if (path != null && context.mounted) {
                              if (scannerState.currentMode != ScanMode.batch) {
                                context.push(
                                  RouteNames.crop,
                                  extra: path,
                                );
                              }
                            }
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 78,
                                height: 78,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                ),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (scannerState.timerSeconds > 0)
                                Text(
                                  '${scannerState.timerSeconds}s',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Batch Thumbnail Preview Badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _buildCircleButton(
                              icon: Icons.check_circle_outline_rounded,
                              size: 48,
                              onTap: () {
                                if (scannerState.capturedImages.isNotEmpty) {
                                  context.push(
                                    RouteNames.scanPreview,
                                    extra: scannerState.capturedImages,
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Capture or import at least one page.'),
                                    ),
                                  );
                                }
                              },
                            ),
                            if (scannerState.capturedImages.isNotEmpty)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.blueAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${scannerState.capturedImages.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 44,
    Color color = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: color, size: size * 0.55),
      ),
    );
  }
}

class _GridOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.0;

    // 2 vertical lines
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);

    // 2 horizontal lines
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
