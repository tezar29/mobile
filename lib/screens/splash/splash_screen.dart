import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Écoute les changements d'état d'authentification pour forcer la redirection
    // au cas où le redirect de go_router ne se déclenche pas à cause de l'état initial.
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      } else if (next.status == AuthStatus.unauthenticated) {
        context.go('/login');
      }
    });

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
