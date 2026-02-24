import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/match_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/requests_provider.dart';
import '../../providers/teams_provider.dart';
import '../../widgets/app_widgets.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _footballTypeFilter;
  String? _countryFilter;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _updateFilters() {
    ref.read(requestFiltersProvider.notifier).state = RequestFilters(
      footballType: _footballTypeFilter,
      country: _countryFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(requestFiltersProvider);
    final availableAsync = ref.watch(requestsProvider(
      RequestFilters(
        tab: 'available',
        footballType: filters.footballType,
        country: filters.country,
      ),
    ));
    final myAsync = ref.watch(requestsProvider(
      const RequestFilters(tab: 'my'),
    ));

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page header ──────────────────────────────────────────────────
          AppPageHeader(
            title: 'Solicitudes',
            subtitle: 'Encuentra y gestiona partidos amistosos',
            action: AppButton(
              label: 'Nueva solicitud',
              icon: Icons.add_rounded,
              onPressed: () => context.go(AppRoutes.createRequest),
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),

          // ── Filters ───────────────────────────────────────────────────────
          _FilterBar(
            footballType: _footballTypeFilter,
            country: _countryFilter,
            onFootballTypeChanged: (v) {
              setState(() => _footballTypeFilter = v);
              _updateFilters();
            },
            onCountryChanged: (v) {
              setState(() => _countryFilter = v);
              _updateFilters();
            },
            onClear: () {
              setState(() {
                _footballTypeFilter = null;
                _countryFilter = null;
              });
              ref.read(requestFiltersProvider.notifier).state =
                  const RequestFilters();
            },
          ),
          const SizedBox(height: AppConstants.spacingMd),

          // ── Tabs ──────────────────────────────────────────────────────────
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.border, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.1,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Disponibles'),
                Tab(text: 'Mis solicitudes'),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),

          // ── Content ───────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _RequestsList(asyncValue: availableAsync, mode: 'available'),
                _RequestsList(asyncValue: myAsync, mode: 'my'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final String? footballType;
  final String? country;
  final ValueChanged<String?> onFootballTypeChanged;
  final ValueChanged<String?> onCountryChanged;
  final VoidCallback onClear;

  const _FilterBar({
    required this.footballType,
    required this.country,
    required this.onFootballTypeChanged,
    required this.onCountryChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilters = footballType != null || country != null;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _FilterDropdown(
          hint: 'Modalidad',
          value: footballType,
          items: AppConstants.footballTypes,
          onChanged: onFootballTypeChanged,
          icon: Icons.sports_soccer_rounded,
        ),
        _FilterDropdown(
          hint: 'País',
          value: country,
          items: AppConstants.countries,
          onChanged: onCountryChanged,
          icon: Icons.location_on_rounded,
        ),
        if (hasFilters)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.errorLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(
                    color: AppTheme.error.withAlpha(40),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close_rounded, size: 13, color: AppTheme.error),
                    SizedBox(width: 4),
                    Text(
                      'Limpiar',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData icon;

  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value != null;
    return Container(
      height: 36,
      padding: const EdgeInsets.only(left: 12, right: 8),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryLight : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: isActive
              ? AppTheme.primaryDark.withAlpha(60)
              : AppTheme.border,
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: AppTheme.textMuted),
              const SizedBox(width: 5),
              Text(
                hint,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: isActive ? AppTheme.primaryDark : AppTheme.textMuted,
          ),
          items: items
              .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text(
                      v,
                      style: const TextStyle(fontSize: 13, color: AppTheme.text),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          style: const TextStyle(
            color: AppTheme.primaryDark,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Requests list ────────────────────────────────────────────────────────────

class _RequestsList extends ConsumerWidget {
  final AsyncValue<List<MatchRequestModel>> asyncValue;
  final String mode;

  const _RequestsList({
    required this.asyncValue,
    required this.mode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncValue.when(
      loading: () => const AppSkeletonList(count: 4),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'No se pudo cargar',
        subtitle: 'Inténtalo de nuevo en un momento',
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return EmptyState(
            icon: mode == 'available'
                ? Icons.search_off_rounded
                : Icons.assignment_outlined,
            title: mode == 'available'
                ? 'Sin solicitudes disponibles'
                : 'Aún no tienes solicitudes',
            subtitle: mode == 'my'
                ? 'Crea una solicitud para encontrar rivales cerca tuyo'
                : 'Probá ajustando los filtros de búsqueda',
            action: mode == 'my'
                ? AppButton(
                    label: 'Crear solicitud',
                    icon: Icons.add_rounded,
                    onPressed: () => context.go(AppRoutes.createRequest),
                  )
                : null,
          );
        }
        return ListView.separated(
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _RequestCard(
            request: requests[index],
            mode: mode,
          ),
        );
      },
    );
  }
}

// ─── Request card ─────────────────────────────────────────────────────────────

class _RequestCard extends ConsumerStatefulWidget {
  final MatchRequestModel request;
  final String mode;

  const _RequestCard({
    required this.request,
    required this.mode,
  });

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _hovered = false;

  Color get _accentColor => switch (widget.request.status.name) {
        'active'    => AppTheme.primary,
        'matched'   => AppTheme.info,
        'completed' => AppTheme.textMuted,
        'cancelled' => AppTheme.error,
        _           => AppTheme.borderStrong,
      };

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isOwner = currentUser?.id == widget.request.userId;
    final req = widget.request;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border(
            left: BorderSide(color: _accentColor, width: 3),
            right: BorderSide(
                color: _hovered ? AppTheme.borderStrong : AppTheme.border),
            top: BorderSide(
                color: _hovered ? AppTheme.borderStrong : AppTheme.border),
            bottom: BorderSide(
                color: _hovered ? AppTheme.borderStrong : AppTheme.border),
          ),
          boxShadow: _hovered ? AppTheme.shadowMd : AppTheme.shadowSm,
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go(
              AppRoutes.requestDetail.replaceFirst(':id', req.id),
            ),
            splashColor: AppTheme.primary.withAlpha(6),
            highlightColor: AppTheme.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ────────────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AppAvatar(name: req.team?.name ?? '?', size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              req.team?.name ?? 'Equipo sin nombre',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppTheme.text,
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (req.footballType != null) ...[
                              const SizedBox(height: 1),
                              Text(
                                'Fútbol ${req.footballType}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      StatusBadge(status: req.status.name),
                      if (isOwner) ...[
                        const SizedBox(width: 4),
                        _CardMenu(onDelete: () => _deleteRequest(context)),
                      ],
                    ],
                  ),

                  // ── Info chips ────────────────────────────────────────────
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (req.country != null && req.country!.isNotEmpty)
                        AppTag(
                          label: req.country!,
                          icon: Icons.location_on_rounded,
                        ),
                      if (req.state != null && req.state!.isNotEmpty)
                        AppTag(
                          label: req.state!,
                          icon: Icons.map_outlined,
                        ),
                      if (req.matchDate != null)
                        AppTag(
                          label:
                              DateFormat('dd/MM/yyyy').format(req.matchDate!),
                          icon: Icons.calendar_today_rounded,
                          color: AppTheme.info,
                          bgColor: AppTheme.infoLight,
                        ),
                      if (req.league != null && req.league!.isNotEmpty)
                        AppTag(
                          label: req.league!,
                          icon: Icons.emoji_events_rounded,
                          color: AppTheme.accentDark,
                          bgColor: AppTheme.accentLight,
                        ),
                    ],
                  ),

                  // ── Address ───────────────────────────────────────────────
                  if (req.fieldAddress != null &&
                      req.fieldAddress!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            req.fieldAddress!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // ── Match action ──────────────────────────────────────────
                  if (widget.mode == 'available' &&
                      req.status == RequestStatus.active) ...[
                    const SizedBox(height: 16),
                    Divider(height: 1, color: AppTheme.border),
                    const SizedBox(height: 14),
                    _MatchButton(requestId: req.id),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteRequest(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Eliminar solicitud',
      message: '¿Eliminar esta solicitud? Esta acción no se puede deshacer.',
      confirmLabel: 'ELIMINAR',
      isDanger: true,
    );
    if (confirmed && context.mounted) {
      final service = ref.read(requestsServiceProvider);
      await service.deleteRequest(widget.request.id);
      ref.invalidate(requestsProvider);
      if (context.mounted) showAppToast(context, 'Solicitud eliminada');
    }
  }
}

// ─── Match button ─────────────────────────────────────────────────────────────

class _MatchButton extends ConsumerStatefulWidget {
  final String requestId;
  const _MatchButton({required this.requestId});

  @override
  ConsumerState<_MatchButton> createState() => _MatchButtonState();
}

class _MatchButtonState extends ConsumerState<_MatchButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsNotifierProvider);
    final teams = teamsAsync.value ?? [];

    if (teams.isEmpty) {
      return AppCallout(
        type: AppCalloutType.warning,
        message: 'Necesitas tener un equipo para aceptar este partido.',
      );
    }

    return SizedBox(
      width: double.infinity,
      child: AppButton(
        label: 'Aceptar partido',
        icon: Icons.handshake_outlined,
        onPressed: _loading ? null : () => _showTeamPicker(context, teams),
        isLoading: _loading,
      ),
    );
  }

  Future<void> _showTeamPicker(BuildContext context, List teams) async {
    if (teams.length == 1) {
      await _doMatch(teams[0].id);
      return;
    }
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        title: const Text(
          'Selecciona tu equipo',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: teams
              .map<Widget>(
                (team) => ListTile(
                  leading: AppAvatar(name: team.name as String, size: 36),
                  title: Text(
                    team.name as String,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  onTap: () => Navigator.pop(ctx, team.id),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (picked != null) await _doMatch(picked);
  }

  Future<void> _doMatch(String teamId) async {
    setState(() => _loading = true);
    try {
      final service = ref.read(requestsServiceProvider);
      await service.matchRequest(widget.requestId, teamId);
      ref.invalidate(requestsProvider);
      if (mounted) showAppToast(context, '¡Partido confirmado! 🎉');
    } catch (e) {
      if (mounted) {
        showAppToast(context, 'Error: $e', type: AppToastType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── Card menu ────────────────────────────────────────────────────────────────

class _CardMenu extends StatelessWidget {
  final VoidCallback onDelete;
  const _CardMenu({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppTheme.textMuted),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      offset: const Offset(0, 32),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.error),
              SizedBox(width: 8),
              Text(
                'Eliminar',
                style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
      onSelected: (v) {
        if (v == 'delete') onDelete();
      },
    );
  }
}
