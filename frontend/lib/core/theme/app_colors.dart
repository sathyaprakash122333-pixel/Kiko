import 'package:flutter/material.dart';

/// Obsidian Kinetic Color Palette for Kiko
/// Sourced directly from `design/stitch/stitch_kiko_gamified_learning_app_ui/obsidian_kinetic/DESIGN.md`
abstract final class KikoColors {
  // Canvas & Surfaces
  static const Color background = Color(0xFF111413);
  static const Color surface = Color(0xFF111413);
  static const Color surfaceDim = Color(0xFF111413);
  static const Color surfaceBright = Color(0xFF373A39);
  static const Color surfaceContainerLowest = Color(0xFF0C0F0E);
  static const Color surfaceContainerLow = Color(0xFF191C1B);
  static const Color surfaceContainer = Color(0xFF1D201F);
  static const Color surfaceContainerHigh = Color(0xFF282B29);
  static const Color surfaceContainerHighest = Color(0xFF323534);

  // Content & Text
  static const Color onSurface = Color(0xFFE1E3E1);
  static const Color onSurfaceVariant = Color(0xFFC4C9AE);
  static const Color textHeadline = Color(0xFFF4F6F4);
  static const Color textMuted = Color(0xFF8E9792);
  static const Color textPlaceholder = Color(0xFF4C5550);

  // Structural Outlines & Dividers
  static const Color outline = Color(0xFF8E937A);
  static const Color outlineVariant = Color(0xFF434934);
  static const Color hairline = Color(0x14FFFFFF); // rgba(255, 255, 255, 0.08)
  static const Color subtleBorder = Color(0xFF2C322F);

  // Primary Accent: Piercing Electric Chartreuse / Lime
  static const Color primary = Color(0xFFF9FFE0);
  static const Color onPrimary = Color(0xFF273500);
  static const Color primaryContainer = Color(0xFFBDF127);
  static const Color onPrimaryContainer = Color(0xFF516B00);
  static const Color primaryFixed = Color(0xFFC0F42B);
  static const Color primaryFixedDim = Color(0xFFA6D700);
  static const Color surfaceTint = Color(0xFFA6D700);

  // Tactile 3D Bevel Shadows
  static const Color tactileShadowPrimary = Color(0xFF516B00);
  static const Color tactileShadowLime = Color(0xFF8EBD05);

  // Secondary
  static const Color secondary = Color(0xFFC4C7C4);
  static const Color onSecondary = Color(0xFF2D312F);
  static const Color secondaryContainer = Color(0xFF444845);
  static const Color onSecondaryContainer = Color(0xFFB2B6B3);

  // Tertiary
  static const Color tertiary = Color(0xFFF8FEF9);
  static const Color onTertiary = Color(0xFF2C322F);
  static const Color tertiaryContainer = Color(0xFFDBE1DC);

  // Inverse
  static const Color inverseSurface = Color(0xFFE1E3E1);
  static const Color inverseOnSurface = Color(0xFF2E3130);

  // Alerts & Errors
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);
}
