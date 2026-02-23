import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

// ─── Providers de servicios ────────────────────────────────────────────────

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(apiClientProvider));
});

// ─── Estado de autenticación ───────────────────────────────────────────────

sealed class AuthState {
  const AuthState();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

extension AuthStateX on AuthState {
  T maybeWhen<T>({
    T Function()? loading,
    T Function(UserModel user)? authenticated,
    T Function()? unauthenticated,
    T Function(String message)? error,
    required T Function() orElse,
  }) {
    return switch (this) {
      AuthLoading() => loading?.call() ?? orElse(),
      AuthAuthenticated(:final user) => authenticated?.call(user) ?? orElse(),
      AuthUnauthenticated() => unauthenticated?.call() ?? orElse(),
      AuthError(:final message) => error?.call(message) ?? orElse(),
    };
  }

  UserModel? get userOrNull => switch (this) {
        AuthAuthenticated(:final user) => user,
        _ => null,
      };
}

// ─── Notifier ─────────────────────────────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restoreSession();
    return const AuthLoading();
  }

  AuthService get _service => ref.read(authServiceProvider);

  /// Al iniciar la app, intenta restaurar la sesión desde el servidor.
  Future<void> _restoreSession() async {
    state = const AuthLoading();
    try {
      // Primero intentar sesión activa en servidor (cookie vigente en browser)
      final user = await _service.getSession();
      if (user != null) {
        state = AuthAuthenticated(user);
        return;
      }
    } catch (_) {}

    // Cookie expirada o sin sesión
    state = const AuthUnauthenticated();
  }

  /// Login con email y contraseña.
  Future<void> signIn(String email, String password) async {
    state = const AuthLoading();
    try {
      final user = await _service.signIn(email, password);
      state = AuthAuthenticated(user);
    } on ApiException catch (e) {
      state = AuthError(e.message);
    } catch (_) {
      state = const AuthError('Error inesperado al iniciar sesión');
    }
  }

  /// Registro y login automático.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _service.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      state = AuthAuthenticated(user);
    } on ApiException catch (e) {
      state = AuthError(e.message);
    } catch (_) {
      state = const AuthError('Error al registrarse. Intenta nuevamente.');
    }
  }

  /// Cerrar sesión.
  Future<void> signOut() async {
    await _service.signOut();
    state = const AuthUnauthenticated();
  }

  /// Restaurar estado de error para permitir reintentar.
  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Shorthand para acceder al usuario autenticado directamente.
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authNotifierProvider).userOrNull;
});
