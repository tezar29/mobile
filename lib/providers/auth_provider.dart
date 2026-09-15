import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import 'service_providers.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({this.status = AuthStatus.unknown, this.errorMessage});

  final AuthStatus status;
  final String? errorMessage;

  AuthState copyWith({AuthStatus? status, String? errorMessage}) {
    return AuthState(status: status ?? this.status, errorMessage: errorMessage);
  }
}

/// Gère l'état global d'authentification, consommé par le routeur
/// (app_router.dart) pour rediriger automatiquement vers login/home.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authService) : super(const AuthState()) {
    _checkInitialAuth();
  }

  final AuthService _authService;

  Future<void> _checkInitialAuth() async {
    final loggedIn = await _authService.isLoggedIn();
    state = state.copyWith(status: loggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated);
  }

  Future<void> login(String email, String password) async {
    final result = await _authService.login(email: email, password: password);
    state = result.isSuccess
        ? state.copyWith(status: AuthStatus.authenticated, errorMessage: null)
        : state.copyWith(status: AuthStatus.unauthenticated, errorMessage: result.error);
  }

  Future<void> register(String email, String password) async {
    final result = await _authService.register(email: email, password: password);
    if (result.isSuccess) {
      await login(email, password);
    } else {
      state = state.copyWith(errorMessage: result.error);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = state.copyWith(status: AuthStatus.unauthenticated);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
