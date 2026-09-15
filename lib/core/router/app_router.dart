import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/vision/vision_screen.dart';

/// Routeur unique de l'app. La redirection centralise toute la logique
/// d'accès : un utilisateur non authentifié ne peut jamais atteindre
/// les écrans protégés, quelle que soit l'URL demandée.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = authState.status == AuthStatus.authenticated;
      final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (authState.status == AuthStatus.unknown) return '/';
      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
      GoRoute(path: '/vision', builder: (context, state) => const VisionScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    ],
  );
});
