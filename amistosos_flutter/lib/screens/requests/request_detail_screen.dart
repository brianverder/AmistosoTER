import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/match_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/matches_provider.dart';
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
              loading: () => const _DetailSkeleton(),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Error al cargar',
                subtitle: e.toString(),
              ),
              data: (req) {
                if (req == null) {
                  return const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Solicitud no encontrada',
                    subtitle: 'Es posible que haya sido eliminada',
                  );
                }

                final isOwner = currentUser?.id == req.userId;
                final canMatch =
                    !isOwner && req.status == RequestStatus.active;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Breadcrumb / back nav ──────────────────────────────
                    _BackNav(teamName: req.team?.name ?? 'Solicitud'),
                    const SizedBox(height: AppConstants.spacingLg),

                    // ── Status hero card ───────────────────────────────────
                    _HeroCard(request: req),
                    const SizedBox(height: 16),

                    // ── Details card ───────────────────────────────────────
                    _DetailsCard(request: req),

                    // ── Author card ────────────────────────────────────────
                    if (req.user != null) ...[
                      const SizedBox(height: 12),
                      _AuthorCard(user: req.user!),
                    ],

                    const SizedBox(height: AppConstants.spacingLg),

                    // ── Action ────────────────────────────────────────────
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
      message: '¿Confirmar eliminación? Esta acción no se puede deshacer.',
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

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSkeletonCard(),
        SizedBox(height: 12),
        AppSkeletonCard(),
        SizedBox(height: 12),
        AppSkeletonList(count: 5),
      ],
    );
  }
}

// ─── Back navigation ──────────────────────────────────────────────────────────

class _BackNav extends StatelessWidget {
  final String teamName;
  const _BackNav({required this.teamName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => context.go(AppRoutes.requests),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 16,
              color: AppTheme.textSec,
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => context.go(AppRoutes.requests),
          child: const Text(
            'Solicitudes',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.chevron_right_rounded,
              size: 14, color: AppTheme.textMuted),
        ),
        Expanded(
          child: Text(
            teamName,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.text,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Hero card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final MatchRequestModel request;
  const _HeroCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppAvatar(name: request.team?.name ?? '?', size: 52),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.team?.name ?? 'Equipo sin nombre',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.text,
                    letterSpacing: -0.3,
                  ),
                ),
                if (request.footballType != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Fútbol ${request.footballType}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          StatusBadge(status: request.status.name),
        ],
      ),
    );
  }
}

// ─── Details card ─────────────────────────────────────────────────────────────

class _DetailsCard extends StatelessWidget {
  final MatchRequestModel request;
  const _DetailsCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DETALLES DEL PARTIDO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),

          // Location section
          if (request.country != null)
            InfoRow(
              icon: Icons.location_on_rounded,
              label: 'PAÍS',
              value: request.country!,
              iconColor: AppTheme.info,
            ),
          if (request.state != null)
            InfoRow(
              icon: Icons.map_outlined,
              label: 'ZONA',
              value: request.state!,
            ),
          if (request.fieldAddress != null)
            InfoRow(
              icon: Icons.place_outlined,
              label: 'DIRECCIÓN',
              value: request.fieldAddress!,
            ),

          // Match info
          if (request.matchDate != null) ...[
            const SizedBox(height: 4),
            InfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'FECHA',
              value: DateFormat('EEEE d \'de\' MMMM yyyy').format(request.matchDate!),
              iconColor: AppTheme.info,
            ),
          ],
          if (request.fieldPrice != null)
            InfoRow(
              icon: Icons.payments_outlined,
              label: 'PRECIO CANCHA',
              value: '\$${request.fieldPrice!.toStringAsFixed(0)}',
              iconColor: AppTheme.success,
            ),
          if (request.league != null)
            InfoRow(
              icon: Icons.emoji_events_rounded,
              label: 'LIGA',
              value: request.league!,
              iconColor: AppTheme.accentDark,
            ),

          // Description
          if (request.description != null &&
              request.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DESCRIPCIÓN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    request.description!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSec,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Author card ──────────────────────────────────────────────────────────────

class _AuthorCard extends StatelessWidget {
  final dynamic user;
  const _AuthorCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          AppAvatar(name: user.name as String, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PUBLICADO POR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.name as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Match action ─────────────────────────────────────────────────────────────

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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppCallout(
            type: AppCalloutType.warning,
            message: 'Necesitas crear un equipo para poder aceptar este partido.',
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Crear mi equipo',
            icon: Icons.add_rounded,
            outlined: true,
            onPressed: () => context.go(AppRoutes.createTeam),
          ),
        ],
      );
    }

    return AppButton(
      label: 'Aceptar partido',
      icon: Icons.handshake_outlined,
      onPressed: _loading ? null : () => _pick(context, teams),
      isLoading: _loading,
      width: double.infinity,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          ),
          title: const Text(
            'Selecciona tu equipo',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          content: IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: teams
                  .map<Widget>(
                    (t) => ListTile(
                      leading: AppAvatar(name: t.name as String, size: 36),
                      title: Text(
                        t.name as String,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      onTap: () => Navigator.pop(ctx, t.id as String),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      );
    }
    if (teamId == null) return;
    setState(() => _loading = true);
    try {
      final service = ref.read(requestsServiceProvider);
      final matchData = await service.matchRequest(widget.requestId, teamId);
      ref.invalidate(requestsProvider);
      ref.invalidate(requestDetailProvider);
      ref.invalidate(matchesNotifierProvider);
      if (mounted) {
        await _showContactModal(context, matchData);
        if (mounted) context.go(AppRoutes.matches);
      }
    } catch (e) {
      if (mounted) {
        showAppToast(context, 'Error: $e', type: AppToastType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showContactModal(
      BuildContext context, Map<String, dynamic> matchData) async {
    final user1 = matchData['user1'] as Map<String, dynamic>?;
    final team1 = matchData['team1'] as Map<String, dynamic>?;

    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => _ContactInfoModal(
          rivalName: user1?['name'] as String? ?? 'Rival',
          rivalPhone: user1?['phone'] as String?,
          rivalTeamName: team1?['name'] as String? ?? 'Equipo rival',
          rivalInstagram: team1?['instagram'] as String?,
        ),
      );
    }
  }
}

// ─── Delete action ────────────────────────────────────────────────────────────

class _DeleteAction extends StatelessWidget {
  final VoidCallback onDelete;
  const _DeleteAction({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Eliminar esta solicitud',
      icon: Icons.delete_outline_rounded,
      onPressed: onDelete,
      outlined: true,
      danger: true,
      width: double.infinity,
    );
  }
}

// ─── Contact info modal ───────────────────────────────────────────────────────

class _ContactInfoModal extends StatelessWidget {
  final String rivalName;
  final String? rivalPhone;
  final String rivalTeamName;
  final String? rivalInstagram;

  const _ContactInfoModal({
    required this.rivalName,
    this.rivalPhone,
    required this.rivalTeamName,
    this.rivalInstagram,
  });

  void _copy(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    showAppToast(context, '$label copiado');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusXl),
                  topRight: Radius.circular(AppTheme.radiusXl),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.handshake_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '¡MATCH CONFIRMADO!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aquí están los datos de tu rival',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // ── Contact info ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Team card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                      children: [
                        AppAvatar(name: rivalTeamName, size: 48),
                        const SizedBox(width: 14),
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
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                rivalTeamName,
                                style: const TextStyle(
                                  fontSize: 16,
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

                  const SizedBox(height: 12),

                  // Contact rows
                  _ContactRow(
                    icon: Icons.person_rounded,
                    label: 'CONTACTO',
                    value: rivalName,
                    iconColor: AppTheme.info,
                    onCopy: () => _copy(context, rivalName, 'Nombre'),
                  ),

                  if (rivalPhone != null) ...[
                    const SizedBox(height: 8),
                    _ContactRow(
                      icon: Icons.phone_rounded,
                      label: 'TELÉFONO',
                      value: rivalPhone!,
                      iconColor: AppTheme.success,
                      onCopy: () => _copy(context, rivalPhone!, 'Teléfono'),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    _ContactRow(
                      icon: Icons.phone_rounded,
                      label: 'TELÉFONO',
                      value: 'No registrado',
                      iconColor: AppTheme.textMuted,
                      muted: true,
                    ),
                  ],

                  if (rivalInstagram != null) ...[
                    const SizedBox(height: 8),
                    _ContactRow(
                      icon: Icons.camera_alt_rounded,
                      label: 'INSTAGRAM',
                      value: rivalInstagram!.startsWith('@')
                          ? rivalInstagram!
                          : '@${rivalInstagram!}',
                      iconColor: const Color(0xFFE1306C),
                      onCopy: () => _copy(
                        context,
                        rivalInstagram!.startsWith('@')
                            ? rivalInstagram!
                            : '@${rivalInstagram!}',
                        'Instagram',
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    _ContactRow(
                      icon: Icons.camera_alt_rounded,
                      label: 'INSTAGRAM',
                      value: 'No registrado',
                      iconColor: AppTheme.textMuted,
                      muted: true,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Close button
                  AppButton(
                    label: '¡Excelente, a jugar!',
                    icon: Icons.sports_soccer_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final VoidCallback? onCopy;
  final bool muted;

  const _ContactRow({
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: muted
                  ? AppTheme.surfaceVariant
                  : iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              icon,
              size: 17,
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
              icon: const Icon(Icons.copy_rounded, size: 17),
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
