import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/matches_provider.dart';
import '../../providers/requests_provider.dart';
import '../../providers/teams_provider.dart';
import '../../widgets/app_widgets.dart';

/// Pantalla principal del dashboard — equivalente a app/dashboard/page.tsx
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final teamsAsync = ref.watch(teamsNotifierProvider);
    final requestsAsync = ref.watch(requestsProvider(const RequestFilters(tab: 'available')));
    final matchesAsync = ref.watch(matchesNotifierProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 768;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // ── Hero / Bienvenida ────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFDCFCE7), Color(0xFFF0FDF4), Color(0xFFECFDF5)],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.primaryLight, width: 1),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('👋', style: TextStyle(fontSize: 40)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¡Hola, ${user?.name ?? 'Jugador'}!',
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            Text(
                              'Listo para coordinar tu próximo partido',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                right: 0,
                top: -10,
                child: Text(
                  '⚽',
                  style: TextStyle(
                    fontSize: 100,
                    color: AppTheme.primary.withOpacity(0.08),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Estadísticas principales ─────────────────────────────────────
        teamsAsync.when(
          loading: () => GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isWide ? 3 : 1,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: List.generate(
                3,
                (_) => Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    )),
          ),
          error: (_, __) => const SizedBox(),
          data: (teams) {
            final teamsCount = teams.length;
            return teamsAsync.when(
              data: (_) => requestsAsync.when(
                data: (requests) => matchesAsync.when(
                  data: (matches) => _StatsGrid(
                    isWide: isWide,
                    teamCount: teamsCount,
                    requestCount: requests.length,
                    matchCount: matches.length,
                  ),
                  loading: () => _StatsGrid(
                      isWide: isWide,
                      teamCount: teamsCount,
                      requestCount: 0,
                      matchCount: 0),
                  error: (_, __) => _StatsGrid(
                      isWide: isWide,
                      teamCount: teamsCount,
                      requestCount: 0,
                      matchCount: 0),
                ),
                loading: () => _StatsGrid(
                    isWide: isWide,
                    teamCount: teamsCount,
                    requestCount: 0,
                    matchCount: 0),
                error: (_, __) => _StatsGrid(
                    isWide: isWide,
                    teamCount: teamsCount,
                    requestCount: 0,
                    matchCount: 0),
              ),
              loading: () => const AppSpinner(),
              error: (_, __) => const SizedBox(),
            );
          },
        ),
        const SizedBox(height: 32),

        // ── Acciones rápidas ─────────────────────────────────────────────
        const SectionHeader(title: '⚡ Acciones Rápidas'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _QuickActionCard(
              icon: '➕',
              title: 'Crear Equipo',
              subtitle: 'Registra tu equipo',
              onTap: () => context.go('/dashboard/teams/new'),
            ),
            _QuickActionCard(
              icon: '📋',
              title: 'Nueva Solicitud',
              subtitle: 'Busca rivales',
              onTap: () => context.go('/dashboard/requests/new'),
            ),
            _QuickActionCard(
              icon: '🔍',
              title: 'Ver Solicitudes',
              subtitle: 'Solicitudes disponibles',
              onTap: () => context.go('/dashboard/requests'),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // ── Layout de dos columnas en desktop ────────────────────────────
        if (isWide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _RecentRequestsSection(ref: ref)),
                const SizedBox(width: 24),
                Expanded(child: _ActiveMatchesSection(ref: ref)),
              ],
            ),
          )
        else ...[
          _RecentRequestsSection(ref: ref),
          const SizedBox(height: 24),
          _ActiveMatchesSection(ref: ref),
        ],

        const SizedBox(height: 32),

        // ── Top equipos (ranking global) ─────────────────────────────────
        _TopTeamsSection(ref: ref),
      ],
      ),
    );
  }
}

// ── Stats grid ─────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final bool isWide;
  final int teamCount;
  final int requestCount;
  final int matchCount;

  const _StatsGrid({
    required this.isWide,
    required this.teamCount,
    required this.requestCount,
    required this.matchCount,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (ctx) {
      final stats = [
        (label: 'Equipos', value: teamCount, emoji: '⚽', route: '/dashboard/teams'),
        (label: 'Solicitudes', value: requestCount, emoji: '📋', route: '/dashboard/requests'),
        (label: 'Partidos', value: matchCount, emoji: '🏆', route: '/dashboard/matches'),
      ];
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: isWide ? 3 : 1,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isWide ? 2.2 : 4,
        children: stats.map((s) {
          return StatCard(
            label: s.label,
            value: s.value.toString(),
            emoji: s.emoji,
            onTap: () => ctx.go(s.route),
          );
        }).toList(),
      );
    });
  }
}

// ── Quick action card ──────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent requests section ────────────────────────────────────────────────

class _RecentRequestsSection extends ConsumerWidget {
  const _RecentRequestsSection({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(requestsProvider(const RequestFilters(tab: 'my')));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: '📋 Mis Últimas Solicitudes',
          action: TextButton(
            onPressed: () => context.go('/dashboard/requests'),
            child: const Text('Ver todas →'),
          ),
        ),
        const SizedBox(height: 12),
        requestsAsync.when(
          loading: () => const Center(child: AppSpinner()),
          error: (e, _) => Text('Error: $e'),
          data: (requests) {
            final myRequests = requests.take(3).toList();
            if (myRequests.isEmpty) {
              return const EmptyState(
                emoji: '📋',
                title: 'No hay solicitudes recientes',
              );
            }
            return Column(
              children: myRequests.map((r) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    onTap: () => context.go('/dashboard/requests/${r.id}'),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.team?.name ?? 'Sin equipo',
                                style:
                                    Theme.of(context).textTheme.labelLarge,
                              ),
                              if (r.footballType != null)
                                Text(
                                  AppConstants.footballTypeLabel(r.footballType ?? ''),

                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                        StatusBadge(status: r.status.name),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ── Active matches section ─────────────────────────────────────────────────

class _ActiveMatchesSection extends ConsumerWidget {
  const _ActiveMatchesSection({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: '🤝 Matches Activos',
          action: TextButton(
            onPressed: () => context.go('/dashboard/matches'),
            child: const Text('Ver todos →'),
          ),
        ),
        const SizedBox(height: 12),
        matchesAsync.when(
          loading: () => const Center(child: AppSpinner()),
          error: (e, _) => Text('Error: $e'),
          data: (matches) {
            final active = matches.where((m) => m.matchResult == null).take(3).toList();
            if (active.isEmpty) {
              return const EmptyState(
                emoji: '🤝',
                title: 'No hay matches activos',
              );
            }
            return Column(
              children: active.map((m) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    onTap: () => context.go('/dashboard/matches/${m.id}'),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${m.team1?.name ?? '?'} vs ${m.team2?.name ?? '?'}',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 4),
                        StatusBadge(status: m.isCompleted ? 'completed' : m.status.name),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ── Top teams section ──────────────────────────────────────────────────────

class _TopTeamsSection extends ConsumerWidget {
  const _TopTeamsSection({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '🏆 Ranking de mis Equipos'),
        const SizedBox(height: 12),
        teamsAsync.when(
          loading: () => const Center(child: AppSpinner()),
          error: (e, _) => const SizedBox(),
          data: (teams) {
            if (teams.isEmpty) {
              return EmptyState(
                emoji: '⚽',
                title: 'Aún no tienes equipos',
                action: AppButton(
                  label: 'Crear equipo',
                  onPressed: () => context.go('/dashboard/teams/new'),
                ),
              );
            }
            final sorted = [...teams]
              ..sort((a, b) => b.gamesWon.compareTo(a.gamesWon));

            return AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: sorted.asMap().entries.map((entry) {
                  final i = entry.key;
                  final team = entry.value;
                  final winRate = team.winRate.toStringAsFixed(0);

                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: i < sorted.length - 1
                          ? Border(
                              bottom: BorderSide(
                                  color: AppTheme.border, width: 1))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: i == 0 ? AppTheme.primary : AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '#${i + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: i == 0 ? Colors.white : AppTheme.textSec,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            team.name,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${team.gamesWon}V ${team.gamesDrawn}E ${team.gamesLost}D',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '$winRate% victorias',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}
