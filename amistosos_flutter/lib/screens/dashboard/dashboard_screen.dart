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

/// Pantalla principal del dashboard
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user    = ref.watch(currentUserProvider);
    final isWide  = MediaQuery.sizeOf(context).width >= 768;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          _DashboardHeader(
            userName: user?.name,
            onNewRequest: () => context.go('/dashboard/requests/new'),
          ),
          const SizedBox(height: 28),

          // ── Métricas ─────────────────────────────────────────────────────
          _StatsSection(isWide: isWide),
          const SizedBox(height: 28),

          // ── Acciones rápidas ─────────────────────────────────────────────
          _QuickActionsSection(isWide: isWide),
          const SizedBox(height: 32),

          // ── Contenido (solicitudes + matches) ────────────────────────────
          if (isWide)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Expanded(child: _RecentRequestsSection()),
                  SizedBox(width: 20),
                  Expanded(child: _ActiveMatchesSection()),
                ],
              ),
            )
          else ...[
            const _RecentRequestsSection(),
            const SizedBox(height: 20),
            const _ActiveMatchesSection(),
          ],
          const SizedBox(height: 32),

          // ── Ranking de equipos ───────────────────────────────────────────
          const _TopTeamsSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  final String? userName;
  final VoidCallback onNewRequest;

  const _DashboardHeader({
    required this.userName,
    required this.onNewRequest,
  });

  static const _dias   = ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'];
  static const _meses  = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String get _date {
    final n = DateTime.now();
    return '${_dias[n.weekday - 1]}, ${n.day} de ${_meses[n.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting, ${userName ?? 'Jugador'}',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                _date,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        AppButton(
          label: 'Nueva Solicitud',
          icon: Icons.add_rounded,
          onPressed: onNewRequest,
        ),
      ],
    );
  }
}

// ─── Stats ────────────────────────────────────────────────────────────────────

class _StatsSection extends ConsumerWidget {
  final bool isWide;
  const _StatsSection({required this.isWide});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync    = ref.watch(teamsNotifierProvider);
    final requestsAsync = ref.watch(requestsProvider(const RequestFilters(tab: 'available')));
    final matchesAsync  = ref.watch(matchesNotifierProvider);

    final teamsCount    = teamsAsync.valueOrNull?.length    ?? 0;
    final requestsCount = requestsAsync.valueOrNull?.length ?? 0;
    final matchesCount  = matchesAsync.valueOrNull?.length  ?? 0;

    // Esqueletos en primera carga
    if (teamsAsync.isLoading && teamsCount == 0) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: isWide ? 3 : 1,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isWide ? 1.7 : 3.2,
        children: List.generate(3, (_) => const AppSkeletonStatCard()),
      );
    }

    return Builder(
      builder: (ctx) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: isWide ? 3 : 1,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isWide ? 1.7 : 3.2,
        children: [
          StatCard(
            label: 'Equipos',
            value: teamsCount.toString(),
            emoji: '⚽',
            onTap: () => ctx.go('/dashboard/teams'),
          ),
          StatCard(
            label: 'Solicitudes',
            value: requestsCount.toString(),
            emoji: '📋',
            onTap: () => ctx.go('/dashboard/requests'),
          ),
          StatCard(
            label: 'Partidos',
            value: matchesCount.toString(),
            emoji: '🏆',
            onTap: () => ctx.go('/dashboard/matches'),
          ),
        ],
      ),
    );
  }
}

// ─── Quick actions ────────────────────────────────────────────────────────────

class _QuickActionsSection extends StatelessWidget {
  final bool isWide;
  const _QuickActionsSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Acciones rápidas'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            QuickActionCard(
              icon: '⚽',
              title: 'Crear Equipo',
              subtitle: 'Registra tu equipo',
              onTap: () => context.go('/dashboard/teams/new'),
            ),
            QuickActionCard(
              icon: '📋',
              title: 'Nueva Solicitud',
              subtitle: 'Busca rivales',
              onTap: () => context.go('/dashboard/requests/new'),
            ),
            QuickActionCard(
              icon: '🔍',
              title: 'Ver Solicitudes',
              subtitle: 'Solicitudes activas',
              onTap: () => context.go('/dashboard/requests'),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Recent requests ──────────────────────────────────────────────────────────

class _RecentRequestsSection extends ConsumerWidget {
  const _RecentRequestsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(requestsProvider(const RequestFilters(tab: 'my')));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Mis Solicitudes',
          action: TextButton(
            onPressed: () => context.go('/dashboard/requests'),
            child: const Text('Ver todas →'),
          ),
        ),
        const SizedBox(height: 12),
        requestsAsync.when(
          loading: () => const AppSkeletonList(count: 3),
          error: (_, __) => const AppCallout(
            message: 'No se pudieron cargar las solicitudes.',
            type: AppCalloutType.error,
          ),
          data: (requests) {
            final items = requests.take(3).toList();
            if (items.isEmpty) {
              return EmptyState(
                icon: Icons.assignment_outlined,
                title: 'Sin solicitudes aún',
                subtitle: 'Crea tu primera solicitud para encontrar rivales',
                action: AppButton(
                  label: 'Crear solicitud',
                  onPressed: () => context.go('/dashboard/requests/new'),
                ),
              );
            }
            return Column(
              children: items.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _RequestListItem(
                  name: r.team?.name ?? 'Sin equipo',
                  subtitle: r.footballType != null
                      ? AppConstants.footballTypeLabel(r.footballType ?? '')
                      : null,
                  status: r.status.name,
                  onTap: () => context.go('/dashboard/requests/${r.id}'),
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ─── Active matches ───────────────────────────────────────────────────────────

class _ActiveMatchesSection extends ConsumerWidget {
  const _ActiveMatchesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Matches Activos',
          action: TextButton(
            onPressed: () => context.go('/dashboard/matches'),
            child: const Text('Ver todos →'),
          ),
        ),
        const SizedBox(height: 12),
        matchesAsync.when(
          loading: () => const AppSkeletonList(count: 3),
          error: (_, __) => const AppCallout(
            message: 'No se pudieron cargar los matches.',
            type: AppCalloutType.error,
          ),
          data: (matches) {
            final active = matches.where((m) => m.matchResult == null).take(3).toList();
            if (active.isEmpty) {
              return const EmptyState(
                icon: Icons.handshake_outlined,
                title: 'Sin matches activos',
                subtitle: 'Tus matches confirmados aparecerán aquí',
              );
            }
            return Column(
              children: active.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MatchListItem(
                  team1: m.team1?.name ?? '?',
                  team2: m.team2?.name ?? '?',
                  status: m.isCompleted ? 'completed' : m.status.name,
                  onTap: () => context.go('/dashboard/matches/${m.id}'),
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ─── Top teams ────────────────────────────────────────────────────────────────

class _TopTeamsSection extends ConsumerWidget {
  const _TopTeamsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Mis Equipos'),
        const SizedBox(height: 12),
        teamsAsync.when(
          loading: () => const AppSkeletonList(count: 2),
          error: (_, __) => const SizedBox(),
          data: (teams) {
            if (teams.isEmpty) {
              return EmptyState(
                icon: Icons.groups_outlined,
                title: 'Aún no tienes equipos',
                subtitle: 'Crea tu primer equipo para empezar a jugar',
                action: AppButton(
                  label: 'Crear equipo',
                  onPressed: () => context.go('/dashboard/teams/new'),
                ),
              );
            }
            final sorted = [...teams]
              ..sort((a, b) => b.gamesWon.compareTo(a.gamesWon));
            return AppCard(
              noPadding: true,
              child: Column(
                children: sorted.asMap().entries.map((entry) {
                  final i    = entry.key;
                  final team = entry.value;
                  final winRate = team.winRate.toStringAsFixed(0);
                  final isLast = i == sorted.length - 1;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : Border(
                              bottom: BorderSide(color: AppTheme.border, width: 1),
                            ),
                    ),
                    child: Row(
                      children: [
                        _RankBadge(position: i + 1),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            team.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.text,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _RecordLabel(label: '${team.gamesWon}V', color: AppTheme.success),
                            const SizedBox(width: 6),
                            _RecordLabel(label: '${team.gamesDrawn}E', color: AppTheme.textMuted),
                            const SizedBox(width: 6),
                            _RecordLabel(label: '${team.gamesLost}D', color: AppTheme.error),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: double.tryParse(winRate) != null && double.parse(winRate) >= 50
                                    ? AppTheme.primaryLight
                                    : AppTheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                              ),
                              child: Text(
                                '$winRate%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: double.tryParse(winRate) != null && double.parse(winRate) >= 50
                                      ? AppTheme.primaryDark
                                      : AppTheme.textSec,
                                ),
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

// ─── List item helpers ────────────────────────────────────────────────────────

class _RequestListItem extends StatelessWidget {
  final String name;
  final String? subtitle;
  final String status;
  final VoidCallback onTap;

  const _RequestListItem({
    required this.name,
    required this.status,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.text,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ],
            ),
          ),
          StatusBadge(status: status),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppTheme.textMuted),
        ],
      ),
    );
  }
}

class _MatchListItem extends StatelessWidget {
  final String team1;
  final String team2;
  final String status;
  final VoidCallback onTap;

  const _MatchListItem({
    required this.team1,
    required this.team2,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          AppAvatar(name: team1, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$team1 vs $team2',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.text,
              ),
            ),
          ),
          StatusBadge(status: status),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppTheme.textMuted),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int position;
  const _RankBadge({required this.position});

  @override
  Widget build(BuildContext context) {
    final isFirst = position == 1;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isFirst ? AppTheme.primary : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        '#$position',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isFirst ? Colors.white : AppTheme.textSec,
        ),
      ),
    );
  }
}

class _RecordLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _RecordLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}
