import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'J.A.R.V.I.S.',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primaryGlow,
                letterSpacing: 6,
              ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 900.ms).fadeOut(
              delay: 900.ms,
              duration: 900.ms,
            ),
      ),
    );
  }
}
