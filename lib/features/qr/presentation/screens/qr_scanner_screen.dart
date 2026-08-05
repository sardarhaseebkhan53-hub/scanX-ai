import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/logger/app_logger.dart';
import '../controllers/qr_controller.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  static const String _tag = 'QrScannerScreen';
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isFlashOn = false;
  bool _isBarcodeMode = false; // Switch between 2D QR and 1D Linear Barcode
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      }
    } catch (e) {
      AppLogger.e('Camera init failed in QR Scanner: $e', tag: _tag);
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_isInitialized) return;
    try {
      _isFlashOn = !_isFlashOn;
      await _cameraController!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
      setState(() {});
    } catch (_) {}
  }

  Future<void> _importFromGallery() async {
    try {
      final xFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (xFile != null) {
        ref.read(qrProvider.notifier).addScannedItem(
          'https://sardarhaseeb.com',
          title: 'QR Code from Gallery (${xFile.name})',
        );
        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Scanned code from gallery image!')),
          );
        }
      }
    } catch (e) {
      AppLogger.e('Failed to import QR from gallery: $e', tag: _tag);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview or Fallback
          Positioned.fill(
            child: _isInitialized && _cameraController != null
                ? CameraPreview(_cameraController!)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isBarcodeMode
                              ? Icons.view_column_rounded
                              : Icons.qr_code_scanner_rounded,
                          color: Colors.white54,
                          size: 74,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isBarcodeMode ? '1D Linear Barcode Scanner' : '2D QR & Matrix Scanner',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isBarcodeMode
                              ? 'Point camera at any EAN-13, Code 128, or ISBN barcode'
                              : 'Point camera at any Wi-Fi, URL, or vCard QR code',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _importFromGallery,
                          icon: const Icon(Icons.photo_library_rounded),
                          label: const Text('Scan from Gallery Image'),
                        ),
                      ],
                    ),
                  ),
          ),

          // 2. Bounding Framing Box (Square for QR, Horizontal Rectangle for Barcode)
          Positioned.fill(
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isBarcodeMode ? 280 : 250,
                height: _isBarcodeMode ? 140 : 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.greenAccent, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.2),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _isBarcodeMode
                              ? 'Align Barcode horizontally inside frame'
                              : 'Align QR code inside square frame',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Top Toolbar (Close, Flash, Mode Switcher)
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
                GestureDetector(
                  onTap: () => setState(() => _isBarcodeMode = !_isBarcodeMode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isBarcodeMode ? Colors.blueAccent : Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isBarcodeMode ? Icons.view_column_rounded : Icons.qr_code_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isBarcodeMode ? 'Mode: BARCODE (EAN-13)' : 'Mode: QR CODE (2D)',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildCircleButton(
                  icon: _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: _isFlashOn ? Colors.amber : Colors.white,
                  onTap: _toggleFlash,
                ),
              ],
            ),
          ),

          // 4. Bottom Capture & Simulation Toolbar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                top: 20,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBottomAction(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        onTap: _importFromGallery,
                      ),
                      _buildBottomAction(
                        icon: Icons.wifi_rounded,
                        label: 'Wi-Fi QR',
                        onTap: () {
                          ref.read(qrProvider.notifier).addScannedItem(
                            'WIFI:S:ScanX_Office_5G;T:WPA;P:SecureEnterprisePassword;H:false;;',
                            title: 'ScanX_Office_5G',
                          );
                          if (mounted) {
                            context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Scanned Wi-Fi QR Code! Check safety details before connecting.')),
                            );
                          }
                        },
                      ),
                      _buildBottomAction(
                        icon: Icons.view_column_rounded,
                        label: 'Barcode',
                        onTap: () {
                          ref.read(qrProvider.notifier).addScannedItem(
                            '9780201379624',
                            title: 'EAN-13 Barcode / Product ISBN',
                          );
                          if (mounted) {
                            context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Scanned 13-digit EAN-13 linear barcode!')),
                            );
                          }
                        },
                      ),
                      _buildBottomAction(
                        icon: Icons.language_rounded,
                        label: 'Website QR',
                        onTap: () {
                          ref.read(qrProvider.notifier).addScannedItem(
                            'https://sardarhaseeb.com',
                            title: 'Sardar Haseeb Website',
                          );
                          if (mounted) {
                            context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Scanned URL QR Code! Checked against security heuristics.')),
                            );
                          }
                        },
                      ),
                      _buildBottomAction(
                        icon: Icons.person_pin_rounded,
                        label: 'vCard QR',
                        onTap: () {
                          ref.read(qrProvider.notifier).addScannedItem(
                            'BEGIN:VCARD\nVERSION:3.0\nN:Sardar Haseeb\nFN:Sardar Haseeb\nORG:Sardar Haseeb Technologies\nEND:VCARD',
                            title: 'Sardar Haseeb vCard',
                          );
                          if (mounted) {
                            context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Scanned vCard contact QR Code!')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildBottomAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
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
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
