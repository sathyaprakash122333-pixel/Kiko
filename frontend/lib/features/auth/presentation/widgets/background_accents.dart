import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Renders the clean, elegant light-theme backdrop for Kiko login
/// with white surface, subtle pale-mint ambient glows, and delicate curved geometric arcs
/// in the top-left and bottom-right corners.
class BackgroundAccents extends StatelessWidget {
  const BackgroundAccents({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: KikoColors.background,
      child: Stack(
        children: [
          // Ambient corner glows and curved geometric accents
          Positioned.fill(
            child: CustomPaint(
              painter: _LoginLightBackdropPainter(),
            ),
          ),
          // Child content
          child,
        ],
      ),
    );
  }
}

class _LoginLightBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Top-left subtle pale-mint radial glow
    final tlGlowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-1.0, -0.9),
        radius: 0.85,
        colors: [
          const Color(0xFFDDF4E5).withValues(alpha: 0.55),
          const Color(0xFFEDF5EF).withValues(alpha: 0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, tlGlowPaint);

    // 2. Bottom-right subtle pale-mint radial glow
    final brGlowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(1.0, 0.9),
        radius: 0.85,
        colors: [
          const Color(0xFFDDF4E5).withValues(alpha: 0.50),
          const Color(0xFFEDF5EF).withValues(alpha: 0.20),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, brGlowPaint);

    // 3. Top-left delicate curved arc line
    final double radiusTL =
        math.min(size.width * 0.72, size.height * 0.42).clamp(200.0, 520.0);
    final Offset centerTL = Offset(-radiusTL * 0.12, -radiusTL * 0.12);

    final linePaintTL = Paint()
      ..color = KikoColors.primaryForest.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..isAntiAlias = true;
    canvas.drawCircle(centerTL, radiusTL, linePaintTL);

    // 4. Bottom-right delicate curved arc line
    final double radiusBR =
        math.min(size.width * 0.72, size.height * 0.42).clamp(200.0, 520.0);
    final Offset centerBR =
        Offset(size.width + radiusBR * 0.12, size.height + radiusBR * 0.12);

    final linePaintBR = Paint()
      ..color = KikoColors.primaryForest.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..isAntiAlias = true;
    canvas.drawCircle(centerBR, radiusBR, linePaintBR);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
