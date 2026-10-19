import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// App Theme Definition for Kiko
abstract final class KikoTheme {
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: KikoColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: KikoColors.primary,
        onPrimary: KikoColors.onPrimary,
        primaryContainer: KikoColors.primaryContainer,
        onPrimaryContainer: KikoColors.onPrimaryContainer,
        secondary: KikoColors.secondary,
        onSecondary: KikoColors.onSecondary,
        secondaryContainer: KikoColors.secondaryContainer,
        onSecondaryContainer: KikoColors.onSecondaryContainer,
        tertiary: KikoColors.tertiary,
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
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: KikoColors.onSurface,
        displayColor: KikoColors.onSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KikoColors.surfaceContainerLow,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: KikoColors.textPlaceholder,
        ),
        prefixIconColor: KikoColors.onSurfaceVariant,
        suffixIconColor: KikoColors.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: KikoColors.surfaceContainerHighest,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: KikoColors.surfaceContainerHighest,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: KikoColors.primaryContainer,
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
}
