import 'package:flutter/material.dart';

class EdgeDetectionOverlay extends StatelessWidget {
  final List<Offset> corners;
  final Color strokeColor;

  const EdgeDetectionOverlay({
    super.key,
    required this.corners,
    this.strokeColor = const Color(0xFF10B981),
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _EdgePainter(corners: corners, strokeColor: strokeColor),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _EdgePainter extends CustomPainter {
  final List<Offset> corners;
  final Color strokeColor;

  _EdgePainter({required this.corners, required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length != 4) return;

    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(corners[0].dx, corners[0].dy)
      ..lineTo(corners[1].dx, corners[1].dy)
      ..lineTo(corners[2].dx, corners[2].dy)
      ..lineTo(corners[3].dx, corners[3].dy)
      ..close();

    canvas.drawPath(path, paint);

    // Draw handle dots at 4 corners
    final dotPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;

    for (final point in corners) {
      canvas.drawCircle(point, 8.0, dotPaint);
      canvas.drawCircle(
        point,
        4.0,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EdgePainter oldDelegate) {
    return oldDelegate.corners != corners || oldDelegate.strokeColor != strokeColor;
  }
}
