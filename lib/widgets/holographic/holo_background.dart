import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Fond animé façon "salle holographique" : grille de perspective très
/// discrète en fond, traversée lentement par une ligne de balayage
/// lumineuse. Volontairement subtil (faible opacité) pour ne jamais
/// nuire à la lisibilité du contenu placé par-dessus.
///
/// Usage : envelopper le `body` d'un `Scaffold` avec `HoloBackground`.
class HoloBackground extends StatefulWidget {
  const HoloBackground({super.key, required this.child});

  final Widget child;

  @override
  State<HoloBackground> createState() => _HoloBackgroundState();
}

class _HoloBackgroundState extends State<HoloBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _HoloGridPainter(progress: _controller.value),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _HoloGridPainter extends CustomPainter {
  _HoloGridPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Grille fixe, très discrète.
    final gridPaint = Paint()
      ..color = AppColors.primaryGlow.withOpacity(0.035)
      ..strokeWidth = 1;

    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Ligne de balayage : un dégradé horizontal qui descend en boucle.
    final scanY = size.height * progress;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.primaryGlow.withOpacity(0.0),
          AppColors.primaryGlow.withOpacity(0.10),
          AppColors.primaryGlow.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 40, size.width, 80));
    canvas.drawRect(Rect.fromLTWH(0, scanY - 40, size.width, 80), scanPaint);
  }

  @override
  bool shouldRepaint(covariant _HoloGridPainter oldDelegate) => oldDelegate.progress != progress;
}
