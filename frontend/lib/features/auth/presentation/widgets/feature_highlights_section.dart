import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Compact bottom feature highlights:
/// 1. Interactive Lessons — Learn at your own pace
/// 2. Track Progress — See your growth
/// 3. Secure & Reliable — Your data is safe with us
class FeatureHighlightsSection extends StatelessWidget {
  const FeatureHighlightsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool isVeryNarrow = width < 345;

        final double titleSize = isVeryNarrow ? 11.5 : 13.0;
        final double subtitleSize = isVeryNarrow ? 10.0 : 11.5;
        final double iconSize = isVeryNarrow ? 22.0 : 26.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Interactive Lessons
            Expanded(
              child: _FeatureItem(
                icon: _LightningBoltIcon(size: iconSize),
                title: 'Interactive Lessons',
                subtitle: 'Learn at your own pace',
                titleSize: titleSize,
                subtitleSize: subtitleSize,
              ),
            ),

            // Divider 1
            _VerticalFeatureDivider(height: isVeryNarrow ? 40 : 46),

            // 2. Track Progress
            Expanded(
              child: _FeatureItem(
                icon: _BarChartIcon(size: iconSize),
                title: 'Track Progress',
                subtitle: 'See your growth',
                titleSize: titleSize,
                subtitleSize: subtitleSize,
              ),
            ),

            // Divider 2
            _VerticalFeatureDivider(height: isVeryNarrow ? 40 : 46),

            // 3. Secure & Reliable
            Expanded(
              child: _FeatureItem(
                icon: _ShieldCheckIcon(size: iconSize),
                title: 'Secure & Reliable',
                subtitle: 'Your data is safe with us',
                titleSize: titleSize,
                subtitleSize: subtitleSize,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.titleSize,
    required this.subtitleSize,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final double titleSize;
  final double subtitleSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          SizedBox(
            height: 28,
            child: Center(child: icon),
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: KikoColors.warmWhite,
              fontWeight: FontWeight.w700,
              fontSize: titleSize,
              letterSpacing: -0.1,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),

          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: KikoColors.mutedMintGray,
              fontWeight: FontWeight.w400,
              fontSize: subtitleSize,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalFeatureDivider extends StatelessWidget {
  const _VerticalFeatureDivider({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.0,
      height: height,
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            KikoColors.vibrantLime.withValues(alpha: 0.05),
            KikoColors.vibrantLime.withValues(alpha: 0.35),
            KikoColors.vibrantLime.withValues(alpha: 0.05),
          ],
        ),
      ),
    );
  }
}

/// Custom stroked lime green lightning bolt icon
class _LightningBoltIcon extends StatelessWidget {
  const _LightningBoltIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LightningBoltPainter(),
      ),
    );
  }
}

class _LightningBoltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    final strokePaint = Paint()
      ..color = KikoColors.vibrantLime
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final path = Path()
      ..moveTo(13.5, 2.0)
      ..lineTo(5.5, 13.0)
      ..lineTo(12.0, 13.0)
      ..lineTo(10.5, 22.0)
      ..lineTo(18.5, 11.0)
      ..lineTo(12.0, 11.0)
      ..close();

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom stroked lime green 3-bar histogram chart icon
class _BarChartIcon extends StatelessWidget {
  const _BarChartIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BarChartPainter(),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = KikoColors.vibrantLime
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Bar 1 (Left - medium height)
    final r1 = RRect.fromRectAndRadius(
      const Rect.fromLTWH(3.5, 10.0, 4.5, 12.0),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(r1, paint);

    // Bar 2 (Middle - tallest)
    final r2 = RRect.fromRectAndRadius(
      const Rect.fromLTWH(9.75, 4.0, 4.5, 18.0),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(r2, paint);

    // Bar 3 (Right - intermediate)
    final r3 = RRect.fromRectAndRadius(
      const Rect.fromLTWH(16.0, 8.0, 4.5, 14.0),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(r3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom stroked lime green shield with checkmark icon
class _ShieldCheckIcon extends StatelessWidget {
  const _ShieldCheckIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShieldCheckPainter(),
      ),
    );
  }
}

class _ShieldCheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    final strokePaint = Paint()
      ..color = KikoColors.vibrantLime
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Shield outline
    final shieldPath = Path()
      ..moveTo(12.0, 2.5)
      ..lineTo(20.0, 5.5)
      ..cubicTo(20.0, 13.0, 16.5, 18.5, 12.0, 21.5)
      ..cubicTo(7.5, 18.5, 4.0, 13.0, 4.0, 5.5)
      ..close();
    canvas.drawPath(shieldPath, strokePaint);

    // Checkmark inside shield
    final checkPaint = Paint()
      ..color = KikoColors.vibrantLime
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final checkPath = Path()
      ..moveTo(8.5, 12.0)
      ..lineTo(11.0, 14.5)
      ..lineTo(15.5, 9.5);
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
