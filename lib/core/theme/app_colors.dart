import 'package:flutter/material.dart';

/// Palette inspirée des interfaces holographiques de JARVIS :
/// fond quasi-noir, accent cyan lumineux, touches ambre pour les alertes.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF05070A);
  static const Color surface = Color(0xFF0B1016);
  static const Color surfaceElevated = Color(0xFF10161D);

  static const Color primaryGlow = Color(0xFF3DDDFF); // cyan holographique
  static const Color secondaryGlow = Color(0xFF7B61FF); // violet accent
  static const Color alert = Color(0xFFFFB84D); // ambre — alertes/warnings
  static const Color danger = Color(0xFFFF5C5C);
  static const Color success = Color(0xFF4DFFB0);

  static const Color textPrimary = Color(0xFFE8F6FF);
  static const Color textSecondary = Color(0xFF7C95A6);
  static const Color divider = Color(0xFF1B2530);

  /// Dégradé utilisé pour les halos et bordures lumineuses des panneaux.
  static const LinearGradient holoBorder = LinearGradient(
    colors: [primaryGlow, secondaryGlow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
