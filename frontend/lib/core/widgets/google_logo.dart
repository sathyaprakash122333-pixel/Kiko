import 'package:flutter/material.dart';

/// Pixel-perfect vector Google 'G' Logo
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 22.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    // Blue: Right bar & upper-right arc
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final bluePath = Path()
      ..moveTo(23.75, 12.27)
      ..cubicTo(23.75, 11.48, 23.68, 10.73, 23.55, 10.01)
      ..lineTo(12.0, 10.01)
      ..lineTo(12.0, 14.74)
      ..lineTo(18.59, 14.74)
      ..cubicTo(18.30, 16.27, 17.43, 17.57, 16.12, 18.44)
      ..lineTo(16.12, 21.57)
      ..lineTo(20.11, 21.57)
      ..cubicTo(22.45, 19.41, 23.75, 16.14, 23.75, 12.27)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Green: Bottom arc
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final greenPath = Path()
      ..moveTo(12.0, 24.0)
      ..cubicTo(15.24, 24.0, 17.96, 22.92, 19.98, 21.05)
      ..lineTo(16.0, 17.96)
      ..cubicTo(14.89, 18.70, 13.52, 19.14, 12.0, 19.14)
      ..cubicTo(8.87, 19.14, 6.22, 17.02, 5.27, 14.18)
      ..lineTo(1.16, 14.18)
      ..lineTo(1.16, 17.37)
      ..cubicTo(3.19, 21.39, 7.34, 24.0, 12.0, 24.0)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // Yellow: Bottom-left arc
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final yellowPath = Path()
      ..moveTo(5.27, 14.29)
      ..cubicTo(5.02, 13.57, 4.89, 12.80, 4.89, 12.0)
      ..cubicTo(4.89, 11.20, 5.02, 10.43, 5.27, 9.71)
      ..lineTo(5.27, 6.52)
      ..lineTo(1.16, 6.52)
      ..cubicTo(0.42, 8.19, 0.0, 10.05, 0.0, 12.0)
      ..cubicTo(0.0, 13.95, 0.42, 15.81, 1.16, 17.48)
      ..lineTo(5.27, 14.29)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Red: Top arc
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    final redPath = Path()
      ..moveTo(12.0, 4.86)
      ..cubicTo(13.76, 4.86, 15.34, 5.47, 16.59, 6.66)
      ..lineTo(20.08, 3.17)
      ..cubicTo(17.95, 1.19, 15.24, 0.0, 12.0, 0.0)
      ..cubicTo(7.34, 0.0, 3.19, 2.61, 1.16, 6.63)
      ..lineTo(5.27, 9.82)
      ..cubicTo(6.22, 6.98, 8.87, 4.86, 12.0, 4.86)
      ..close();
    canvas.drawPath(redPath, redPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
