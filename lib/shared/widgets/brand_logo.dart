import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Vector recreation of the official ScanX AI neon logo:
/// rounded tile with gradient border + glow, corner brackets, document sheet
/// with folded corner, glowing scanline, scanner tray and gradient "AI" glyphs.
class ScanXLogoIcon extends StatelessWidget {
  final double size;
  final bool glow;

  const ScanXLogoIcon({super.key, this.size = 48, this.glow = true});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LogoPainter(glow: glow),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final bool glow;
  _LogoPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 1024.0;
    Rect r(double l, double t, double r2, double b) =>
        Rect.fromLTRB(l * k, t * k, r2 * k, b * k);
    Offset p(double x, double y) => Offset(x * k, y * k);

    final borderGrad = LinearGradient(
      colors: const [Color(0xFFD43BF7), Color(0xFF8B5CF6), Color(0xFF3B82F6), Color(0xFF2FE9FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(r(96, 96, 928, 928));

    final tileRect = r(96, 96, 928, 928);
    final tileRRect = RRect.fromRectAndRadius(tileRect, Radius.circular(208 * k));

    // Tile fill
    canvas.save();
    canvas.clipRRect(tileRRect);
    canvas.drawRect(tileRect, Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0E0818), Color(0xFF08060F), Color(0xFF04050B)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(tileRect));
    final ambient = Paint()
      ..shader = RadialGradient(colors: [
        const Color(0xFF7C5CFF).withOpacity(0.16),
        Colors.transparent,
      ]).createShader(r(212, 130, 812, 730));
    canvas.drawRect(tileRect, ambient);
    canvas.restore();

    // Border glow + border ring
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16 * k
      ..shader = borderGrad;
    if (glow) {
      canvas.saveLayer(r(0, 0, 1024, 1024), Paint());
      canvas.drawRRect(tileRRect, borderPaint
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
      canvas.restore();
    }
    canvas.drawRRect(tileRRect.deflate(8 * k), borderPaint..maskFilter = null);

    // Corner brackets
    void bracket(List<Offset> pts, Color color) {
      final path = Path()
        ..moveTo(pts[0])
        ..lineTo(pts[1])
        ..lineTo(pts[2]);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30 * k
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color;
      if (glow) {
        canvas.saveLayer(r(0, 0, 1024, 1024), Paint());
        canvas.drawPath(path, paint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
        canvas.restore();
      }
      canvas.drawPath(path, paint..maskFilter = null);
    }

    bracket([p(196, 322), p(196, 212), p(306, 212)], const Color(0xFFD24BF7));
    bracket([p(718, 212), p(828, 212), p(828, 322)], const Color(0xFF4FA0F7));
    bracket([p(196, 702), p(196, 812), p(306, 812)], const Color(0xFF8B5CF6));
    bracket([p(718, 812), p(828, 812), p(828, 702)], const Color(0xFF38D5F7));

    // Scanner tray
    final trayPath = Path()
      ..moveTo(p(306, 640))
      ..lineTo(p(718, 640))
      ..lineTo(p(772, 780))
      ..lineTo(p(252, 780))
      ..close();
    canvas.drawPath(trayPath, Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [Color(0xFF120C20), Color(0xFF080512)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(r(252, 640, 772, 780)));
    canvas.drawPath(trayPath, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20 * k
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(colors: const [Color(0xFF8B5CF6), Color(0xFF3B82F6)]).createShader(r(252, 640, 772, 780)));

    // Document sheet
    final docPath = Path()
      ..moveTo(p(352, 230))
      ..lineTo(p(598, 230))
      ..lineTo(p(672, 304))
      ..lineTo(p(672, 620))
      ..lineTo(p(352, 620))
      ..close();
    canvas.drawPath(docPath, Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFEDEAFF), Color(0xFFC9C2E8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(r(352, 230, 672, 620)));
    final foldPath = Path()
      ..moveTo(p(598, 230))
      ..lineTo(p(672, 304))
      ..lineTo(p(598, 304))
      ..close();
    canvas.drawPath(foldPath, Paint()..color = const Color(0xFFB7AEDA));

    // Document text lines
    void line(double x1, double y, double x2, Color c, [double w = 18]) {
      canvas.drawLine(p(x1, y), p(x2, y), Paint()
        ..color = c
        ..strokeWidth = w * k
        ..strokeCap = StrokeCap.round);
    }

    line(392, 330, 520, const Color(0xFF7C5CFF));
    line(392, 378, 612, const Color(0xFF6F6DFB));
    line(392, 426, 632, const Color(0xFF627DF9));
    line(392, 474, 560, const Color(0xFF5B8DEF));
    line(392, 566, 600, const Color(0xFFA79BD8), 16);
    line(392, 596, 540, const Color(0xFFA79BD8), 16);

    // Scanline with glow
    final scanShader = LinearGradient(colors: const [Color(0xFFE14BF7), Color(0xFFFFFFFF), Color(0xFF38D5F7)])
        .createShader(r(168, 512, 856, 512));
    final scan = Paint()
      ..strokeCap = StrokeCap.round
      ..shader = scanShader;
    canvas.saveLayer(r(0, 0, 1024, 1024), Paint());
    canvas.drawLine(p(168, 512), p(856, 512), scan
      ..strokeWidth = 26 * k
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
    canvas.restore();
    canvas.drawLine(p(168, 512), p(856, 512), scan
      ..strokeWidth = 10 * k
      ..maskFilter = null);

    // AI glyphs
    final aiShader = LinearGradient(colors: const [Color(0xFFA855F7), Color(0xFF7C6BFF), Color(0xFF38D5F7)])
        .createShader(r(400, 786, 580, 906));
    void aiStroke(Offset a, Offset b, double w) {
      canvas.drawLine(a, b, Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = w * k
        ..shader = aiShader);
    }

    if (glow) {
      canvas.saveLayer(r(0, 0, 1024, 1024), Paint());
      aiStroke(p(452, 786), p(408, 906), 30);
      aiStroke(p(452, 786), p(496, 906), 30);
      aiStroke(p(425, 864), p(479, 864), 26);
      aiStroke(p(562, 786), p(562, 906), 30);
      canvas.restore();
    }
    aiStroke(p(452, 786), p(408, 906), 30);
    aiStroke(p(452, 786), p(496, 906), 30);
    aiStroke(p(425, 864), p(479, 864), 26);
    aiStroke(p(562, 786), p(562, 906), 30);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// "ScanX [AI]" gradient wordmark matching the brand lockup.
class ScanXWordmark extends StatelessWidget {
  final double fontSize;
  final bool showTagline;

  const ScanXWordmark({super.key, this.fontSize = 22, this.showTagline = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Scan',
              style: TextStyle(color: AppColors.textPrimaryDark, fontSize: fontSize, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.1),
            ),
            ShaderMask(
              shaderCallback: (rect) => LinearGradient(colors: const [Color(0xFFD43BF7), Color(0xFF8B5CF6), Color(0xFF38D5F7)]).createShader(rect),
              child: Text(
                'X',
                style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.1),
              ),
            ),
            const SizedBox(width: fontSize * 0.28),
            Container(
              padding: EdgeInsets.symmetric(horizontal: fontSize * 0.24, vertical: fontSize * 0.08),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(fontSize * 0.28),
                gradient: AppColors.brandGradient,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: fontSize * 0.22, vertical: fontSize * 0.06),
                decoration: BoxDecoration(
                  color: const Color(0xFF05060E),
                  borderRadius: BorderRadius.circular(fontSize * 0.2),
                ),
                child: ShaderMask(
                  shaderCallback: (rect) => LinearGradient(colors: const [Color(0xFFA855F7), Color(0xFF38D5F7)]).createShader(rect),
                  child: Text(
                    'AI',
                    style: TextStyle(color: Colors.white, fontSize: fontSize * 0.62, fontWeight: FontWeight.w900, height: 1.15),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 3),
          ShaderMask(
            shaderCallback: (rect) => LinearGradient(colors: const [Color(0xFFD43BF7), Color(0xFF8B5CF6), Color(0xFF38D5F7)]).createShader(rect),
            child: Text(
              'SMART SCANNER. SMARTER AI.',
              style: TextStyle(color: Colors.white, fontSize: fontSize * 0.36, fontWeight: FontWeight.w700, letterSpacing: 2.2),
            ),
          ),
        ],
      ],
    );
  }
}

/// Golden premium crown used for Pro surfaces (home header, paywall, banners).
class PremiumCrownIcon extends StatelessWidget {
  final double size;
  const PremiumCrownIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _CrownPainter());
  }
}

class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 100.0;
    Offset p(double x, double y) => Offset(x * k, y * k);
    final shader = const LinearGradient(
      colors: [Color(0xFFFF8C00), Color(0xFFFFC857), Color(0xFFFFE08A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(p(12, 70))
      ..lineTo(p(12, 38))
      ..lineTo(p(30, 52))
      ..lineTo(p(50, 24))
      ..lineTo(p(70, 52))
      ..lineTo(p(88, 38))
      ..lineTo(p(88, 70))
      ..close();

    canvas.saveLayer(Rect.fromLTRB(-size.width, -size.height, size.width * 2, size.height * 2), Paint());
    canvas.drawPath(path, Paint()..shader = shader..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.restore();
    canvas.drawPath(path, Paint()..shader = shader);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(12 * k, 76 * k, 88 * k, 88 * k), Radius.circular(4 * k)),
      Paint()..shader = shader,
    );
    for (final g in [p(12, 30), p(50, 16), p(88, 30)]) {
      canvas.drawCircle(g, 5 * k, Paint()..shader = shader);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Full brand lockup used on onboarding, profile and about surfaces.
class ScanXBrandLockup extends StatelessWidget {
  final double iconSize;

  const ScanXBrandLockup({super.key, this.iconSize = 96});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScanXLogoIcon(size: iconSize),
        SizedBox(height: iconSize * 0.18),
        ScanXWordmark(fontSize: iconSize * 0.34, showTagline: true),
      ],
    );
  }
}
