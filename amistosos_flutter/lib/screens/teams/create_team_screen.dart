import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/teams_provider.dart';
import '../../widgets/app_widgets.dart';

class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _leagueCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _instagramCtrl.dispose();
    _leagueCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(teamsNotifierProvider.notifier).createTeam(
            name: _nameCtrl.text.trim(),
            instagram: _instagramCtrl.text.trim().isEmpty
                ? null
                : _instagramCtrl.text.trim(),
            league: _leagueCtrl.text.trim().isEmpty
                ? null
                : _leagueCtrl.text.trim(),
          );
      if (mounted) {
        showAppToast(context, 'Equipo creado exitosamente');
        context.go(AppRoutes.teams);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: AppTheme.shadowMd,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_rounded,
                              color: AppTheme.textSec),
                          onPressed: () => context.go(AppRoutes.teams),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Crear equipo',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            Text('Registra tu equipo de fútbol',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    if (_error != null) ...[
                      AppErrorBanner(message: _error!),
                      const SizedBox(height: 16),
                    ],

                    AppTextField(
                      label: 'Nombre del equipo',
                      controller: _nameCtrl,
                      hintText: 'Ej: Los Halcones FC',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'El nombre es requerido';
                        if (v.trim().length < 2) return 'Mínimo 2 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Instagram (opcional)',
                      controller: _instagramCtrl,
                      hintText: 'usuario (sin @)',
                      prefixIcon:
                          const Icon(Icons.alternate_email, size: 18),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Liga / Torneo (opcional)',
                      controller: _leagueCtrl,
                      hintText: 'Ej: Liga Regional, Torneo Apertura',
                      prefixIcon:
                          const Icon(Icons.emoji_events_outlined, size: 18),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                        ),
                        child: _loading
                            ? const AppSpinner(size: 18, color: AppTheme.surface)
                            : const Text('Crear equipo',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => context.go(AppRoutes.teams),
                        child: Text('Cancelar',
                            style: TextStyle(color: AppTheme.textMuted)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
