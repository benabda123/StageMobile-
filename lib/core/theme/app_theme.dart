import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glass_tokens.dart';

class AppColors {
  AppColors._();

  /// Bleu marine "Keystone" — couleur de marque du projet.
  static const Color primary = Color(0xFF003366);
  static const Color primaryDark = Color(0xFF00213F);
  static const Color primaryLight = Color(0xFF00509E);
  static const Color textPrimary = GlassTokens.textPrimary;
}

class AppTheme {
  AppTheme._();

  /// Thème clair aux couleurs de marque Keystone (#003366).
  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primaryLight,
      surface: const Color(0xFFF5F7FA),
      onSurface: const Color(0xFF0B192C),
      error: GlassTokens.errorRed,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
    );
  }

  static ThemeData get dark {
    final ColorScheme scheme = ColorScheme.dark(
      primary: GlassTokens.submitBlue,
      onPrimary: GlassTokens.textPrimary,
      secondary: GlassTokens.activeBorder,
      surface: GlassTokens.glassFill,
      onSurface: GlassTokens.textPrimary,
      error: GlassTokens.errorRed,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: GlassTokens.textPrimary,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      dividerColor: GlassTokens.glassBorder,
      iconTheme: const IconThemeData(color: GlassTokens.textPrimary),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: GlassTokens.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: GlassTokens.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(color: GlassTokens.textPrimary),
        titleSmall: TextStyle(color: GlassTokens.textSecondary),
        bodyLarge: TextStyle(color: GlassTokens.textPrimary),
        bodyMedium: TextStyle(color: GlassTokens.textSecondary),
        bodySmall: TextStyle(color: GlassTokens.textHint),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GlassTokens.glassFill,
        labelStyle: const TextStyle(color: GlassTokens.textSecondary),
        hintStyle: const TextStyle(color: GlassTokens.textHint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassTokens.glassRadius),
          borderSide: const BorderSide(color: GlassTokens.glassBorderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassTokens.glassRadius),
          borderSide: const BorderSide(color: GlassTokens.glassBorderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassTokens.glassRadius),
          borderSide: const BorderSide(color: GlassTokens.activeBorder),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: GlassTokens.glassFillLight,
        contentTextStyle: const TextStyle(color: GlassTokens.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlassTokens.glassRadius),
          side: const BorderSide(color: GlassTokens.glassBorderStrong),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: GlassTokens.activeBorder,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: GlassTokens.bgDeepAlt,
        headerBackgroundColor: GlassTokens.submitBlue,
        headerForegroundColor: GlassTokens.textPrimary,
      ),
    );
  }
}
