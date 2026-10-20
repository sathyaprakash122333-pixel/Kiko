import 'package:flutter/material.dart';

/// Centralized Light Palette Design System for Kiko
/// Palette Specification:
/// - Background: #FFFFFF
/// - Secondary surface: #F5F7F5
/// - Primary forest green: #174D36
/// - Secondary emerald: #27865A
/// - Tertiary pale mint: #DDF4E5
/// - Primary text: #26352D
/// - Secondary text: #66756C
/// - Borders: #E1E8E2
/// - Hover background: #EDF5EF
/// - Error: accessible dark red (#BA1A1A)
/// - Success: readable green (#27865A)
abstract final class KikoColors {
  // Pure canvas & secondary surface
  static const Color background = Color(0xFFFFFFFF);
  static const Color secondarySurface = Color(0xFFF5F7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFF5F7F5);

  // Primary Actions: Forest Green
  static const Color primaryForest = Color(0xFF174D36);
  static const Color primary = Color(0xFF174D36);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Secondary & Progress: Emerald
  static const Color secondaryEmerald = Color(0xFF27865A);
  static const Color secondary = Color(0xFF27865A);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // Tertiary & Highlights: Pale Mint
  static const Color tertiaryMint = Color(0xFFDDF4E5);
  static const Color tertiary = Color(0xFFDDF4E5);
  static const Color onTertiary = Color(0xFF174D36);

  // Content & Text
  static const Color textPrimary = Color(0xFF26352D);
  static const Color textSecondary = Color(0xFF66756C);
  static const Color onSurface = Color(0xFF26352D);
  static const Color onSurfaceVariant = Color(0xFF66756C);
  static const Color textHeadline = Color(0xFF26352D);
  static const Color textMuted = Color(0xFF66756C);
  static const Color textPlaceholder = Color(0xFF8E9B93);

  // Structural Outlines & Dividers
  static const Color border = Color(0xFFE1E8E2);
  static const Color outline = Color(0xFFE1E8E2);
  static const Color outlineVariant = Color(0xFFE1E8E2);
  static const Color divider = Color(0xFFE1E8E2);
  static const Color hairline = Color(0x1F26352D);
  static const Color subtleBorder = Color(0xFFE1E8E2);

  // Interactive states
  static const Color hover = Color(0xFFEDF5EF);
  static const Color hoverBackground = Color(0xFFEDF5EF);

  // Semantic Alerts & Statuses
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  static const Color success = Color(0xFF27865A);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFDDF4E5);
  static const Color onSuccessContainer = Color(0xFF0F3826);

  static const Color warning = Color(0xFFB45309);
  static const Color warningContainer = Color(0xFFFEF3C7);

  // Material 3 Surface Containers remapped to light palette
  static const Color surfaceDim = Color(0xFFF5F7F5);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF5F7F5);
  static const Color surfaceContainer = Color(0xFFF5F7F5);
  static const Color surfaceContainerHigh = Color(0xFFEDF1EE);
  static const Color surfaceContainerHighest = Color(0xFFE1E8E2);

  // Primary Containers & Tactile button accents
  static const Color primaryContainer = Color(0xFFDDF4E5);
  static const Color onPrimaryContainer = Color(0xFF174D36);
  static const Color primaryFixed = Color(0xFF174D36);
  static const Color primaryFixedDim = Color(0xFF27865A);
  static const Color surfaceTint = Color(0xFF174D36);
  static const Color tactileShadowPrimary = Color(0xFF0D3222);
  static const Color tactileShadowLime = Color(0xFF1B593C);

  // Secondary Containers
  static const Color secondaryContainer = Color(0xFFEDF5EF);
  static const Color onSecondaryContainer = Color(0xFF26352D);

  // Tertiary Containers
  static const Color tertiaryContainer = Color(0xFFDDF4E5);

  // Inverse
  static const Color inverseSurface = Color(0xFF26352D);
  static const Color inverseOnSurface = Color(0xFFFFFFFF);

  // Brand aliases remapped to light theme
  static const Color forestBackground = Color(0xFFFFFFFF);
  static const Color forestSecondary = Color(0xFFF5F7F5);
  static const Color forestSurface = Color(0xFFF5F7F5);
  static const Color vibrantLime = Color(0xFF174D36);
  static const Color softMint = Color(0xFF27865A);
  static const Color warmWhite = Color(0xFFFFFFFF);
  static const Color mutedMintGray = Color(0xFF66756C);
  static const Color darkMintBorder = Color(0xFFE1E8E2);
  static const Color darkMintDivider = Color(0x33174D36);
}

