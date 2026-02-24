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

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? theme.accent : AppTheme.border,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: _hovered
              ? [BoxShadow(color: theme.accent.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Accent bar
                Container(width: 4, color: theme.accent),
                // Card body
                Expanded(
                  child: InkWell(
                    onTap: () => context.go(AppRoutes.matchDetail.replaceFirst(':id', match.id)),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: status badge + football type
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              theme.badge,
                              if (match.matchRequest?.footballType != null)
                                _FootballTypePill(type: match.matchRequest!.footballType!),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Teams + score
                          Row(
                            children: [
                              Expanded(
                                child: _TeamSide(
                                  name: match.team1?.name ?? 'Equipo 1',
                                  align: CrossAxisAlignment.start,
                                ),
                              ),
                              _ScoreBox(match: match),
                              Expanded(
                                child: _TeamSide(
                                  name: match.team2?.name ?? 'Equipo 2',
                                  align: CrossAxisAlignment.end,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Meta: date + address
                          _MetaRow(match: match, accent: theme.accent),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    final isUpcoming = matchDate != null && matchDate.isAfter(DateTime.now());
    if (isUpcoming) {
      return _CardTheme(
        accent: AppTheme.primary,
        badge: _StatusPill(
          icon: Icons.schedule_rounded,
          label: 'Próximo',
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
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ─── Football type pill ───────────────────────────────────────────────────────

class _FootballTypePill extends StatelessWidget {
  final String type;
  const _FootballTypePill({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sports_soccer_rounded, size: 11, color: AppTheme.textMuted),
          const SizedBox(width: 4),
          Text(
            'F$type',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─── Team side ────────────────────────────────────────────────────────────────

class _TeamSide extends StatelessWidget {
  final String name;
  final CrossAxisAlignment align;
  const _TeamSide({required this.name, required this.align});

  @override
  Widget build(BuildContext context) {
    final isLeft = align == CrossAxisAlignment.start;
    return Row(
      mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: isLeft
          ? [
              AppAvatar(name: name, size: 36),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.text, letterSpacing: -0.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]
          : [
              Flexible(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.text, letterSpacing: -0.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
              AppAvatar(name: name, size: 36),
            ],
    );
  }
}

// ─── Score box ────────────────────────────────────────────────────────────────

class _ScoreBox extends StatelessWidget {
  final MatchModel match;
  const _ScoreBox({required this.match});

  @override
  Widget build(BuildContext context) {
    final result = match.matchResult;
    if (result != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                '${result.team1Score}  –  ${result.team2Score}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: AppTheme.text,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _winnerLabel(result, match),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
            ),
          ],
        ),
      );
    }

    // VS indicator
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.08),
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 1.5),
        ),
        alignment: Alignment.center,
        child: const Text(
          'VS',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppTheme.primary),
        ),
      ),
    );
  }

  String _winnerLabel(MatchResultModel result, MatchModel match) {
    if (result.winnerId == null) return 'Empate';
    if (result.winnerId == match.team1Id) return '${match.team1?.name ?? ''} gana';
    return '${match.team2?.name ?? ''} gana';
  }
}

// ─── Meta row ─────────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final MatchModel match;
  final Color accent;
  const _MetaRow({required this.match, required this.accent});

  @override
  Widget build(BuildContext context) {
    final date = match.matchRequest?.matchDate;
    final address = match.matchRequest?.fieldAddress;
    final items = <Widget>[];

    if (date != null) {
      final formatted = DateFormat('dd MMM · HH:mm').format(date);
      items.add(_MetaChip(icon: Icons.calendar_today_rounded, label: formatted, color: accent));
    }
    if (address != null) {
      items.add(_MetaChip(icon: Icons.place_outlined, label: address, color: AppTheme.textMuted, maxWidth: 180));
    }

    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 6, children: items);
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double? maxWidth;
  const _MetaChip({required this.icon, required this.label, required this.color, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          if (maxWidth != null)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth!),
              child: Text(label,
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
            )
          else
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
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
