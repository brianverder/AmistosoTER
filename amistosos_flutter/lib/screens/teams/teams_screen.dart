import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../providers/teams_provider.dart';
import '../../widgets/app_widgets.dart';

class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsNotifierProvider);

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionHeader(
                  title: 'MIS EQUIPOS',
                  subtitle: 'Gestiona tus equipos de fútbol',
                ),
                AppButton(
                  label: '+ NUEVO EQUIPO',
                  onPressed: () => context.go(AppRoutes.createTeam),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingLg),
            Expanded(
              child: teamsAsync.when(
                loading: () => const AppLoadingScreen(),
                error: (e, _) => EmptyState(
                  icon: Icons.error_outline,
                  title: 'Error al cargar equipos',
                  subtitle: e.toString(),
                ),
                data: (teams) {
                  if (teams.isEmpty) {
                    return EmptyState(
                      icon: Icons.group_off,
                      title: 'No tienes equipos',
                      subtitle: 'Crea tu primer equipo para empezar',
                      action: AppButton(
                        label: '+ CREAR EQUIPO',
                        onPressed: () => context.go(AppRoutes.createTeam),
                      ),
                    );
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth < 600
                          ? 1
                          : constraints.maxWidth < 1024
                              ? 2
                              : 3;
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: AppConstants.spacingMd,
                          mainAxisSpacing: AppConstants.spacingMd,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: teams.length,
                        itemBuilder: (context, index) {
                          final team = teams[index];
                          return AppCard(
                            onTap: () => context.go(
                              AppRoutes.teamDetail.replaceFirst(':id', team.id),
                            ),
                            padding: const EdgeInsets.all(AppConstants.spacingMd),
                            child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.shield, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            team.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        _TeamMenu(
                                          onDetail: () => context.go(
                                            AppRoutes.teamDetail
                                                .replaceFirst(':id', team.id),
                                          ),
                                          onStats: () => context.go(
                                            AppRoutes.teamStats
                                                .replaceFirst(':id', team.id),
                                          ),
                                          onDelete: () => _confirmDelete(
                                            context,
                                            ref,
                                            team.id,
                                            team.name,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (team.instagram != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '@${team.instagram}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    const Divider(height: 1),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _StatPill(
                                          label: 'G',
                                          value: team.gamesWon,
                                          highlight: true,
                                        ),
                                        _StatPill(
                                          label: 'E',
                                          value: team.gamesDrawn,
                                        ),
                                        _StatPill(
                                          label: 'P',
                                          value: team.gamesLost,
                                          muted: true,
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              '${team.winRate.toStringAsFixed(0)}%',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const Text(
                                              'WIN',
                                              style: TextStyle(fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                          );
                        },
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

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String teamId,
    String teamName,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Eliminar equipo',
      message: '¿Eliminar "$teamName"? Esta acción no se puede deshacer.',
      confirmLabel: 'ELIMINAR',
      isDanger: true,
    );
    if (confirmed && context.mounted) {
      await ref
          .read(teamsNotifierProvider.notifier)
          .deleteTeam(teamId);
      showAppToast(context, 'Equipo eliminado');
    }
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int value;
  final bool highlight;
  final bool muted;

  const _StatPill({
    required this.label,
    required this.value,
    this.highlight = false,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: highlight
                ? AppTheme.primary
                : muted
                    ? AppTheme.textMuted
                    : AppTheme.text,
          ),
        ),
        Text(label,
            style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
      ],
    );
  }
}

class _TeamMenu extends StatelessWidget {
  final VoidCallback onDetail;
  final VoidCallback onStats;
  final VoidCallback onDelete;

  const _TeamMenu({
    required this.onDetail,
    required this.onStats,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'detail', child: Text('Ver detalle')),
        const PopupMenuItem(value: 'stats', child: Text('Ver estadísticas')),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Eliminar', style: TextStyle(color: Colors.red)),
        ),
      ],
      onSelected: (v) {
        if (v == 'detail') onDetail();
        if (v == 'stats') onStats();
        if (v == 'delete') onDelete();
      },
    );
  }
}
