import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Thème sombre unique de l'application — JARVIS n'a pas de mode clair,
/// cohérent avec l'esthétique holographique voulue.
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.orbitronTextTheme(base.textTheme).copyWith(
      bodyLarge: GoogleFonts.rajdhani(fontSize: 16, color: AppColors.textPrimary),
      bodyMedium: GoogleFonts.rajdhani(fontSize: 14, color: AppColors.textSecondary),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primaryGlow,
        secondary: AppColors.secondaryGlow,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      dividerColor: AppColors.divider,
      iconTheme: const IconThemeData(color: AppColors.primaryGlow),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGlow,
          foregroundColor: AppColors.background,
          textStyle: GoogleFonts.orbitron(fontWeight: FontWeight.w600, letterSpacing: 1.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGlow, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
