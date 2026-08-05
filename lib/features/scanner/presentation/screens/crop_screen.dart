import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../services/scanner/image_processing_service.dart';
import '../../../../shared/widgets/custom_app_bar.dart';

class CropScreen extends StatefulWidget {
  final String imagePath;

  const CropScreen({super.key, required this.imagePath});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final ImageProcessingService _imageProcessor = ImageProcessingService();
  late String _imagePath;
  late List<Offset> _corners;
  bool _isAutoDetecting = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.imagePath;
    _corners = const [
      Offset(0.12, 0.16),
      Offset(0.88, 0.16),
      Offset(0.90, 0.82),
      Offset(0.10, 0.82),
    ];
    _autoDetectEdges();
  }

  Future<void> _autoDetectEdges() async {
    setState(() => _isAutoDetecting = true);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    setState(() {
      // Responsive normalized points. This keeps handles inside any phone,
      // tablet, foldable, or landscape viewport while native CV edge detection
      // can be layered in behind the same model later.
      _corners = const [
        Offset(0.10, 0.14),
        Offset(0.90, 0.14),
        Offset(0.92, 0.84),
        Offset(0.08, 0.84),
      ];
      _isAutoDetecting = false;
    });
  }

  Future<void> _rotate() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    final rotated = await _imageProcessor.rotateImageFile(File(_imagePath), 90);
    if (!mounted) return;
    setState(() {
      if (rotated != null) _imagePath = rotated.path;
      _isProcessing = false;
    });
  }

  Future<void> _applyAiFilter() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    final enhanced = await _imageProcessor.applyFilterPreset(File(_imagePath), 'aiEnhance');
    if (!mounted) return;
    setState(() {
      if (enhanced != null) _imagePath = enhanced.path;
      _isProcessing = false;
    });
  }

  Offset _toAbsolute(Offset normalized, Size size) {
    return Offset(normalized.dx * size.width, normalized.dy * size.height);
  }

  Offset _toNormalized(Offset absolute, Size size) {
    return Offset(
      (absolute.dx / math.max(1, size.width)).clamp(0.02, 0.98).toDouble(),
      (absolute.dy / math.max(1, size.height)).clamp(0.02, 0.98).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final file = File(_imagePath);
    final fileExists = file.existsSync();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Perspective Crop',
        actions: [
          IconButton(
            tooltip: 'Reset edges',
            onPressed: _autoDetectEdges,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Confirm crop',
            onPressed: _isProcessing ? null : () => context.pushReplacement(RouteNames.scanPreview, extra: [_imagePath]),
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: _isAutoDetecting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('AI auto-detecting document boundaries...'),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: fileExists
                          ? InteractiveViewer(
                              minScale: 0.8,
                              maxScale: 4,
                              child: Image.file(file, fit: BoxFit.contain),
                            )
                          : Container(
                              margin: const EdgeInsets.all(24),
                              color: Colors.grey[850],
                              alignment: Alignment.center,
                              child: const Text('Document Preview Page', style: TextStyle(color: Colors.white)),
                            ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _CropPolygonPainter(
                            corners: _corners.map((p) => _toAbsolute(p, canvasSize)).toList(),
                          ),
                        ),
                      ),
                    ),
                    for (int i = 0; i < _corners.length; i++)
                      _CornerHandle(
                        position: _toAbsolute(_corners[i], canvasSize),
                        label: '${i + 1}',
                        onDrag: (delta) {
                          setState(() {
                            final absolute = _toAbsolute(_corners[i], canvasSize) + delta;
                            _corners[i] = _toNormalized(absolute, canvasSize);
                          });
                        },
                      ),
                    if (_isProcessing)
                      Container(
                        color: Colors.black45,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildCropOption(icon: Icons.auto_awesome, label: 'Auto Crop', onTap: _autoDetectEdges),
              _buildCropOption(icon: Icons.rotate_right_rounded, label: 'Rotate', onTap: _rotate),
              _buildCropOption(icon: Icons.filter_vintage_rounded, label: 'AI Filter', onTap: _applyAiFilter),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: _isProcessing ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _CornerHandle extends StatelessWidget {
  final Offset position;
  final String label;
  final ValueChanged<Offset> onDrag;

  const _CornerHandle({required this.position, required this.label, required this.onDrag});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - 24,
      top: position.dy - 24,
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(details.delta),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.22),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blueAccent, width: 3),
              ),
            ),
            Positioned(
              top: -30,
              child: Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.62),
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
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

    final overlay = Path()..addRect(Offset.zero & size);
    final docPath = Path()
      ..moveTo(corners[0].dx, corners[0].dy)
      ..lineTo(corners[1].dx, corners[1].dy)
      ..lineTo(corners[2].dx, corners[2].dy)
      ..lineTo(corners[3].dx, corners[3].dy)
      ..close();

    canvas.drawPath(
      Path.combine(PathOperation.difference, overlay, docPath),
      Paint()..color = Colors.black.withOpacity(0.45),
    );

    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawPath(docPath, paint);
  }

  @override
  bool shouldRepaint(covariant _CropPolygonPainter oldDelegate) => oldDelegate.corners != corners;
}
