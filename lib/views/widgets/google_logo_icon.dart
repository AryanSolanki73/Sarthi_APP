import 'package:flutter/material.dart';

/// Renders the official multi-colored Google "G" logo using Canvas.
///
/// Self-contained with zero image asset dependencies.
class GoogleLogoIcon extends StatelessWidget {
  const GoogleLogoIcon({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double strokeWidth = w * 0.22;
    final Rect arcRect = Rect.fromCenter(
      center: Offset(w / 2, h / 2),
      width: w - strokeWidth,
      height: h - strokeWidth,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // 1. Red (top arc)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(arcRect, -2.5, 1.8, false, paint);

    // 2. Yellow (bottom-left arc)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(arcRect, 2.3, 1.5, false, paint);

    // 3. Green (bottom arc)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(arcRect, 0.6, 1.7, false, paint);

    // 4. Blue (right arc)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(arcRect, -0.7, 1.3, false, paint);

    // 5. Blue horizontal crossbar
    final barPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF4285F4);

    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        w * 0.44,
        h / 2 - strokeWidth / 2,
        w * 0.56,
        strokeWidth,
      ),
      Radius.circular(strokeWidth * 0.15),
    );
    canvas.drawRRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

