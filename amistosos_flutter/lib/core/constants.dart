// Constantes globales de la aplicación
class AppConstants {
  AppConstants._();

  // ─── URLs ────────────────────────────────────────────────────────────────
  /// En producción apunta al VPS. Para desarrollo local cambiá a http://localhost:3000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://www.tercer-tiempo.com/amistosos',
  );

  // ─── API Endpoints ────────────────────────────────────────────────────────
  static const String csrfEndpoint = '/api/auth/csrf';
  static const String signInEndpoint = '/api/auth/callback/credentials';
  static const String sessionEndpoint = '/api/auth/session';
  static const String signOutEndpoint = '/api/auth/signout';
  static const String registerEndpoint = '/api/auth/register';

  static const String teamsEndpoint = '/api/teams';
  static const String requestsEndpoint = '/api/requests';
  static const String matchesEndpoint = '/api/matches';
  static const String publicRequestsEndpoint = '/api/public/requests';
  static const String usersCountEndpoint = '/api/public/users-count';

  // ─── Rutas de navegación ─────────────────────────────────────────────────
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeDashboard = '/dashboard';
  static const String routeTeams = '/dashboard/teams';
  static const String routeTeamNew = '/dashboard/teams/new';
  static const String routeTeamDetail = '/dashboard/teams/:id';
  static const String routeTeamStats = '/dashboard/teams/:id/stats';
  static const String routeRequests = '/dashboard/requests';
  static const String routeRequestNew = '/dashboard/requests/new';
  static const String routeRequestDetail = '/dashboard/requests/:id';
  static const String routeMatches = '/dashboard/matches';
  static const String routeMatchDetail = '/dashboard/matches/:id';
  static const String routePublicPartidos = '/partidos';

  // ─── Storage keys ─────────────────────────────────────────────────────────
  static const String storageUserId = 'user_id';
  static const String storageUserName = 'user_name';
  static const String storageUserEmail = 'user_email';

  // ─── Países permitidos ───────────────────────────────────────────────────
  static const List<String> countries = ['Uruguay', 'Argentina', 'Brasil'];

  // ─── Tipos de fútbol ─────────────────────────────────────────────────────
  static const List<String> footballTypes = ['5', '7', '8', '11', 'futsal'];

  // ─── Espaciados ───────────────────────────────────────────────────────────
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  static String footballTypeLabel(String? type) {
    const labels = {
      '5': 'Fútbol 5',
      '7': 'Fútbol 7',
      '8': 'Fútbol 8',
      '11': 'Fútbol 11',
      'futsal': 'Futsal',
    };
    return labels[type] ?? type ?? 'Sin especificar';
  }
}

/// Alias de rutas de navegación con la misma convención usada en screens.
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';

  static const String teams = '/dashboard/teams';
  static const String createTeam = '/dashboard/teams/new';
  static const String teamDetail = '/dashboard/teams/:id';
  static const String teamStats = '/dashboard/teams/:id/stats';

  static const String requests = '/dashboard/requests';
  static const String createRequest = '/dashboard/requests/new';
  static const String requestDetail = '/dashboard/requests/:id';

  static const String matches = '/dashboard/matches';
  static const String matchDetail = '/dashboard/matches/:id';

  static const String publicPartidos = '/partidos';
}
