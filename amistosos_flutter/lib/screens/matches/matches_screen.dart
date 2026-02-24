import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/match_model.dart';
import '../../providers/matches_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/skeleton.dart';

// ─── Main screen ──────────────────────────────────────────────────────────────

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    // Refresh on every navigation to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(matchesNotifierProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final matchesAsync = ref.watch(matchesNotifierProvider);

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'MIS PARTIDOS',
            subtitle: 'Historial y partidos confirmados',
          ),
          const SizedBox(height: AppConstants.spacingMd),
          _FilterRow(
            selected: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Expanded(
            child: matchesAsync.when(
              loading: () => _SkeletonList(),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Error al cargar partidos',
                subtitle: e.toString(),
              ),
              data: (matches) {
                final filtered = _applyFilter(matches, _filter);
                if (filtered.isEmpty) {
                  return _EmptyMatches(filter: _filter);
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MatchCard(match: filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<MatchModel> _applyFilter(List<MatchModel> matches, _Filter f) {
    switch (f) {
      case _Filter.upcoming:
        return matches.where((m) => !m.isCompleted).toList();
      case _Filter.completed:
        return matches.where((m) => m.isCompleted).toList();
      case _Filter.all:
        return matches;
    }
  }
}

// ─── Filter enum & row ────────────────────────────────────────────────────────

enum _Filter { all, upcoming, completed }

extension _FilterLabel on _Filter {
  String get label {
    switch (this) {
      case _Filter.all:
        return 'Todos';
      case _Filter.upcoming:
        return 'Próximos';
      case _Filter.completed:
        return 'Completados';
    }
  }

  IconData get icon {
    switch (this) {
      case _Filter.all:
        return Icons.apps_rounded;
      case _Filter.upcoming:
        return Icons.schedule_rounded;
      case _Filter.completed:
        return Icons.check_circle_rounded;
    }
  }
}

class _FilterRow extends StatelessWidget {
  final _Filter selected;
  final ValueChanged<_Filter> onChanged;
  const _FilterRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _Filter.values.map((f) {
        final active = f == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active ? AppTheme.primary : AppTheme.border,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(f.icon, size: 13, color: active ? Colors.white : AppTheme.textMuted),
                  const SizedBox(width: 5),
                  Text(
                    f.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Match card ───────────────────────────────────────────────────────────────

class _MatchCard extends StatefulWidget {
  final MatchModel match;
  const _MatchCard({required this.match});

  @override
  State<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<_MatchCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final theme = _resolveTheme(match);
    final date = match.matchRequest?.matchDate;
    final address = match.matchRequest?.fieldAddress;
    final footballType = match.matchRequest?.footballType;
    final league1 = match.team1?.league;
    final league2 = match.team2?.league;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? theme.accent : AppTheme.border,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? theme.accent.withOpacity(0.12)
                  : Colors.black.withOpacity(0.04),
              blurRadius: _hovered ? 20 : 8,
              offset: Offset(0, _hovered ? 6 : 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => context.go(
              AppRoutes.matchDetail.replaceFirst(':id', match.id)),
          borderRadius: BorderRadius.circular(16),
          splashColor: theme.accent.withAlpha(8),
          highlightColor: AppTheme.surfaceVariant.withOpacity(0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top bar: status + football type + date ───────────
              Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.accent.withOpacity(0.06),
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
                    theme.badge,
                    const SizedBox(width: 8),
                    if (footballType != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sports_soccer_rounded,
                                size: 11, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Text('Fútbol $footballType',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (date != null) ...[
                      Icon(Icons.calendar_today_rounded,
                          size: 12, color: theme.accent),
                      const SizedBox(width: 5),
                      Text(
                        _formatDateNatural(date),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.accent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Teams confrontation ─────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: Row(
                  children: [
                    // Team 1
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.accent.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: AppAvatar(
                                name: match.team1?.name ?? 'E1',
                                size: 42),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            match.team1?.name ?? 'Equipo 1',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppTheme.text,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          if (league1 != null && league1.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              league1,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.accentDark,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Score / VS
                    _ScoreBox(match: match, accent: theme.accent),

                    // Team 2
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.accent.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: AppAvatar(
                                name: match.team2?.name ?? 'E2',
                                size: 42),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            match.team2?.name ?? 'Equipo 2',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppTheme.text,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          if (league2 != null && league2.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              league2,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.accentDark,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Detail info section ─────────────────────────────
              if (address != null || (league1 ?? league2) != null) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.border.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        if (address != null && address.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.stadium_rounded,
                                  size: 14, color: AppTheme.textMuted),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  address,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSec,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateNatural(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    final dayName = DateFormat('EEEE', 'es').format(date);
    final dayCapitalized =
        '${dayName[0].toUpperCase()}${dayName.substring(1)}';
    final dateStr = DateFormat('dd MMM').format(date);
    final time = DateFormat('HH:mm').format(date);

    if (diff == 0) return 'Hoy · $time';
    if (diff == 1) return 'Mañana · $time';
    if (diff > 1 && diff <= 6) return '$dayCapitalized · $time';
    return '$dateStr · $time';
  }

  _CardTheme _resolveTheme(MatchModel match) {
    if (match.isCompleted) {
      return _CardTheme(
        accent: AppTheme.textMuted,
        badge: const _StatusPill(
          icon: Icons.check_circle_rounded,
          label: 'Finalizado',
          color: AppTheme.textMuted,
          bg: AppTheme.surfaceVariant,
        ),
      );
    }
    final matchDate = match.matchRequest?.matchDate;
    final isUpcoming =
        matchDate != null && matchDate.isAfter(DateTime.now());
    if (isUpcoming) {
      final days = matchDate!.difference(DateTime.now()).inDays;
      String label = 'Próximo';
      if (days == 0) label = 'Hoy';
      if (days == 1) label = 'Mañana';
      return _CardTheme(
        accent: AppTheme.primary,
        badge: _StatusPill(
          icon: Icons.schedule_rounded,
          label: label,
          color: AppTheme.primary,
          bg: AppTheme.primary.withOpacity(0.08),
        ),
      );
    }
    if (match.status == MatchStatus.confirmed) {
      return _CardTheme(
        accent: AppTheme.info,
        badge: _StatusPill(
          icon: Icons.handshake_rounded,
          label: 'Confirmado',
          color: AppTheme.info,
          bg: AppTheme.info.withOpacity(0.08),
        ),
      );
    }
    return _CardTheme(
      accent: const Color(0xFFD97706),
      badge: const _StatusPill(
        icon: Icons.hourglass_top_rounded,
        label: 'Pendiente',
        color: Color(0xFFD97706),
        bg: Color(0xFFFEF3C7),
      ),
    );
  }
}

class _CardTheme {
  final Color accent;
  final Widget badge;
  const _CardTheme({required this.accent, required this.badge});
}

// ─── Status pill ──────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

// ─── Score box ────────────────────────────────────────────────────────────────

class _ScoreBox extends StatelessWidget {
  final MatchModel match;
  final Color accent;
  const _ScoreBox({required this.match, required this.accent});

  @override
  Widget build(BuildContext context) {
    final result = match.matchResult;
    if (result != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                '${result.team1Score}  –  ${result.team2Score}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: AppTheme.text,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _winnerLabel(result, match),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: result.winnerId != null
                    ? AppTheme.primary
                    : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    // VS indicator
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: accent.withOpacity(0.08),
          shape: BoxShape.circle,
          border:
              Border.all(color: accent.withOpacity(0.25), width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          'VS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            color: accent,
          ),
        ),
      ),
    );
  }

  String _winnerLabel(MatchResultModel result, MatchModel match) {
    if (result.winnerId == null) return 'Empate';
    if (result.winnerId == match.team1Id) {
      return '${match.team1?.name ?? ''} gana';
    }
    return '${match.team2?.name ?? ''} gana';
  }
}

// ─── Skeleton list ────────────────────────────────────────────────────────────

class _SkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 4,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: AppSkeletonCard(),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyMatches extends StatelessWidget {
  final _Filter filter;
  const _EmptyMatches({required this.filter});

  @override
  Widget build(BuildContext context) {
    switch (filter) {
      case _Filter.upcoming:
        return const Center(
          child: EmptyState(
            icon: Icons.sports_soccer_rounded,
            title: 'Sin partidos próximos',
            subtitle: 'Acepta una solicitud disponible para confirmar tu siguiente partido',
          ),
        );
      case _Filter.completed:
        return const Center(
          child: EmptyState(
            icon: Icons.emoji_events_rounded,
            title: 'Sin partidos finalizados',
            subtitle: 'Registra el resultado de tus partidos aquí',
          ),
        );
      case _Filter.all:
        return const Center(
          child: EmptyState(
            icon: Icons.sports_soccer_rounded,
            title: 'Sin partidos aún',
            subtitle: 'Acepta una solicitud disponible para confirmar un partido',
          ),
        );
    }
  }
}
