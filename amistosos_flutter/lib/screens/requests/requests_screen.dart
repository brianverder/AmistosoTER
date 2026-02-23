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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SectionHeader(
                    title: 'SOLICITUDES',
                    subtitle: 'Encuentra y gestiona partidos amistosos',
                  ),
                ),
                AppButton(
                  label: '+ NUEVA',
                  onPressed: () => context.go(AppRoutes.createRequest),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            // Filters
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
            // Tabs
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.border, width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Disponibles'),
                  Tab(text: 'Mis solicitudes'),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _RequestsList(
                    asyncValue: availableAsync,
                    mode: 'available',
                  ),
                  _RequestsList(
                    asyncValue: myAsync,
                    mode: 'my',
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}

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
      spacing: AppConstants.spacingSm,
      runSpacing: AppConstants.spacingSm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _FilterDropdown(
          hint: 'Modalidad',
          value: footballType,
          items: AppConstants.footballTypes,
          onChanged: onFootballTypeChanged,
          icon: Icons.sports_soccer,
        ),
        _FilterDropdown(
          hint: 'País',
          value: country,
          items: AppConstants.countries,
          onChanged: onCountryChanged,
          icon: Icons.location_on,
        ),
        if (hasFilters)
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('LIMPIAR'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textMuted,
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
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: value != null ? AppTheme.text : AppTheme.textMuted,
          width: value != null ? 2 : 1,
        ),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.textMuted),
            const SizedBox(width: 4),
            Text(hint, style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          ],
        ),
        underline: const SizedBox.shrink(),
        items: items
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: onChanged,
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

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
      loading: () => const AppLoadingScreen(),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Error al cargar',
        subtitle: e.toString(),
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return EmptyState(
            icon: Icons.search_off,
            title: mode == 'available'
                ? 'No hay solicitudes disponibles'
                : 'No has creado solicitudes',
            subtitle: mode == 'my'
                ? 'Crea una solicitud para encontrar rivales'
                : 'Intenta con otros filtros',
            action: mode == 'my'
                ? AppButton(
                    label: '+ CREAR SOLICITUD',
                    onPressed: () => context.go(AppRoutes.createRequest),
                  )
                : null,
          );
        }
        return ListView.separated(
          itemCount: requests.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppConstants.spacingSm),
          itemBuilder: (context, index) {
            final req = requests[index];
            return _RequestCard(
              request: req,
              mode: mode,
            );
          },
        );
      },
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final MatchRequestModel request;
  final String mode;

  const _RequestCard({
    required this.request,
    required this.mode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isOwner = currentUser?.id == request.userId;

    return AppCard(
      child: InkWell(
        onTap: () => context.go(
          AppRoutes.requestDetail.replaceFirst(':id', request.id),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.team?.name ?? 'Equipo',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  StatusBadge(status: request.status.name),
                  if (isOwner)
                    _CardMenu(
                      onDelete: () => _deleteRequest(context, ref),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: AppConstants.spacingSm,
                runSpacing: 4,
                children: [
                  _InfoChip(
                    icon: Icons.sports_soccer,
                    label: 'F${request.footballType}',
                  ),
                  _InfoChip(
                    icon: Icons.location_on,
                    label: request.country ?? '',
                  ),
                  if (request.state != null)
                    _InfoChip(
                      icon: Icons.map,
                      label: request.state!,
                    ),
                  if (request.matchDate != null)
                    _InfoChip(
                      icon: Icons.calendar_today,
                      label: DateFormat('dd/MM/yyyy')
                          .format(request.matchDate!),
                    ),
                ],
              ),
              if (request.fieldAddress != null) ...[
                const SizedBox(height: 6),
                Text(
                  request.fieldAddress!,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
              if (mode == 'available' && request.status == RequestStatus.active)
                ...[
                const SizedBox(height: AppConstants.spacingMd),
                const Divider(height: 1),
                const SizedBox(height: AppConstants.spacingMd),
                _MatchButton(requestId: request.id),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteRequest(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Eliminar solicitud',
      message: '¿Eliminar esta solicitud? Esta acción no se puede deshacer.',
      confirmLabel: 'ELIMINAR',
      isDanger: true,
    );
    if (confirmed && context.mounted) {
      final service = ref.read(requestsServiceProvider);
      await service.deleteRequest(request.id);
      ref.invalidate(requestsProvider);
      if (context.mounted) showAppToast(context, 'Solicitud eliminada');
    }
  }
}

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

    return Row(
      children: [
        if (teams.isNotEmpty) ...[
          Expanded(
            child: AppButton(
              label: _loading ? '...' : 'ACEPTAR PARTIDO',
              onPressed: _loading
                  ? null
                  : () => _showTeamPicker(context, teams),
              isLoading: _loading,
            ),
          ),
        ] else
          Text(
            'Necesitas un equipo para aceptar',
            style: TextStyle(
              color: AppTheme.textSec,
              fontSize: 12,
            ),
          ),
      ],
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
        shape: const RoundedRectangleBorder(),
        title: const Text(
          'SELECCIONA TU EQUIPO',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: teams
              .map<Widget>(
                (team) => ListTile(
                  title: Text(team.name),
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
      if (mounted) showAppToast(context, '¡Partido confirmado!');
    } catch (e) {
      if (mounted) showAppToast(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppTheme.textSec),
          ),
        ],
      ),
    );
  }
}

class _CardMenu extends StatelessWidget {
  final VoidCallback onDelete;
  const _CardMenu({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18),
      shape: const RoundedRectangleBorder(),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'delete',
          child: Text('Eliminar', style: TextStyle(color: AppTheme.error)),
        ),
      ],
      onSelected: (v) {
        if (v == 'delete') onDelete();
      },
    );
  }
}
