import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../providers/teams_provider.dart';
import '../../widgets/app_widgets.dart';

class TeamDetailScreen extends ConsumerStatefulWidget {
  final String teamId;
  const TeamDetailScreen({super.key, required this.teamId});

  @override
  ConsumerState<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends ConsumerState<TeamDetailScreen> {
  final _nameCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _editing = false;
  bool _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(teamDetailProvider(widget.teamId));

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: teamAsync.when(
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
                if (!_editing) {
                  _nameCtrl.text = team.name;
                  _instagramCtrl.text = team.instagram ?? '';
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => context.go(AppRoutes.teams),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            team.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => context.go(
                            AppRoutes.teamStats
                                .replaceFirst(':id', team.id),
                          ),
                          icon: const Icon(Icons.bar_chart, size: 18),
                          label: const Text('ESTADÍSTICAS'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingLg),
                    // Stats row
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'GANADOS',
                            value: team.gamesWon.toString(),
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingSm),
                        Expanded(
                          child: StatCard(
                            title: 'EMPATADOS',
                            value: team.gamesDrawn.toString(),
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingSm),
                        Expanded(
                          child: StatCard(
                            title: 'PERDIDOS',
                            value: team.gamesLost.toString(),
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingSm),
                        Expanded(
                          child: StatCard(
                            title: 'WIN RATE',
                            value: '${team.winRate.toStringAsFixed(1)}%',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingLg),
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.spacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'INFORMACIÓN DEL EQUIPO',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                if (!_editing)
                                  TextButton(
                                    onPressed: () =>
                                        setState(() => _editing = true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.black,
                                    ),
                                    child: const Text('EDITAR'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.spacingMd),
                            if (_editing)
                              _EditForm(
                                formKey: _formKey,
                                nameCtrl: _nameCtrl,
                                instagramCtrl: _instagramCtrl,
                                saving: _saving,
                                error: _error,
                                onSave: () => _saveTeam(team.id),
                                onCancel: () {
                                  setState(() {
                                    _editing = false;
                                    _error = null;
                                    _nameCtrl.text = team.name;
                                    _instagramCtrl.text =
                                        team.instagram ?? '';
                                  });
                                },
                              )
                            else ...[
                              _InfoRow(
                                label: 'NOMBRE',
                                value: team.name,
                              ),
                              if (team.instagram != null)
                                _InfoRow(
                                  label: 'INSTAGRAM',
                                  value: '@${team.instagram}',
                                ),
                              _InfoRow(
                                label: 'TOTAL PARTIDOS',
                                value: team.totalGames.toString(),
                              ),
                              _InfoRow(
                                label: 'PUNTOS',
                                value: team.points.toString(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingLg),
                    // Danger zone
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.spacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ZONA DE PELIGRO',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacingMd),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => _deleteTeam(
                                    context, team.id, team.name),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(
                                      color: Colors.red, width: 2),
                                  shape: const RoundedRectangleBorder(),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                                child: const Text('ELIMINAR EQUIPO'),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Future<void> _saveTeam(String teamId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(teamsNotifierProvider.notifier).updateTeam(
            id: teamId,
            name: _nameCtrl.text.trim(),
            instagram: _instagramCtrl.text.trim().isEmpty
                ? null
                : _instagramCtrl.text.trim(),
          );
      if (mounted) {
        setState(() => _editing = false);
        showAppToast(context, 'Equipo actualizado');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteTeam(
    BuildContext context,
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
      await ref.read(teamsNotifierProvider.notifier).deleteTeam(teamId);
      if (context.mounted) {
        showAppToast(context, 'Equipo eliminado');
        context.go(AppRoutes.teams);
      }
    }
  }
}

class _EditForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController instagramCtrl;
  final bool saving;
  final String? error;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _EditForm({
    required this.formKey,
    required this.nameCtrl,
    required this.instagramCtrl,
    required this.saving,
    required this.error,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (error != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 8),
          ],
          const Text(
            'NOMBRE *',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 6),
          AppTextField(
            controller: nameCtrl,
            hintText: 'Nombre del equipo',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          const Text(
            'INSTAGRAM',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 6),
          AppTextField(
            controller: instagramCtrl,
            hintText: 'usuario (sin @)',
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'GUARDAR',
                  onPressed: onSave,
                  isLoading: saving,
                ),
              ),
              const SizedBox(width: AppConstants.spacingSm),
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black, width: 2),
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('CANCELAR'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
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
