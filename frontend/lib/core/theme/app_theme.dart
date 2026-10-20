import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// App Theme Definition for Kiko — Centralized Light Design System
/// Dominant background: #FFFFFF
/// Secondary surface: #F5F7F5
/// Primary actions: #174D36 (Forest Green)
/// Secondary/Progress: #27865A (Emerald)
/// Tertiary/Highlights: #DDF4E5 (Pale Mint)
/// Text primary: #26352D
/// Text secondary: #66756C
/// Borders: #E1E8E2
abstract final class KikoTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.light().textTheme,
    );

    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: KikoColors.primaryForest,
      onPrimary: KikoColors.onPrimary,
      primaryContainer: KikoColors.primaryContainer,
      onPrimaryContainer: KikoColors.onPrimaryContainer,
      secondary: KikoColors.secondaryEmerald,
      onSecondary: KikoColors.onSecondary,
      secondaryContainer: KikoColors.secondaryContainer,
      onSecondaryContainer: KikoColors.onSecondaryContainer,
      tertiary: KikoColors.tertiaryMint,
      onTertiary: KikoColors.onTertiary,
      error: KikoColors.error,
      onError: KikoColors.onError,
      errorContainer: KikoColors.errorContainer,
      onErrorContainer: KikoColors.onErrorContainer,
      surface: KikoColors.surface,
      onSurface: KikoColors.onSurface,
      onSurfaceVariant: KikoColors.onSurfaceVariant,
      outline: KikoColors.outline,
      outlineVariant: KikoColors.outlineVariant,
      surfaceContainerLowest: KikoColors.surfaceContainerLowest,
      surfaceContainerLow: KikoColors.surfaceContainerLow,
      surfaceContainer: KikoColors.surfaceContainer,
      surfaceContainerHigh: KikoColors.surfaceContainerHigh,
      surfaceContainerHighest: KikoColors.surfaceContainerHighest,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: KikoColors.background,
      colorScheme: colorScheme,
      textTheme: baseTextTheme.apply(
        bodyColor: KikoColors.textPrimary,
        displayColor: KikoColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: KikoColors.background,
        foregroundColor: KikoColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: KikoColors.secondarySurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: KikoColors.border,
            width: 1,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: KikoColors.border,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KikoColors.primaryForest,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KikoColors.primaryForest,
          side: const BorderSide(color: KikoColors.border, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KikoColors.primaryForest,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KikoColors.secondarySurface,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: KikoColors.textPlaceholder,
        ),
        prefixIconColor: KikoColors.textSecondary,
        suffixIconColor: KikoColors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: KikoColors.border,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: KikoColors.border,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: KikoColors.primaryForest,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: KikoColors.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: KikoColors.error,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  /// Backward-compatible alias — ensures entire app renders light theme globally
  static ThemeData get darkTheme => lightTheme;
}
