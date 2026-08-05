import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/logger/app_logger.dart';
import '../controllers/qr_controller.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  static const String _tag = 'QrScannerScreen';
  late final MobileScannerController _scannerController;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isBarcodeMode = false;
  bool _handledResult = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    try {
      await _scannerController.toggleTorch();
      if (mounted) setState(() => _isTorchOn = !_isTorchOn);
    } catch (e) {
      AppLogger.e('QR torch toggle failed: $e', tag: _tag);
    }
  }

  Future<void> _importFromGallery() async {
    try {
      final xFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (xFile == null) return;
      final capture = await _scannerController.analyzeImage(xFile.path);
      final raw = capture == null ? null : _firstReadableValue(capture.barcodes);
      if (raw == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No QR or barcode found in selected image.'), backgroundColor: Color(0xFF3A1220)),
          );
        }
        return;
      }
      _completeScan(raw, title: 'Code from ${xFile.name}');
    } catch (e) {
      AppLogger.e('Failed to import QR from gallery: $e', tag: _tag);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery scan failed: $e'), backgroundColor: const Color(0xFF3A1220)),
        );
      }
    }
  }

  String? _firstReadableValue(List<Barcode> barcodes) {
    for (final barcode in barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  void _handleCapture(BarcodeCapture capture) {
    if (_handledResult) return;
    final raw = _firstReadableValue(capture.barcodes);
    if (raw == null) return;
    _completeScan(raw);
  }

  void _completeScan(String raw, {String? title}) {
    if (_handledResult) return;
    _handledResult = true;
    ref.read(qrProvider.notifier).addScannedItem(raw, title: title);
    if (!mounted) return;
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scanned code saved to history.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final frameWidth = (_isBarcodeMode
            ? (size.width * 0.78).clamp(240.0, 420.0)
            : (size.shortestSide * 0.68).clamp(220.0, 340.0))
        .toDouble();
    final frameHeight = (_isBarcodeMode ? (frameWidth * 0.42).clamp(110.0, 170.0) : frameWidth).toDouble();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _handleCapture,
              errorBuilder: (context, error, child) => _ScannerError(onGallery: _importFromGallery),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.0,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.64)],
                ),
              ),
            ),
          ),
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: frameWidth,
              height: frameHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_isBarcodeMode ? 18 : 28),
                border: Border.all(color: Colors.greenAccent, width: 3),
                boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.25), blurRadius: 22, spreadRadius: 2)],
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                  child: Text(
                    _isBarcodeMode ? 'Align 1D barcode horizontally' : 'Align QR code inside frame',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _buildCircleButton(icon: Icons.close_rounded, onTap: () => Navigator.of(context).pop()),
                  const Spacer(),
                  Flexible(
                    child: GestureDetector(
                      onTap: () => setState(() => _isBarcodeMode = !_isBarcodeMode),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isBarcodeMode ? Colors.blueAccent : Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_isBarcodeMode ? Icons.view_column_rounded : Icons.qr_code_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _isBarcodeMode ? 'BARCODE' : 'QR CODE',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildCircleButton(icon: Icons.cameraswitch_rounded, onTap: () => _scannerController.switchCamera()),
                  const SizedBox(width: 8),
                  _buildCircleButton(icon: _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded, color: _isTorchOn ? Colors.amber : Colors.white, onTap: _toggleFlash),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 22, top: 20, left: 20, right: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, Colors.black.withOpacity(0.9)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 18,
                runSpacing: 10,
                children: [
                  _buildBottomAction(icon: Icons.photo_library_rounded, label: 'Gallery', onTap: _importFromGallery),
                  _buildBottomAction(icon: Icons.qr_code_2_rounded, label: 'QR', onTap: () => setState(() => _isBarcodeMode = false)),
                  _buildBottomAction(icon: Icons.view_column_rounded, label: 'Barcode', onTap: () => setState(() => _isBarcodeMode = true)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap, double size = 44, Color color = Colors.white}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
        child: Icon(icon, color: color, size: size * 0.55),
      ),
    );
  }

  Widget _buildBottomAction({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: Colors.white30)),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 6),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ScannerError extends StatelessWidget {
  final VoidCallback onGallery;
  const _ScannerError({required this.onGallery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_scanner_rounded, color: Colors.white54, size: 74),
            const SizedBox(height: 16),
            const Text('Camera unavailable', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Allow camera permission or scan a saved image from gallery.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton.icon(onPressed: onGallery, icon: const Icon(Icons.photo_library_rounded), label: const Text('Scan from Gallery')),
          ],
        ),
      ),
    );
  }
}
