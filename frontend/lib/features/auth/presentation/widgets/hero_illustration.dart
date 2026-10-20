import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Hero illustration displaying the Kiko owl mascot coding at a laptop with 'K' logo,
/// in front of a code editor window with '</>' and code lines, next to a stack of books.
/// Sourced directly from the reference visual design.
/// PRESERVED: This owl illustration is an intentional part of Kiko's login identity.
class HeroIllustration extends StatelessWidget {
  const HeroIllustration({
    super.key,
    this.maxWidth = 360.0,
    this.size, // optional size override for backward compatibility
  });

  final double maxWidth;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = size ?? maxWidth;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: AspectRatio(
          aspectRatio: 415 / 215,
          child: Image.asset(
            'assets/images/kiko_mascot_owl_coding.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              return _VectorFallbackIllustration(size: effectiveMaxWidth);
            },
          ),
        ),
      ),
    );
  }
}

/// Fallback illustration in case the image asset fails to load
class _VectorFallbackIllustration extends StatelessWidget {
  const _VectorFallbackIllustration({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * (215 / 415),
      decoration: BoxDecoration(
        color: KikoColors.secondarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: KikoColors.border,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.code_rounded,
              color: KikoColors.primaryForest,
              size: 42,
            ),
            SizedBox(height: 6),
            Text(
              'Kiko Coding Mascot',
              style: TextStyle(
                color: KikoColors.primaryForest,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
