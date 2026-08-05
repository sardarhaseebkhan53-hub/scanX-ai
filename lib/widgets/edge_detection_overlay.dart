import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class EdgeDetectionOverlay extends StatelessWidget {
  final List<Offset> corners;
  final Color strokeColor;

  const EdgeDetectionOverlay({
    super.key,
    required this.corners,
    this.strokeColor = const Color(0xFF00E5FF),
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _LuxEdgePainter(corners: corners, strokeColor: strokeColor),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _LuxEdgePainter extends CustomPainter {
  final List<Offset> corners;
  final Color strokeColor;

  _LuxEdgePainter({required this.corners, required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length != 4) return;

    // Outer glow
    final glowPaint = Paint()
      ..color = strokeColor.withOpacity(0.28)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path()
      ..moveTo(corners[0].dx, corners[0].dy)
      ..lineTo(corners[1].dx, corners[1].dy)
      ..lineTo(corners[2].dx, corners[2].dy)
      ..lineTo(corners[3].dx, corners[3].dy)
      ..close();

    canvas.drawPath(path, glowPaint);

    // Main neon stroke
    final mainPaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, mainPaint);

    // Inner subtle line
    final innerPaint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, innerPaint);

    // Corner handles — luxury style
    for (final point in corners) {
      // Glow behind handle
      canvas.drawCircle(point, 18, Paint()..color = strokeColor.withOpacity(0.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      // Outer ring
      canvas.drawCircle(point, 11, Paint()..color = strokeColor..style = PaintingStyle.stroke..strokeWidth = 1.6);
      // Inner fill
      canvas.drawCircle(point, 7, Paint()..color = Colors.white..style = PaintingStyle.fill);
      canvas.drawCircle(point, 3.5, Paint()..color = strokeColor);
    }

    // L-shaped corner indicators extra luxury
    for (int i = 0; i < 4; i++) {
      final p = corners[i];
      final next = corners[(i + 1) % 4];
      final prev = corners[(i - 1 + 4) % 4];
      // small L at corner pointing inwards
      final dirToNext = (next - p);
      final dirToPrev = (prev - p);
      final unitNext = dirToNext / dirToNext.distance * 22;
      final unitPrev = dirToPrev / dirToPrev.distance * 22;

      final paintL = Paint()
        ..color = AppColors.neonCyan
        ..strokeWidth = 2.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p, p + unitNext, paintL);
      canvas.drawLine(p, p + unitPrev, paintL);
    }
  }

  @override
  bool shouldRepaint(covariant _LuxEdgePainter oldDelegate) {
    return oldDelegate.corners != corners || oldDelegate.strokeColor != strokeColor;
  }
}
