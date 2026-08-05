import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

class CropScreen extends StatefulWidget {
  final String imagePath;

  const CropScreen({super.key, required this.imagePath});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  // Default corner coordinates
  late List<Offset> _corners;
  bool _isAutoDetecting = true;

  @override
  void initState() {
    super.initState();
    // Initialize default corners for interactive cropping
    _corners = [
      const Offset(60, 100),
      const Offset(300, 100),
      const Offset(320, 500),
      const Offset(40, 500),
    ];
    // Simulate brief auto-edge AI detection
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() => _isAutoDetecting = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.imagePath);
    final fileExists = file.existsSync();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Perspective Crop',
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _corners = [
                  const Offset(20, 20),
                  Offset(MediaQuery.of(context).size.width - 20, 20),
                  Offset(MediaQuery.of(context).size.width - 20, 480),
                  const Offset(20, 480),
                ];
              });
            },
            child: const Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () {
              context.push(
                RouteNames.scanPreview,
                extra: [widget.imagePath],
              );
            },
            child: const Text('Confirm'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isAutoDetecting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('AI Auto-detecting document boundaries...'),
                ],
              ),
            )
          : Stack(
              children: [
                Center(
                  child: fileExists
                      ? Image.file(file, fit: BoxFit.contain)
                      : Container(
                          width: double.infinity,
                          height: 480,
                          color: Colors.grey[800],
                          alignment: Alignment.center,
                          child: const Text('Document Preview Page'),
                        ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CropPolygonPainter(corners: _corners),
                  ),
                ),
                // Draggable corner handles
                for (int i = 0; i < _corners.length; i++)
                  Positioned(
                    left: _corners[i].dx - 20,
                    top: _corners[i].dy - 20,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _corners[i] = _corners[i] + details.delta;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blueAccent, width: 3),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCropOption(icon: Icons.auto_awesome, label: 'Auto Crop', onTap: () {}),
              _buildCropOption(icon: Icons.rotate_right_rounded, label: 'Rotate', onTap: () {}),
              _buildCropOption(icon: Icons.filter_vintage_rounded, label: 'AI Filter', onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _CropPolygonPainter extends CustomPainter {
  final List<Offset> corners;

  _CropPolygonPainter({required this.corners});

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length != 4) return;

    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(corners[0].dx, corners[0].dy)
      ..lineTo(corners[1].dx, corners[1].dy)
      ..lineTo(corners[2].dx, corners[2].dy)
      ..lineTo(corners[3].dx, corners[3].dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CropPolygonPainter oldDelegate) => true;
}
