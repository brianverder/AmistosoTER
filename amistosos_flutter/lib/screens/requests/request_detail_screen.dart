import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/match_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/requests_provider.dart';
import '../../providers/teams_provider.dart';
import '../../widgets/app_widgets.dart';

class RequestDetailScreen extends ConsumerWidget {
  final String requestId;
  const RequestDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reqAsync = ref.watch(requestDetailProvider(requestId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: reqAsync.when(
              loading: () => const AppLoadingScreen(),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Error',
                subtitle: e.toString(),
              ),
              data: (req) {
                if (req == null) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    title: 'Solicitud no encontrada',
                    subtitle: '',
                  );
                }

                final isOwner = currentUser?.id == req.userId;
                final canMatch = !isOwner &&
                    req.status == RequestStatus.active;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => context.go(AppRoutes.requests),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            req.team?.name ?? 'Solicitud',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        StatusBadge(status: req.status.name),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingLg),
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.spacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DETALLES DEL PARTIDO',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacingMd),
                            _DetailRow(
                              icon: Icons.shield,
                              label: 'EQUIPO',
                              value: req.team?.name ?? '—',
                            ),
                            _DetailRow(
                              icon: Icons.sports_soccer,
                              label: 'MODALIDAD',
                              value: 'Fútbol ${req.footballType}',
                            ),
                            _DetailRow(
                              icon: Icons.location_on,
                              label: 'PAÍS',
                              value: req.country ?? '—',
                            ),
                            if (req.state != null)
                              _DetailRow(
                                icon: Icons.map,
                                label: 'ZONA',
                                value: req.state!,
                              ),
                            if (req.fieldAddress != null)
                              _DetailRow(
                                icon: Icons.place,
                                label: 'DIRECCIÓN',
                                value: req.fieldAddress!,
                              ),
                            if (req.fieldPrice != null)
                              _DetailRow(
                                icon: Icons.attach_money,
                                label: 'PRECIO',
                                value: req.fieldPrice!.toStringAsFixed(0),
                              ),
                            if (req.matchDate != null)
                              _DetailRow(
                                icon: Icons.calendar_today,
                                label: 'FECHA',
                                value: DateFormat('dd/MM/yyyy')
                                    .format(req.matchDate!),
                              ),
                            if (req.league != null)
                              _DetailRow(
                                icon: Icons.emoji_events,
                                label: 'LIGA',
                                value: req.league!,
                              ),
                            if (req.description != null) ...[
                              const SizedBox(height: AppConstants.spacingSm),
                              const Text(
                                'DESCRIPCIÓN',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(req.description!),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (req.user != null) ...[
                      const SizedBox(height: AppConstants.spacingMd),
                      AppCard(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(AppConstants.spacingMd),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PUBLICADO POR',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                req.user!.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppConstants.spacingLg),
                    if (canMatch)
                      _MatchAction(requestId: req.id)
                    else if (isOwner && req.status == RequestStatus.active)
                      _DeleteAction(
                        onDelete: () => _deleteAndBack(context, ref, req.id),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAndBack(
      BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Eliminar solicitud',
      message: '¿Confirmar eliminación?',
      confirmLabel: 'ELIMINAR',
      isDanger: true,
    );
    if (confirmed && context.mounted) {
      final service = ref.read(requestsServiceProvider);
      await service.deleteRequest(id);
      ref.invalidate(requestsProvider);
      if (context.mounted) {
        showAppToast(context, 'Solicitud eliminada');
        context.go(AppRoutes.requests);
      }
    }
  }
}

class _MatchAction extends ConsumerStatefulWidget {
  final String requestId;
  const _MatchAction({required this.requestId});

  @override
  ConsumerState<_MatchAction> createState() => _MatchActionState();
}

class _MatchActionState extends ConsumerState<_MatchAction> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsNotifierProvider);
    final teams = teamsAsync.value ?? [];

    if (teams.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange, width: 2),
          color: Colors.orange.shade50,
        ),
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            const Expanded(
                child: Text('Necesitas un equipo para aceptar este partido')),
            TextButton(
              onPressed: () => context.go(AppRoutes.createTeam),
              child: const Text('CREAR EQUIPO'),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: AppButton(
        label: 'ACEPTAR PARTIDO',
        onPressed: _loading ? null : () => _pick(context, teams),
        isLoading: _loading,
      ),
    );
  }

  Future<void> _pick(BuildContext context, List teams) async {
    String? teamId;
    if (teams.length == 1) {
      teamId = teams[0].id;
    } else {
      teamId = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: const RoundedRectangleBorder(),
          title: const Text(
            'SELECCIONA TU EQUIPO',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: teams
                .map<Widget>(
                  (t) => ListTile(
                    title: Text(t.name),
                    onTap: () => Navigator.pop(ctx, t.id as String),
                  ),
                )
                .toList(),
          ),
        ),
      );
    }
    if (teamId == null) return;
    setState(() => _loading = true);
    try {
      final service = ref.read(requestsServiceProvider);
      await service.matchRequest(widget.requestId, teamId);
      ref.invalidate(requestsProvider);
      ref.invalidate(requestDetailProvider);
      if (mounted) showAppToast(context, '¡Partido confirmado!');
    } catch (e) {
      if (mounted) showAppToast(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _DeleteAction extends StatelessWidget {
  final VoidCallback onDelete;
  const _DeleteAction({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onDelete,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red, width: 2),
          shape: const RoundedRectangleBorder(),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: const Text('ELIMINAR SOLICITUD'),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
