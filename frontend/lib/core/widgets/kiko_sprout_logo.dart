import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Crisp, scalable vector Kiko Leaf / Sprout mark.
/// Faithfully reproduces the brand logo with two vibrant lime green leaves
/// and an organic connecting stem.
class KikoSproutLogo extends StatelessWidget {
  const KikoSproutLogo({
    super.key,
    this.size = 36.0,
    this.color = KikoColors.vibrantLime,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _KikoSproutPainter(color: color),
      ),
    );
  }
}

class _KikoSproutPainter extends CustomPainter {
  const _KikoSproutPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Canvas coordinate space normalized to 48x48
    final scale = size.width / 48.0;
    canvas.scale(scale, scale);

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final stemPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Stem: curves gently from bottom up to junction
    final stemPath = Path()
      ..moveTo(23.5, 42.0)
      ..cubicTo(23.5, 34.0, 24.5, 28.0, 25.0, 23.0);
    canvas.drawPath(stemPath, stemPaint);

    // Left leaf: organic teardrop tilted towards upper-left
    final leftLeaf = Path()
      ..moveTo(24.5, 24.5)
      ..cubicTo(19.0, 26.5, 12.0, 24.0, 7.5, 17.5)
      ..cubicTo(5.5, 14.0, 6.0, 10.5, 9.5, 10.0)
      ..cubicTo(15.5, 9.0, 22.0, 15.0, 24.5, 24.5)
      ..close();
    canvas.drawPath(leftLeaf, fillPaint);

    // Right leaf: slightly larger lush leaf pointing up and right
    final rightLeaf = Path()
      ..moveTo(24.0, 23.0)
      ..cubicTo(25.5, 16.0, 31.0, 10.0, 38.5, 8.5)
      ..cubicTo(41.5, 8.0, 43.5, 10.5, 42.5, 14.5)
      ..cubicTo(40.5, 21.0, 33.5, 26.0, 24.0, 23.0)
      ..close();
    canvas.drawPath(rightLeaf, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _KikoSproutPainter oldDelegate) =>
      oldDelegate.color != color;
}
