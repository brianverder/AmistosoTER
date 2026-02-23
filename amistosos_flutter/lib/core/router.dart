import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_layout.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/teams/teams_screen.dart';
import '../screens/teams/create_team_screen.dart';
import '../screens/teams/team_detail_screen.dart';
import '../screens/teams/team_stats_screen.dart';
import '../screens/requests/requests_screen.dart';
import '../screens/requests/create_request_screen.dart';
import '../screens/requests/request_detail_screen.dart';
import '../screens/matches/matches_screen.dart';
import '../screens/matches/match_detail_screen.dart';
import '../screens/public/partidos_screen.dart';

/// Clave global para navegación imperativa cuando sea necesario
final navigatorKey = GlobalKey<NavigatorState>();

/// Provider del router, observa el estado de auth para redirecciones
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/login',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isAuthenticated = authState.maybeWhen(
        authenticated: (_) => true,
        orElse: () => false,
      );
      final isLoading = authState.maybeWhen(
        loading: () => true,
        orElse: () => false,
      );

      // No redirigir mientras carga
      if (isLoading) return null;

      final path = state.matchedLocation;
      final isAuthRoute = path == '/login' || path == '/register';
      final isPublicRoute = path == '/partidos' || path.startsWith('/partidos/');

      // Usuario autenticado en pantalla de auth → redirigir a dashboard
      if (isAuthenticated && isAuthRoute) return '/dashboard';

      // Usuario NO autenticado en ruta protegida → redirigir a login
      if (!isAuthenticated && !isAuthRoute && !isPublicRoute) {
        return '/login?returnUrl=${Uri.encodeComponent(path)}';
      }

      return null;
    },
    routes: [
      // ── Rutas públicas ────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => LoginScreen(
          returnUrl: state.uri.queryParameters['returnUrl'],
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/partidos',
        name: 'publicPartidos',
        builder: (context, state) => const PartidosScreen(),
      ),

      // ── Dashboard (protegido) ─────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => DashboardLayout(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),

          // ── Teams ─────────────────────────────────────────────────────────
          GoRoute(
            path: '/dashboard/teams',
            name: 'teams',
            builder: (context, state) => const TeamsScreen(),
          ),
          GoRoute(
            path: '/dashboard/teams/new',
            name: 'teamNew',
            builder: (context, state) => const CreateTeamScreen(),
          ),
          GoRoute(
            path: '/dashboard/teams/:id',
            name: 'teamDetail',
            builder: (context, state) => TeamDetailScreen(
              teamId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/dashboard/teams/:id/stats',
            name: 'teamStats',
            builder: (context, state) => TeamStatsScreen(
              teamId: state.pathParameters['id']!,
            ),
          ),

          // ── Requests ──────────────────────────────────────────────────────
          GoRoute(
            path: '/dashboard/requests',
            name: 'requests',
            builder: (context, state) => const RequestsScreen(),
          ),
          GoRoute(
            path: '/dashboard/requests/new',
            name: 'requestNew',
            builder: (context, state) => const CreateRequestScreen(),
          ),
          GoRoute(
            path: '/dashboard/requests/:id',
            name: 'requestDetail',
            builder: (context, state) => RequestDetailScreen(
              requestId: state.pathParameters['id']!,
            ),
          ),

          // ── Matches ───────────────────────────────────────────────────────
          GoRoute(
            path: '/dashboard/matches',
            name: 'matches',
            builder: (context, state) => const MatchesScreen(),
          ),
          GoRoute(
            path: '/dashboard/matches/:id',
            name: 'matchDetail',
            builder: (context, state) => MatchDetailScreen(
              matchId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
    ],

    // Error handler global
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('404', style: TextStyle(fontSize: 72, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Página no encontrada'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('IR AL DASHBOARD'),
            ),
          ],
        ),
      ),
    ),
  );
});
