import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Mascot Speech Card featuring Tofu the turtle and a cheerful speech bubble
class MascotSpeechCard extends StatelessWidget {
  const MascotSpeechCard({
    super.key,
    required this.title,
    required this.message,
    this.avatarAsset = 'assets/images/tofu_mascot.png',
  });

  final String title;
  final String message;
  final String avatarAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KikoColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: KikoColors.surfaceContainerHigh.withValues(alpha: 0.7),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Mascot Avatar Container
          Stack(
            children: [
              Container(
                width: 68,
                height: 68,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: KikoColors.surfaceContainerHigh.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: KikoColors.surfaceContainerHighest,
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    avatarAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.cruelty_free,
                          size: 32,
                          color: KikoColors.primaryContainer,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Online Indicator Dot
              Positioned(
                bottom: 3,
                right: 3,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: KikoColors.primaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: KikoColors.surfaceContainerLowest,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Speech Bubble
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: KikoColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: KikoColors.surfaceContainerHigh.withValues(alpha: 0.7),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: KikoTypography.headlineMd(
                          color: KikoColors.primaryContainer,
                          fontWeight: FontWeight.w700,
                        ).copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        message,
                        style: KikoTypography.bodySm(
                          color: KikoColors.onSurface,
                        ).copyWith(
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                // Bubble Triangle Arrow
                Positioned(
                  left: -6,
                  child: CustomPaint(
                    size: const Size(6, 12),
                    painter: _SpeechTrianglePainter(
                      color: KikoColors.surfaceContainerLow,
                      borderColor: KikoColors.surfaceContainerHigh.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeechTrianglePainter extends CustomPainter {
  const _SpeechTrianglePainter({
    required this.color,
    required this.borderColor,
  });

  final Color color;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawPath(path, fillPaint);
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(0, size.height / 2),
      borderPaint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SpeechTrianglePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.borderColor != borderColor;
}
