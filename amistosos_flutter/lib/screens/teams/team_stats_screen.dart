import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../providers/teams_provider.dart';
import '../../widgets/app_widgets.dart';

class TeamStatsScreen extends ConsumerWidget {
  final String teamId;
  const TeamStatsScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamDetailProvider(teamId));
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go(
                        AppRoutes.teamDetail.replaceFirst(':id', teamId),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: teamAsync.when(
                        loading: () => const Text('Estadísticas'),
                        error: (_, __) => const Text('Estadísticas'),
                        data: (team) => SectionHeader(
                          title: 'ESTADÍSTICAS',
                          subtitle: team?.name,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingLg),
                teamAsync.when(
                  loading: () => const AppLoadingScreen(),
                  error: (e, _) => EmptyState(
                    icon: Icons.error_outline,
                    title: 'Error',
                    subtitle: e.toString(),
                  ),
                  data: (team) {
                    if (team == null) {
                      return const EmptyState(
                        icon: Icons.search_off,
                        title: 'Equipo no encontrado',
                        subtitle: '',
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main stats grid
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cols = constraints.maxWidth < 500 ? 2 : 4;
                            return _StatsGrid(
                              items: [
                                _StatItem(
                                    label: 'GANADOS',
                                    value: team.gamesWon.toString()),
                                _StatItem(
                                    label: 'EMPATADOS',
                                    value: team.gamesDrawn.toString()),
                                _StatItem(
                                    label: 'PERDIDOS',
                                    value: team.gamesLost.toString()),
                                _StatItem(
                                    label: 'TOTAL PARTIDOS',
                                    value: team.totalGames.toString()),
                              ],
                              columns: cols,
                            );
                          },
                        ),
                        const SizedBox(height: AppConstants.spacingMd),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cols = constraints.maxWidth < 500 ? 2 : 3;
                            return _StatsGrid(
                              items: [
                                _StatItem(
                                  label: 'WIN RATE',
                                  value:
                                      '${team.winRate.toStringAsFixed(1)}%',
                                  highlight: true,
                                ),
                                _StatItem(
                                  label: 'PUNTOS',
                                  value: team.points.toString(),
                                  highlight: true,
                                ),
                                _StatItem(
                                  label: 'PUNTOS/PJ',
                                  value: team.totalGames > 0
                                      ? (team.points / team.totalGames)
                                          .toStringAsFixed(2)
                                      : '—',
                                ),
                              ],
                              columns: cols,
                            );
                          },
                        ),
                        const SizedBox(height: AppConstants.spacingLg),
                        // Win rate bar
                        AppCard(
                          child: Padding(
                            padding:
                                const EdgeInsets.all(AppConstants.spacingMd),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DISTRIBUCIÓN DE RESULTADOS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: AppConstants.spacingMd),
                                if (team.totalGames > 0) ...[
                                  _ResultBar(
                                    label: 'Ganados',
                                    count: team.gamesWon,
                                    total: team.totalGames,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(height: 8),
                                  _ResultBar(
                                    label: 'Empatados',
                                    count: team.gamesDrawn,
                                    total: team.totalGames,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(height: 8),
                                  _ResultBar(
                                    label: 'Perdidos',
                                    count: team.gamesLost,
                                    total: team.totalGames,
                                    color: Colors.grey.shade300,
                                  ),
                                ] else
                                  const Text(
                                    'Sin partidos jugados',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingLg),
                        // Extended stats from API — reuses teamDetailProvider data
                        const SizedBox.shrink(),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final bool highlight;
  _StatItem({required this.label, required this.value, this.highlight = false});
}

class _StatsGrid extends StatelessWidget {
  final List<_StatItem> items;
  final int columns;
  const _StatsGrid({required this.items, required this.columns});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += columns) {
      final rowItems = items.sublist(
        i,
        (i + columns) < items.length ? i + columns : items.length,
      );
      rows.add(
        Row(
          children: rowItems.asMap().entries.map((entry) {
            final item = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: entry.key < rowItems.length - 1
                      ? AppConstants.spacingSm
                      : 0,
                ),
                child: StatCard(
                  title: item.label,
                  value: item.value,
                ),
              ),
            );
          }).toList(),
        ),
      );
      if (i + columns < items.length) {
        rows.add(const SizedBox(height: AppConstants.spacingSm));
      }
    }
    return Column(children: rows);
  }
}

class _ResultBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  const _ResultBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 20,
                color: Colors.grey.shade100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1),
                ),
              ),
              FractionallySizedBox(
                widthFactor: pct.clamp(0.0, 1.0),
                child: Container(
                  height: 20,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '$count (${(pct * 100).toStringAsFixed(0)}%)',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
