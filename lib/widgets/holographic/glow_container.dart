import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Conteneur générique avec bordure dégradée lumineuse et léger halo —
/// brique de base de toute l'esthétique "panneau holographique".
class GlowContainer extends StatelessWidget {
  const GlowContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.glowIntensity = 0.35,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final double glowIntensity;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: AppColors.holoBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGlow.withOpacity(glowIntensity),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.2), // épaisseur de la bordure dégradée
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(borderRadius - 1),
        ),
        child: child,
      ),
    );
  }
}
