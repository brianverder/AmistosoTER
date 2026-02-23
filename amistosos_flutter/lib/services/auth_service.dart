import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../models/user_model.dart';
import 'api_client.dart';

/// Servicio de autenticación.
/// Usa el flujo de NextAuth con credentials provider:
///   1. GET /api/auth/csrf → csrfToken
///   2. POST /api/auth/callback/credentials (form-encoded) → session cookie
///   3. GET /api/auth/session → datos del usuario
class AuthService {
  final ApiClient _client;

  AuthService(this._client);

  // ─── Login ────────────────────────────────────────────────────────────────

  /// Inicia sesión con email y contraseña.
  /// Devuelve el [UserModel] autenticado o lanza [ApiException].
  Future<UserModel> signIn(String email, String password) async {
    // Paso 1: obtener CSRF token
    final csrfData = await _client.get(AppConstants.csrfEndpoint) as Map<String, dynamic>;
    final csrfToken = csrfData['csrfToken'] as String;

    // Paso 2: enviar credenciales como form-encoded (requerido por NextAuth)
    final loginResponse = await _client.postForm(
      AppConstants.signInEndpoint,
      {
        'csrfToken': csrfToken,
        'email': email,
        'password': password,
        'callbackUrl': '${AppConstants.baseUrl}/dashboard',
        'json': 'true',
      },
    );

    // NextAuth devuelve 200 con body { url: "..." } si la autenticación es válida
    // o 200 con url que contiene "error" si las credenciales son incorrectas
    if (loginResponse.statusCode == 200) {
      final body = loginResponse.data;
      if (body is Map<String, dynamic>) {
        final url = body['url'] as String? ?? '';
        if (url.contains('error')) {
          throw const ApiException(
              message: 'Credenciales inválidas', statusCode: 401);
        }
      }
    } else if ((loginResponse.statusCode ?? 0) >= 400) {
      throw const ApiException(
          message: 'Credenciales inválidas', statusCode: 401);
    }

    // Paso 3: leer sesión activa para obtener datos del usuario
    return await _getSession();
  }

  // ─── Sesión actual ────────────────────────────────────────────────────────

  /// Obtiene el usuario de la sesión activa o null si no hay sesión.
  Future<UserModel?> getSession() async {
    try {
      return await _getSession();
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> _getSession() async {
    final data = await _client.get(AppConstants.sessionEndpoint) as Map<String, dynamic>?;
    final user = data?['user'] as Map<String, dynamic>?;
    if (user == null) {
      throw const ApiException(
          message: 'Sin sesión activa', statusCode: 401);
    }
    final userModel = UserModel.fromJson(user);
    await _persistUser(userModel);
    return userModel;
  }

  // ─── Registro ─────────────────────────────────────────────────────────────

  /// Registra un nuevo usuario y retorna el [UserModel] creado.
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final data = await _client.post(
      AppConstants.registerEndpoint,
      data: {
        'name': name,
        'email': email,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    ) as Map<String, dynamic>;

    // Tras registrar, iniciar sesión automáticamente
    return await signIn(email, password);
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  /// Cierra la sesión en el servidor y limpia el storage local.
  Future<void> signOut() async {
    try {
      // Primero obtener CSRF token
      final csrfData = await _client.get(AppConstants.csrfEndpoint) as Map<String, dynamic>;
      final csrfToken = csrfData['csrfToken'] as String;

      await _client.postForm(
        AppConstants.signOutEndpoint,
        {
          'csrfToken': csrfToken,
          'callbackUrl': '${AppConstants.baseUrl}/login',
          'json': 'true',
        },
      );
    } catch (_) {
      // Aunque falle el signout en servidor, limpiar local
    } finally {
      await _clearUser();
    }
  }

  // ─── Persistencia local ───────────────────────────────────────────────────

  Future<void> _persistUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.storageUserId, user.id);
    await prefs.setString(AppConstants.storageUserName, user.name);
    await prefs.setString(AppConstants.storageUserEmail, user.email);
  }

  Future<void> _clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.storageUserId);
    await prefs.remove(AppConstants.storageUserName);
    await prefs.remove(AppConstants.storageUserEmail);
  }

  /// Intenta recuperar usuario desde SharedPreferences (para restore de sesión).
  Future<UserModel?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(AppConstants.storageUserId);
    final name = prefs.getString(AppConstants.storageUserName);
    final email = prefs.getString(AppConstants.storageUserEmail);
    if (id == null || name == null || email == null) return null;
    return UserModel(id: id, name: name, email: email);
  }
}
