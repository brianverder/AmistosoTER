import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/matches_provider.dart';
import '../../widgets/app_widgets.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            const SizedBox(height: AppConstants.spacingLg),
            Expanded(
              child: matchesAsync.when(
                loading: () => const AppLoadingScreen(),
                error: (e, _) => EmptyState(
                  icon: Icons.error_outline,
                  title: 'Error al cargar partidos',
                  subtitle: e.toString(),
                ),
                data: (matches) {
                  if (matches.isEmpty) {
                    return const EmptyState(
                      icon: Icons.sports_soccer,
                      title: 'Sin partidos aún',
                      subtitle:
                          'Acepta una solicitud disponible para confirmar un partido',
                    );
                  }
                  return ListView.separated(
                    itemCount: matches.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppConstants.spacingSm),
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      final isCompleted = match.matchResult != null;
                      return AppCard(
                        child: InkWell(
                          onTap: () => context.go(
                            AppRoutes.matchDetail
                                .replaceFirst(':id', match.id),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppConstants.spacingMd),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.shield,
                                              size: 16),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              match.team1?.name ?? 'Equipo 1',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: isCompleted &&
                                              match.matchResult != null
                                          ? Text(
                                              '${match.matchResult!.team1Score} - ${match.matchResult!.team2Score}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 18,
                                              ),
                                            )
                                          : const Text(
                                              'VS',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              match.team2?.name ?? 'Equipo 2',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.shield,
                                              size: 16),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (match.matchRequest?.matchDate != null)
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today,
                                              size: 12,
                                              color: AppTheme.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('dd/MM/yy')
                                                .format(match.matchRequest!.matchDate!),
                                            style: TextStyle(
                                              color: AppTheme.textMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      const SizedBox.shrink(),
                                    Row(
                                      children: [
                                        if (isCompleted)
                                          const Icon(Icons.check_circle_rounded,
                                              size: 16,
                                              color: AppTheme.success)
                                        else
                                          const Icon(Icons.schedule_rounded,
                                              size: 16,
                                              color: AppTheme.accent),
                                        const SizedBox(width: 4),
                                        StatusBadge(
                                          status: isCompleted
                                              ? 'completed'
                                              : match.status.name,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
    );
  }
}
