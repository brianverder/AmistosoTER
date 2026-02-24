import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/matches_provider.dart';
import '../../providers/requests_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/teams_provider.dart';
import '../../widgets/app_widgets.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// Dashboard principal — Rediseño 2026
/// ──────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user   = ref.watch(currentUserProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 768;

    final mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hero banner ──────────────────────────────────────────────────
        _HeroBanner(
          userName: user?.name,
          onNewRequest: () => context.go('/dashboard/requests/new'),
        ),
        const SizedBox(height: 24),

        // ── Stats compactos ──────────────────────────────────────────────
        _CompactStats(isWide: isWide),
        const SizedBox(height: 28),

        // ── Solicitudes + Partidos ───────────────────────────────────────
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
        const SizedBox(height: 28),

        // ── Mis equipos ──────────────────────────────────────────────────
        const _MyTeamsSection(),
        const SizedBox(height: 32),
      ],
    );

    // ── Wide: panel ranking a la derecha ─────────────────────────────────
    if (isWide) {
      return SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: mainContent),
            const SizedBox(width: 24),
            const SizedBox(
              width: 280,
              child: _GlobalRankingPanel(),
            ),
          ],
        ),
      );
    }

    // ── Narrow: columna única ────────────────────────────────────────────
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          mainContent,
          const _GlobalRankingPanel(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HERO BANNER — gradient card with greeting + CTA
// ═══════════════════════════════════════════════════════════════════════════════

class _HeroBanner extends StatelessWidget {
  final String? userName;
  final VoidCallback onNewRequest;

  const _HeroBanner({required this.userName, required this.onNewRequest});

  static const _dias  = ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'];
  static const _meses = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];

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

  String get _motivational {
    final h = DateTime.now().hour;
    if (h < 12) return '¡Arrancá el día con un amistoso! ⚡';
    if (h < 18) return '¡Hora de buscar rival y jugar! 🔥';
    return '¡Organizá el partido de mañana! 🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF047857), Color(0xFF065F46)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ── Decorative circles ──────────────────────────────────────
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 50,
            bottom: -40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -25,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('👋', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$_greeting, ${userName ?? 'Jugador'}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 42),
                child: Text(
                  '📅 $_date',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.75),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _motivational,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onNewRequest,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 18, color: AppTheme.primary),
                        SizedBox(width: 6),
                        Text(
                          'Nueva Solicitud',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// COMPACT STATS — 3 colorful mini-cards
// ═══════════════════════════════════════════════════════════════════════════════

class _CompactStats extends ConsumerWidget {
  final bool isWide;
  const _CompactStats({required this.isWide});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync    = ref.watch(teamsNotifierProvider);
    final requestsAsync = ref.watch(requestsProvider(const RequestFilters(tab: 'available')));
    final matchesAsync  = ref.watch(matchesNotifierProvider);

    final teamsCount    = teamsAsync.valueOrNull?.length    ?? 0;
    final requestsCount = requestsAsync.valueOrNull?.length ?? 0;
    final matchesCount  = matchesAsync.valueOrNull?.length  ?? 0;

    if (teamsAsync.isLoading && teamsCount == 0) {
      return Row(
        children: List.generate(3, (_) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        )),
      );
    }

    final items = [
      _MiniStatData(
        emoji: '⚽',
        label: 'Equipos',
        value: teamsCount,
        colors: const [Color(0xFF059669), Color(0xFF10B981)],
        onTap: () => context.go('/dashboard/teams'),
      ),
      _MiniStatData(
        emoji: '📋',
        label: 'Amistosos',
        value: requestsCount,
        colors: const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
        onTap: () => context.go('/dashboard/requests'),
      ),
      _MiniStatData(
        emoji: '🏆',
        label: 'Partidos',
        value: matchesCount,
        colors: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
        onTap: () => context.go('/dashboard/matches'),
      ),
    ];

    if (isWide) {
      return Row(
        children: items.asMap().entries.map((e) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: e.key == 0 ? 0 : 8,
              right: e.key == 2 ? 0 : 8,
            ),
            child: _MiniStatCard(data: e.value),
          ),
        )).toList(),
      );
    }

    return Column(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _MiniStatCard(data: item),
      )).toList(),
    );
  }
}

class _MiniStatData {
  final String emoji;
  final String label;
  final int value;
  final List<Color> colors;
  final VoidCallback onTap;

  const _MiniStatData({
    required this.emoji,
    required this.label,
    required this.value,
    required this.colors,
    required this.onTap,
  });
}

class _MiniStatCard extends StatefulWidget {
  final _MiniStatData data;
  const _MiniStatCard({required this.data});

  @override
  State<_MiniStatCard> createState() => _MiniStatCardState();
}

class _MiniStatCardState extends State<_MiniStatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: d.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: d.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: d.colors[0].withOpacity(_hovered ? 0.35 : 0.2),
                blurRadius: _hovered ? 16 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          transform: _hovered
              ? (Matrix4.identity()..translate(0.0, -2.0))
              : Matrix4.identity(),
          child: Row(
            children: [
              Text(d.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.value.toString(),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      d.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                transform: _hovered
                    ? Matrix4.translationValues(3, 0, 0)
                    : Matrix4.identity(),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RECENT REQUESTS
// ═══════════════════════════════════════════════════════════════════════════════

class _RecentRequestsSection extends ConsumerWidget {
  const _RecentRequestsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(requestsProvider(const RequestFilters(tab: 'my')));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ColoredSectionHeader(
          emoji: '📝',
          title: 'Mis Solicitudes',
          color: AppTheme.info,
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
              return _EmptySection(
                emoji: '📄',
                title: 'Sin solicitudes aún',
                subtitle: 'Crea tu primera solicitud para encontrar rivales',
                buttonLabel: 'Crear solicitud',
                onAction: () => context.go('/dashboard/requests/new'),
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

// ═══════════════════════════════════════════════════════════════════════════════
// ACTIVE MATCHES
// ═══════════════════════════════════════════════════════════════════════════════

class _ActiveMatchesSection extends ConsumerWidget {
  const _ActiveMatchesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ColoredSectionHeader(
          emoji: '🤝',
          title: 'Matches Activos',
          color: AppTheme.accent,
          action: TextButton(
            onPressed: () => context.go('/dashboard/matches'),
            child: const Text('Ver todos →'),
          ),
        ),
        const SizedBox(height: 12),
        matchesAsync.when(
          loading: () => const AppSkeletonList(count: 3),
          error: (_, __) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppCallout(
                message: 'No se pudieron cargar los matches.',
                type: AppCalloutType.error,
              ),
              TextButton.icon(
                onPressed: () => ref.invalidate(matchesNotifierProvider),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reintentar'),
              ),
            ],
          ),
          data: (matches) {
            final active = matches.where((m) => m.matchResult == null).take(3).toList();
            if (active.isEmpty) {
              return const _EmptySection(
                emoji: '🏟️',
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

// ═══════════════════════════════════════════════════════════════════════════════
// MY TEAMS
// ═══════════════════════════════════════════════════════════════════════════════

class _MyTeamsSection extends ConsumerWidget {
  const _MyTeamsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ColoredSectionHeader(
          emoji: '⚽',
          title: 'Mis Equipos',
          color: AppTheme.primary,
          action: TextButton(
            onPressed: () => context.go('/dashboard/teams'),
            child: const Text('Ver todos →'),
          ),
        ),
        const SizedBox(height: 12),
        teamsAsync.when(
          loading: () => const AppSkeletonList(count: 2),
          error: (_, __) => const SizedBox(),
          data: (teams) {
            if (teams.isEmpty) {
              return _EmptySection(
                emoji: '👥',
                title: 'Aún no tienes equipos',
                subtitle: 'Crea tu primer equipo para empezar a jugar',
                buttonLabel: 'Crear equipo',
                onAction: () => context.go('/dashboard/teams/new'),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: i == 0
                          ? AppTheme.primaryFaint
                          : Colors.transparent,
                      border: isLast
                          ? null
                          : const Border(
                              bottom: BorderSide(color: AppTheme.border, width: 1),
                            ),
                    ),
                    child: Row(
                      children: [
                        _TeamRankBadge(position: i + 1),
                        const SizedBox(width: 12),
                        AppAvatar(name: team.name, size: 32),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                team.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.text,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _RecordChip(label: '${team.gamesWon}V', color: AppTheme.success),
                                  const SizedBox(width: 4),
                                  _RecordChip(label: '${team.gamesDrawn}E', color: AppTheme.textMuted),
                                  const SizedBox(width: 4),
                                  _RecordChip(label: '${team.gamesLost}D', color: AppTheme.error),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _WinRateBadge(winRate: winRate),
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

// ═══════════════════════════════════════════════════════════════════════════════
// GLOBAL RANKING PANEL (derecha)
// ═══════════════════════════════════════════════════════════════════════════════

class _GlobalRankingPanel extends ConsumerWidget {
  const _GlobalRankingPanel();

  static const _gold   = Color(0xFFF59E0B);
  static const _silver = Color(0xFF94A3B8);
  static const _bronze = Color(0xFFCD7F32);

  Color _rankColor(int pos) {
    if (pos == 1) return _gold;
    if (pos == 2) return _silver;
    if (pos == 3) return _bronze;
    return AppTheme.textMuted;
  }

  String _rankEmoji(int pos) {
    if (pos == 1) return '🥇';
    if (pos == 2) return '🥈';
    if (pos == 3) return '🥉';
    return '#$pos';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(topTeamsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header con gradiente ────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _gold.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('🏆', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 8),
                  Text(
                    'Top Ganadores',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Equipos con más partidos ganados en la plataforma',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Ranking list ────────────────────────────────────────────────
        async.when(
          loading: () => const AppSkeletonList(count: 5),
          error: (_, __) => const SizedBox(),
          data: (teams) {
            if (teams.isEmpty) {
              return AppCard(
                child: Column(
                  children: const [
                    SizedBox(height: 8),
                    Text('😴', style: TextStyle(fontSize: 32)),
                    SizedBox(height: 10),
                    Text(
                      'Aún no hay partidos\njugados',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              );
            }

            return AppCard(
              noPadding: true,
              child: Column(
                children: teams.asMap().entries.map((entry) {
                  final pos    = entry.key + 1;
                  final team   = entry.value;
                  final isLast = pos == teams.length;
                  final color  = _rankColor(pos);
                  final emoji  = _rankEmoji(pos);

                  return Container(
                    decoration: BoxDecoration(
                      color: pos == 1
                          ? _gold.withOpacity(0.06)
                          : Colors.transparent,
                      border: isLast
                          ? null
                          : const Border(
                              bottom: BorderSide(color: AppTheme.border, width: 1),
                            ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          child: pos <= 3
                              ? Text(emoji, style: const TextStyle(fontSize: 18))
                              : Text(
                                  '#$pos',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                team.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: pos == 1 ? FontWeight.w700 : FontWeight.w600,
                                  color: AppTheme.text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (team.league != null && team.league!.isNotEmpty)
                                const SizedBox(height: 2),
                              if (team.league != null && team.league!.isNotEmpty)
                                Text(
                                  team.league!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: pos == 1
                                ? AppTheme.primaryLight
                                : AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.emoji_events_rounded,
                                size: 12,
                                color: pos == 1
                                    ? AppTheme.primaryDark
                                    : AppTheme.textSec,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${team.gamesWon}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: pos == 1
                                      ? AppTheme.primaryDark
                                      : AppTheme.textSec,
                                ),
                              ),
                            ],
                          ),
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

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Section header with emoji + colored accent ─────────────────────────────

class _ColoredSectionHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final Color color;
  final Widget? action;

  const _ColoredSectionHeader({
    required this.emoji,
    required this.title,
    required this.color,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 17)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.text,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

// ─── Empty state with emoji ──────────────────────────────────────────────────

class _EmptySection extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onAction;

  const _EmptySection({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
          if (buttonLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            AppButton(label: buttonLabel!, onPressed: onAction!),
          ],
        ],
      ),
    );
  }
}

// ─── Request list item ──────────────────────────────────────────────────────

class _RequestListItem extends StatefulWidget {
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
  State<_RequestListItem> createState() => _RequestListItemState();
}

class _RequestListItemState extends State<_RequestListItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.primaryFaint : AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? AppTheme.primary.withOpacity(0.3) : AppTheme.border,
            ),
            boxShadow: _hovered ? AppTheme.shadowSm : null,
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: _statusColor(widget.status),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.text,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              StatusBadge(status: widget.status),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: _hovered ? AppTheme.primary : AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
      case 'open':
        return AppTheme.success;
      case 'pending':
        return AppTheme.warning;
      case 'accepted':
        return AppTheme.info;
      case 'completed':
        return AppTheme.textMuted;
      default:
        return AppTheme.border;
    }
  }
}

// ─── Match list item ────────────────────────────────────────────────────────

class _MatchListItem extends StatefulWidget {
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
  State<_MatchListItem> createState() => _MatchListItemState();
}

class _MatchListItemState extends State<_MatchListItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFFFF8E1) : AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? AppTheme.accent.withOpacity(0.3) : AppTheme.border,
            ),
            boxShadow: _hovered ? AppTheme.shadowSm : null,
          ),
          child: Row(
            children: [
              // Split avatar (overlapping team initials)
              SizedBox(
                width: 44,
                height: 36,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      child: AppAvatar(name: widget.team1, size: 28),
                    ),
                    Positioned(
                      left: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.surface, width: 2),
                        ),
                        child: AppAvatar(name: widget.team2, size: 28),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.team1} vs ${widget.team2}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '⚔️ Amistoso',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: widget.status),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: _hovered ? AppTheme.accent : AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Team rank badge ────────────────────────────────────────────────────────

class _TeamRankBadge extends StatelessWidget {
  final int position;
  const _TeamRankBadge({required this.position});

  @override
  Widget build(BuildContext context) {
    const emojis = ['🥇', '🥈', '🥉'];
    if (position <= 3) {
      return Text(emojis[position - 1], style: const TextStyle(fontSize: 18));
    }
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(7),
      ),
      alignment: Alignment.center,
      child: Text(
        '#$position',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppTheme.textSec,
        ),
      ),
    );
  }
}

// ─── Record chip ────────────────────────────────────────────────────────────

class _RecordChip extends StatelessWidget {
  final String label;
  final Color color;
  const _RecordChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── Win rate badge ─────────────────────────────────────────────────────────

class _WinRateBadge extends StatelessWidget {
  final String winRate;
  const _WinRateBadge({required this.winRate});

  @override
  Widget build(BuildContext context) {
    final rate = double.tryParse(winRate) ?? 0;
    final isGood = rate >= 50;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: isGood
            ? const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
              )
            : null,
        color: isGood ? null : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        '$winRate%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isGood ? Colors.white : AppTheme.textSec,
        ),
      ),
    );
  }
}
