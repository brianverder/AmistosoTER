import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/match_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/matches_provider.dart';
import '../../widgets/app_widgets.dart';

class MatchDetailScreen extends ConsumerStatefulWidget {
  final String matchId;
  const MatchDetailScreen({super.key, required this.matchId});

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _score1Ctrl = TextEditingController();
  final _score2Ctrl = TextEditingController();
  bool _submitting = false;
  String? _error;
  bool _showResultForm = false;

  @override
  void dispose() {
    _score1Ctrl.dispose();
    _score2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submitResult(String matchId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(matchesNotifierProvider.notifier).submitResult(
            matchId,
            team1Score: int.parse(_score1Ctrl.text),
            team2Score: int.parse(_score2Ctrl.text),
          );
      if (mounted) {
        setState(() => _showResultForm = false);
        showAppToast(context, 'Resultado registrado');
        ref.invalidate(matchDetailProvider(matchId));
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(matchDetailProvider(widget.matchId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: matchAsync.when(
              loading: () => const AppLoadingScreen(),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Error',
                subtitle: e.toString(),
              ),
              data: (match) {
                if (match == null) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    title: 'Partido no encontrado',
                    subtitle: '',
                  );
                }

                final hasResult = match.matchResult != null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => context.go(AppRoutes.matches),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: SectionHeader(title: 'DETALLE DEL PARTIDO'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingLg),
                    // Scoreboard
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.spacingLg),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      const Icon(Icons.shield, size: 32),
                                      const SizedBox(height: 8),
                                      Text(
                                        match.team1?.name ?? 'Equipo 1',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: hasResult
                                      ? Column(
                                          children: [
                                            Text(
                                              '${match.matchResult!.team1Score} - ${match.matchResult!.team2Score}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 36,
                                              ),
                                            ),
                                            const Text(
                                              'RESULTADO FINAL',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          children: [
                                            const Text(
                                              'VS',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 28,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            StatusBadge(
                                                status: match.status.name),
                                          ],
                                        ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      const Icon(Icons.shield, size: 32),
                                      const SizedBox(height: 8),
                                      Text(
                                        match.team2?.name ?? 'Equipo 2',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (match.matchRequest?.matchDate != null) ...[
                              const SizedBox(height: AppConstants.spacingMd),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('dd/MM/yyyy')
                                        .format(match.matchRequest!.matchDate!),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    // Match info
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.spacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'INFORMACIÓN',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: AppConstants.spacingMd),
                            if (match.matchRequest?.footballType != null)
                              _InfoRow(
                                icon: Icons.sports_soccer,
                                label: 'MODALIDAD',
                                value: 'Fútbol ${match.matchRequest!.footballType}',
                              ),
                            if (match.matchRequest?.fieldAddress != null)
                              _InfoRow(
                                icon: Icons.place,
                                label: 'CANCHA',
                                value: match.matchRequest!.fieldAddress!,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    // Contact info of the rival
                    _RivalContactCard(
                      match: match,
                      currentUserId: currentUser?.id ?? '',
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    // Result section
                    if (!hasResult) ...[
                      if (!_showResultForm)
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            label: 'REGISTRAR RESULTADO',
                            onPressed: () =>
                                setState(() => _showResultForm = true),
                          ),
                        )
                      else
                        AppCard(
                          child: Padding(
                            padding:
                                const EdgeInsets.all(AppConstants.spacingMd),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'REGISTRAR RESULTADO',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(
                                      height: AppConstants.spacingMd),
                                  if (_error != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      color: Colors.red.shade50,
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                            color: Colors.red),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              match.team1?.name ??
                                                  'Equipo 1',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            AppTextField(
                                              controller: _score1Ctrl,
                                              hintText: '0',
                                              keyboardType:
                                                  TextInputType.number,
                                              validator: (v) {
                                                if (v == null ||
                                                    v.isEmpty) {
                                                  return 'Requerido';
                                                }
                                                if (int.tryParse(v) ==
                                                    null) {
                                                  return 'Número';
                                                }
                                                return null;
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Text(
                                          '-',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 24,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              match.team2?.name ??
                                                  'Equipo 2',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            AppTextField(
                                              controller: _score2Ctrl,
                                              hintText: '0',
                                              keyboardType:
                                                  TextInputType.number,
                                              validator: (v) {
                                                if (v == null ||
                                                    v.isEmpty) {
                                                  return 'Requerido';
                                                }
                                                if (int.tryParse(v) ==
                                                    null) {
                                                  return 'Número';
                                                }
                                                return null;
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                      height: AppConstants.spacingMd),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppButton(
                                          label: 'GUARDAR',
                                          onPressed: () => _submitResult(
                                              match.id),
                                          isLoading: _submitting,
                                        ),
                                      ),
                                      const SizedBox(
                                          width: AppConstants.spacingSm),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => setState(
                                              () => _showResultForm =
                                                  false),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.black,
                                            side: const BorderSide(
                                                color: Colors.black,
                                                width: 2),
                                            shape:
                                                const RoundedRectangleBorder(),
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    vertical: 14),
                                          ),
                                          child: const Text('CANCELAR'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ] else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(
                              color: Colors.green, width: 2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green),
                            const SizedBox(width: 8),
                            const Text(
                              'Resultado registrado',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
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
            width: 110,
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

// ─── Rival contact card ───────────────────────────────────────────────────────

class _RivalContactCard extends StatelessWidget {
  final MatchModel match;
  final String currentUserId;

  const _RivalContactCard({
    required this.match,
    required this.currentUserId,
  });

  void _copy(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    showAppToast(context, '$label copiado');
  }

  @override
  Widget build(BuildContext context) {
    // Determine rival based on current user
    final isUser1 = currentUserId == match.userId1;
    final UserSnapshot? rivalUser = isUser1 ? match.user2 : match.user1;
    final TeamSnapshot? rivalTeam = isUser1 ? match.team2 : match.team1;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DATOS DE CONTACTO DEL RIVAL',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
                color: AppTheme.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 14),

            // Team row
            if (rivalTeam != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(
                  children: [
                    AppAvatar(name: rivalTeam.name, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EQUIPO RIVAL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMuted,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rivalTeam.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Contact rows
            if (rivalUser != null) ...[
              _ContactDetailRow(
                icon: Icons.person_rounded,
                label: 'NOMBRE',
                value: rivalUser.name,
                iconColor: AppTheme.info,
                onCopy: () => _copy(context, rivalUser.name, 'Nombre'),
              ),
              const SizedBox(height: 8),
              if (rivalUser.email != null) ...[
                _ContactDetailRow(
                  icon: Icons.email_rounded,
                  label: 'EMAIL',
                  value: rivalUser.email!,
                  iconColor: AppTheme.info,
                  onCopy: () => _copy(context, rivalUser.email!, 'Email'),
                ),
              ] else
                _ContactDetailRow(
                  icon: Icons.email_rounded,
                  label: 'EMAIL',
                  value: 'No registrado',
                  iconColor: AppTheme.textMuted,
                  muted: true,
                ),
              const SizedBox(height: 8),
              if (rivalUser.phone != null) ...[
                _ContactDetailRow(
                  icon: Icons.phone_rounded,
                  label: 'TELÉFONO',
                  value: rivalUser.phone!,
                  iconColor: AppTheme.success,
                  onCopy: () => _copy(context, rivalUser.phone!, 'Teléfono'),
                ),
              ] else
                _ContactDetailRow(
                  icon: Icons.phone_rounded,
                  label: 'TELÉFONO',
                  value: 'No registrado',
                  iconColor: AppTheme.textMuted,
                  muted: true,
                ),
              if (rivalTeam?.instagram != null) ...[
                const SizedBox(height: 8),
                _ContactDetailRow(
                  icon: Icons.camera_alt_rounded,
                  label: 'INSTAGRAM',
                  value: rivalTeam!.instagram!.startsWith('@')
                      ? rivalTeam.instagram!
                      : '@${rivalTeam.instagram!}',
                  iconColor: const Color(0xFFE1306C),
                  onCopy: () => _copy(
                    context,
                    rivalTeam.instagram!.startsWith('@')
                        ? rivalTeam.instagram!
                        : '@${rivalTeam.instagram!}',
                    'Instagram',
                  ),
                ),
              ],
            ] else ...[
              const Center(
                child: Text(
                  'Información de contacto no disponible',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final VoidCallback? onCopy;
  final bool muted;

  const _ContactDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.onCopy,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: muted
                  ? AppTheme.surfaceVariant
                  : iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              icon,
              size: 16,
              color: muted ? AppTheme.textMuted : iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: muted ? AppTheme.textMuted : AppTheme.text,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded, size: 16),
              color: AppTheme.textMuted,
              tooltip: 'Copiar',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }
}
