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
  final int initialTab;
  const RequestsScreen({super.key, this.initialTab = 0});

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
    _tabCtrl = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
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

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isOwner = currentUser?.id == widget.request.userId;
    final req = widget.request;
    final team = req.team;
    final hasStats = team != null && (team.totalGames ?? 0) > 0;
    final winPct = hasStats
        ? ((team!.gamesWon ?? 0) / (team.totalGames ?? 1) * 100)
            .toStringAsFixed(0)
        : null;

    // Build detail rows
    final detailRows = <_InfoRowData>[];
    if (req.footballType != null) {
      detailRows.add(_InfoRowData(
        icon: Icons.sports_soccer_rounded,
        label: 'Modalidad',
        value: 'Fútbol ${req.footballType}',
      ));
    }
    if (req.country != null || req.state != null) {
      final loc = [req.country, req.state]
          .where((e) => e != null && e.isNotEmpty)
          .join(', ');
      if (loc.isNotEmpty) {
        detailRows.add(_InfoRowData(
          icon: Icons.location_on_rounded,
          label: 'Ubicación',
          value: loc,
        ));
      }
    }
    if (req.matchDate != null) {
      final dayName = DateFormat('EEEE', 'es').format(req.matchDate!);
      final formatted = DateFormat('dd/MM/yyyy').format(req.matchDate!);
      final daysUntil = req.matchDate!.difference(DateTime.now()).inDays;
      String timeHint = '';
      if (daysUntil == 0) {
        timeHint = ' · Hoy';
      } else if (daysUntil == 1) {
        timeHint = ' · Mañana';
      } else if (daysUntil > 1 && daysUntil <= 7) {
        timeHint = ' · En $daysUntil días';
      }
      detailRows.add(_InfoRowData(
        icon: Icons.calendar_today_rounded,
        label: 'Fecha del partido',
        value:
            '${dayName[0].toUpperCase()}${dayName.substring(1)} $formatted$timeHint',
        valueColor: AppTheme.info,
      ));
    }
    if (req.league != null && req.league!.isNotEmpty) {
      detailRows.add(_InfoRowData(
        icon: Icons.emoji_events_rounded,
        label: 'Liga / Torneo',
        value: req.league!,
        valueColor: AppTheme.accentDark,
      ));
    }
    if (req.fieldPrice != null) {
      detailRows.add(_InfoRowData(
        icon: Icons.monetization_on_rounded,
        label: 'Precio de cancha',
        value: '\$${req.fieldPrice!.toStringAsFixed(0)}',
        valueColor: AppTheme.primary,
      ));
    }
    if (req.fieldAddress != null && req.fieldAddress!.isNotEmpty) {
      detailRows.add(_InfoRowData(
        icon: Icons.stadium_rounded,
        label: 'Dirección',
        value: req.fieldAddress!,
      ));
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? AppTheme.primary : AppTheme.border,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? AppTheme.primary.withOpacity(0.10)
                  : Colors.black.withOpacity(0.04),
              blurRadius: _hovered ? 20 : 8,
              offset: Offset(0, _hovered ? 6 : 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => context.go(
            AppRoutes.requestDetail.replaceFirst(':id', req.id),
          ),
          borderRadius: BorderRadius.circular(16),
          splashColor: AppTheme.primary.withAlpha(8),
          highlightColor: AppTheme.surfaceVariant.withOpacity(0.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Section ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryFaint, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: AppAvatar(
                          name: team?.name ?? '?', size: 44),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team?.name ?? 'Equipo sin nombre',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppTheme.text,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (req.footballType != null) ...[
                                Icon(Icons.sports_soccer_rounded,
                                    size: 12, color: AppTheme.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  'Fútbol ${req.footballType}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              if (req.footballType != null &&
                                  req.league != null) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6),
                                  child: Text('·',
                                      style: TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 12)),
                                ),
                              ],
                              if (req.league != null &&
                                  req.league!.isNotEmpty) ...[
                                Icon(Icons.emoji_events_rounded,
                                    size: 12, color: AppTheme.accentDark),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    req.league!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.accentDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: req.status.name),
                    if (isOwner) ...[
                      const SizedBox(width: 2),
                      _CardMenu(onDelete: () => _deleteRequest(context)),
                    ],
                  ],
                ),
              ),

              // ── Stats bar (only if team has stats) ─────────────────────
              if (hasStats) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.border.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        _MiniStat(
                            label: 'PJ',
                            value: '${team!.totalGames ?? 0}',
                            color: AppTheme.textSec),
                        _StatDot(),
                        _MiniStat(
                            label: 'PG',
                            value: '${team.gamesWon ?? 0}',
                            color: AppTheme.success),
                        _StatDot(),
                        _MiniStat(
                            label: 'PE',
                            value: '${team.gamesDrawn ?? 0}',
                            color: AppTheme.warning),
                        _StatDot(),
                        _MiniStat(
                            label: 'PP',
                            value: '${team.gamesLost ?? 0}',
                            color: AppTheme.error),
                        const Spacer(),
                        if (winPct != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                AppTheme.primary,
                                AppTheme.primaryDark,
                              ]),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$winPct% victorias',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],

              // ── Detail rows ────────────────────────────────────────────
              if (detailRows.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 13, color: AppTheme.textMuted),
                      const SizedBox(width: 5),
                      const Text(
                        'DETALLES DEL PARTIDO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.border.withOpacity(0.4)),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < detailRows.length; i++) ...[
                          _buildInfoRow(detailRows[i]),
                          if (i < detailRows.length - 1)
                            Divider(
                              height: 1,
                              color: AppTheme.border.withOpacity(0.4),
                              indent: 40,
                              endIndent: 12,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              // ── Description ────────────────────────────────────────────
              if (req.description != null &&
                  req.description!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.accent.withOpacity(0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💬',
                            style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mensaje del equipo',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accentDark,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                req.description!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSec,
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // ── Footer action ──────────────────────────────────────────
              if (widget.mode == 'available' &&
                  req.status == RequestStatus.active) ...[
                Container(
                  decoration: BoxDecoration(
                    border:
                        Border(top: BorderSide(color: AppTheme.border)),
                    color: _hovered
                        ? AppTheme.primary.withOpacity(0.03)
                        : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                  child: _MatchButton(requestId: req.id),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(_InfoRowData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(data.icon, size: 16, color: data.valueColor ?? AppTheme.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: Text(
              data.label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              data.value,
              style: TextStyle(
                fontSize: 13,
                color: data.valueColor ?? AppTheme.text,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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

// ─── Data classes & mini widgets ──────────────────────────────────────────────

class _InfoRowData {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRowData({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color)),
        const SizedBox(height: 1),
        Text(label,
            style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
                letterSpacing: 0.3)),
      ],
    );
  }
}

class _StatDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: AppTheme.border,
    );
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
      if (mounted) {
        showAppToast(context, '¡Partido confirmado! 🎉');
        context.go(AppRoutes.matches);
      }
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
