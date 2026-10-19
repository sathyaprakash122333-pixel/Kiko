import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Obsidian Kinetic Typography for Kiko
abstract final class KikoTypography {
  // Editorial Headlines (Newsreader - Serif)
  static TextStyle displayLg({Color color = KikoColors.onSurface}) =>
      GoogleFonts.newsreader(
        fontSize: 56,
        height: 60 / 56,
        letterSpacing: -0.03 * 56,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle displayLgMobile({Color color = KikoColors.onSurface}) =>
      GoogleFonts.newsreader(
        fontSize: 36,
        height: 42 / 36,
        letterSpacing: -0.02 * 36,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle displayMd({Color color = KikoColors.onSurface}) =>
      GoogleFonts.newsreader(
        fontSize: 40,
        height: 46 / 40,
        letterSpacing: -0.02 * 40,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle headlineLg({Color color = KikoColors.onSurface}) =>
      GoogleFonts.newsreader(
        fontSize: 30,
        height: 36 / 30,
        letterSpacing: -0.01 * 30,
        fontWeight: FontWeight.w400,
        color: color,
      );

  // Operational Interface (Plus Jakarta Sans - Sans Serif)
  static TextStyle headlineMd({
    Color color = KikoColors.onSurface,
    FontWeight fontWeight = FontWeight.w600,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 20,
        height: 26 / 20,
        letterSpacing: -0.01 * 20,
        fontWeight: fontWeight,
        color: color,
      );

  static TextStyle bodyLg({
    Color color = KikoColors.onSurface,
    FontWeight fontWeight = FontWeight.w400,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: fontWeight,
        color: color,
      );

  static TextStyle bodyMd({
    Color color = KikoColors.onSurface,
    FontWeight fontWeight = FontWeight.w400,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: fontWeight,
        color: color,
      );

  static TextStyle bodySm({
    Color color = KikoColors.onSurface,
    FontWeight fontWeight = FontWeight.w400,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: fontWeight,
        color: color,
      );

  // Technical Badges & Monospace (JetBrains Mono)
  static TextStyle labelCode({
    Color color = KikoColors.onSurfaceVariant,
    FontWeight fontWeight = FontWeight.w500,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 0.02 * 12,
        fontWeight: fontWeight,
        color: color,
      );

  static TextStyle labelCaps({
    Color color = KikoColors.onSurfaceVariant,
    FontWeight fontWeight = FontWeight.w600,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: 10,
        height: 14 / 10,
        letterSpacing: 0.12 * 10,
        fontWeight: fontWeight,
        color: color,
      );
}
