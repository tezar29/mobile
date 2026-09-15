import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';

/// État visuel de l'orbe — délibérément découplé de `VoiceStatus`
/// (providers/voice_provider.dart) pour que ce widget reste un composant
/// UI pur, sans dépendance vers la couche état/métier. L'écran appelant
/// fait la correspondance entre les deux.
enum OrbVisualState { idle, waking, listening, thinking, speaking, error }

/// Orbe holographique central — le "cœur" visuel de JARVIS. Un anneau
/// de sonar (cercles concentriques qui s'étendent et s'estompent) donne
/// une sensation de présence active, avec une couleur et un rythme
/// différents selon l'état (écoute passive, capture, réflexion, réponse).
class VoiceOrbButton extends StatelessWidget {
  const VoiceOrbButton({
    super.key,
    required this.state,
    required this.onTap,
    this.size = 130,
  });

  final OrbVisualState state;
  final VoidCallback onTap;
  final double size;

  Color get _color => switch (state) {
        OrbVisualState.idle => AppColors.primaryGlow,
        OrbVisualState.waking => AppColors.primaryGlow,
        OrbVisualState.listening => AppColors.secondaryGlow,
        OrbVisualState.thinking => AppColors.alert,
        OrbVisualState.speaking => AppColors.success,
        OrbVisualState.error => AppColors.danger,
      };

  IconData get _icon => switch (state) {
        OrbVisualState.idle => Icons.mic_none_rounded,
        OrbVisualState.waking => Icons.hearing_rounded,
        OrbVisualState.listening => Icons.graphic_eq_rounded,
        OrbVisualState.thinking => Icons.auto_awesome_rounded,
        OrbVisualState.speaking => Icons.volume_up_rounded,
        OrbVisualState.error => Icons.priority_high_rounded,
      };

  Duration get _rippleSpeed => switch (state) {
        OrbVisualState.idle => 2400.ms,
        OrbVisualState.waking => 1800.ms,
        OrbVisualState.listening => 900.ms,
        OrbVisualState.thinking => 700.ms,
        OrbVisualState.speaking => 600.ms,
        OrbVisualState.error => 1200.ms,
      };

  bool get _rippleActive => state != OrbVisualState.idle;

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size * 1.8,
        height: size * 1.8,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_rippleActive) ..._buildRipples(color, size),
            _buildCore(color, size),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRipples(Color color, double size) {
    // Trois anneaux décalés dans le temps pour un effet de sonar continu.
    return List.generate(3, (i) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 1.5)),
      )
          .animate(onPlay: (c) => c.repeat(), delay: (i * _rippleSpeed.inMilliseconds ~/ 3).ms)
          .scale(
            duration: _rippleSpeed,
            begin: const Offset(1, 1),
            end: const Offset(1.9, 1.9),
            curve: Curves.easeOut,
          )
          .fadeOut(duration: _rippleSpeed, curve: Curves.easeOut);
    });
  }

  Widget _buildCore(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color.withOpacity(0.55), color.withOpacity(0.05)]),
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(_icon, color: color, size: size * 0.4),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          duration: state == OrbVisualState.idle ? 1800.ms : 550.ms,
          begin: const Offset(1, 1),
          end: Offset(state == OrbVisualState.idle ? 1.04 : 1.1, state == OrbVisualState.idle ? 1.04 : 1.1),
        );
  }
}
