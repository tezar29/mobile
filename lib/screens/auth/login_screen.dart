import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/holographic/glow_container.dart';
import '../../widgets/holographic/holo_background.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await ref.read(authStateProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: HoloBackground(
        child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: GlowContainer(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'CONNEXION',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: AppColors.primaryGlow, letterSpacing: 3),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Mot de passe'),
                    ),
                    if (authState.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(authState.errorMessage!, style: const TextStyle(color: AppColors.danger)),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('SE CONNECTER'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Créer un compte'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}
