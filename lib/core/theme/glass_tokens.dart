import 'package:flutter/material.dart';

/// Tokens du design system Web (dark + glassmorphism).
abstract final class GlassTokens {
  // Arrière-plan WAVES
  static const Color bgDeep = Color(0xFF070D18);
  static const Color bgDeepAlt = Color(0xFF0B192C);
  static const Color waveColor = Color(0xFF005588);

  // Glassmorphism
  static const Color glassFill = Color(0x990F172A); // rgba(15,23,42,0.60)
  static const Color glassFillLight = Color(0xB30F172A);
  static const Color glassBorder = Color(0x14FFFFFF); // ~0.08
  static const Color glassBorderStrong = Color(0x1FFFFFFF); // ~0.12
  static const double glassRadius = 16;
  static const double glassBlurSigma = 14;

  // Texte
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xA6FFFFFF); // 0.65
  static const Color textHint = Color(0x80FFFFFF);

  // Actif / sélectionné
  static const Color activeFill = Color(0x592563EB); // rgba(37,99,235,0.35)
  static const Color activeBorder = Color(0xCC60A5FA);
  static const Color accentBorder = activeBorder;
  static const Color activeGlow = Color(0x4D2563EB);

  // Actions
  static const Color submitBlue = Color(0xFF1D4ED8);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF22C55E);
  static const Color warningOrange = Color(0xFFF59E0B);

  static List<BoxShadow> activeGlowShadow = <BoxShadow>[
    const BoxShadow(
      color: activeGlow,
      blurRadius: 10,
      spreadRadius: 0,
    ),
  ];
}

/// Espacements standard pour le contenu sous header / bottom nav.
abstract final class GlassLayout {
  /// Marge entre le bas du header et le premier élément de contenu.
  static const double contentTopGap = 16;

  /// Réserve en bas pour la bottom navigation flottante.
  static const double bottomNavReserve = 100;

  /// Padding recommandé pour listes scrollables dans le shell employé.
  static const EdgeInsets shellScrollPadding = EdgeInsets.only(
    top: contentTopGap,
    bottom: bottomNavReserve,
    left: 16,
    right: 16,
  );

  /// Padding pour pages plein écran avec AppBar glass (sans bottom nav).
  static const EdgeInsets pageScrollPadding = EdgeInsets.only(
    top: contentTopGap,
    bottom: 24,
    left: 16,
    right: 16,
  );
}
