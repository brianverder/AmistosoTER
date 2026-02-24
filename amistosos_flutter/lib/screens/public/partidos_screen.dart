import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/match_request_model.dart';
import '../../providers/requests_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/skeleton.dart';

class PartidosScreen extends ConsumerStatefulWidget {
  const PartidosScreen({super.key});

  @override
  ConsumerState<PartidosScreen> createState() => _PartidosScreenState();
}

class _PartidosScreenState extends ConsumerState<PartidosScreen> {
  String? _footballTypeFilter;
  String? _countryFilter;

  void _updateFilters() {
    ref.read(publicRequestFiltersProvider.notifier).state = RequestFilters(
      footballType: _footballTypeFilter,
      country: _countryFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(publicRequestFiltersProvider);
    final requestsAsync = ref.watch(publicRequestsProvider(filters));
    final hasFilter = _footballTypeFilter != null || _countryFilter != null;

    return Scaffold(
      backgroundColor: AppTheme.surfaceVariant,
      body: Column(
        children: [
          const _TopBar(),
          _HeroSection(
            footballTypeFilter: _footballTypeFilter,
            countryFilter: _countryFilter,
            hasFilter: hasFilter,
            onFootballType: (v) { setState(() => _footballTypeFilter = v); _updateFilters(); },
            onCountry: (v) { setState(() => _countryFilter = v); _updateFilters(); },
            onClear: () {
              setState(() { _footballTypeFilter = null; _countryFilter = null; });
              ref.read(publicRequestFiltersProvider.notifier).state = const RequestFilters();
            },
          ),
          Expanded(
            child: requestsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(AppConstants.spacingLg),
                itemCount: 4,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: AppSkeletonCard(),
                ),
              ),
              error: (e, _) => Center(
                child: EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Error al cargar',
                  subtitle: e.toString(),
                ),
              ),
              data: (requests) {
                if (requests.isEmpty) {
                  return const Center(
                    child: EmptyState(
                      icon: Icons.sports_soccer_rounded,
                      title: 'Sin solicitudes disponibles',
                      subtitle: 'Prueba con otros filtros o vuelve más tarde',
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.spacingLg,
                    AppConstants.spacingMd,
                    AppConstants.spacingLg,
                    AppConstants.spacingXl,
                  ),
                  itemCount: requests.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RequestCard(request: requests[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingLg, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                'assets/images/ter.png',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.sports_soccer_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'TERCER TIEMPO',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              letterSpacing: 1.5,
              color: AppTheme.text,
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.login),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: const Icon(Icons.login_rounded, size: 16),
            label: const Text(
              'Ingresar',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero section ─────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final String? footballTypeFilter;
  final String? countryFilter;
  final bool hasFilter;
  final ValueChanged<String?> onFootballType;
  final ValueChanged<String?> onCountry;
  final VoidCallback onClear;

  const _HeroSection({
    required this.footballTypeFilter,
    required this.countryFilter,
    required this.hasFilter,
    required this.onFootballType,
    required this.onCountry,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0f172a), Color(0xFF1e293b)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingLg,
        AppConstants.spacingLg,
        AppConstants.spacingLg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "EN VIVO" badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text(
                  'EN VIVO',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Partidos\nDisponibles',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 28,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Encuentra tu próximo rival y confirma tu amistoso',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterPill(
                  hint: 'Modalidad',
                  value: footballTypeFilter,
                  items: AppConstants.footballTypes,
                  onChanged: onFootballType,
                  icon: Icons.sports_soccer_rounded,
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  hint: 'País',
                  value: countryFilter,
                  items: AppConstants.countries,
                  onChanged: onCountry,
                  icon: Icons.location_on_rounded,
                ),
                if (hasFilter) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onClear,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close_rounded, size: 14, color: Colors.white70),
                          SizedBox(width: 4),
                          Text(
                            'Limpiar',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Filter pill ──────────────────────────────────────────────────────────────

class _FilterPill extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData icon;

  const _FilterPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primary.withOpacity(0.15) : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive ? AppTheme.primary.withOpacity(0.6) : Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF1e293b),
          iconEnabledColor: isActive ? AppTheme.primary : Colors.white60,
          isDense: true,
          hint: Row(children: [
            Icon(icon, size: 13, color: isActive ? AppTheme.primary : Colors.white60),
            const SizedBox(width: 5),
            Text(
              hint,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? AppTheme.primary : Colors.white60,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
          items: items
              .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text(v, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ))
              .toList(),
          onChanged: onChanged,
          selectedItemBuilder: (ctx) => items
              .map((v) => Row(children: [
                    Icon(icon, size: 13, color: AppTheme.primary),
                    const SizedBox(width: 5),
                    Text(
                      v,
                      style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w700),
                    ),
                  ]))
              .toList(),
        ),
      ),
    );
  }
}

// ─── Request card ─────────────────────────────────────────────────────────────

class _RequestCard extends StatefulWidget {
  final MatchRequestModel request;
  const _RequestCard({required this.request});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final team = req.team;
    final hasStats = team != null && (team.totalGames ?? 0) > 0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? AppTheme.primary : AppTheme.border,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: avatar + team name + status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppAvatar(name: team?.name ?? '?', size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(
                                  team?.name ?? 'Equipo',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppTheme.text,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              StatusBadge(status: req.status.name),
                            ]),
                            if (req.footballType != null) ...[
                              const SizedBox(height: 3),
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
                    ],
                  ),

                  // Stats row
                  if (hasStats) ...[
                    const SizedBox(height: 12),
                    _StatsRow(team: team!),
                  ],

                  const SizedBox(height: 12),

                  // Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (req.country != null)
                        _InfoTag(icon: Icons.location_on_rounded, label: req.country!, color: AppTheme.info),
                      if (req.state != null)
                        _InfoTag(icon: Icons.map_outlined, label: req.state!),
                      if (req.matchDate != null)
                        _InfoTag(
                          icon: Icons.calendar_today_rounded,
                          label: DateFormat('dd/MM/yyyy').format(req.matchDate!),
                          color: AppTheme.primary,
                        ),
                      if (req.league != null)
                        _InfoTag(
                          icon: Icons.emoji_events_rounded,
                          label: req.league!,
                          color: const Color(0xFFD97706),
                        ),
                      if (req.fieldPrice != null)
                        _InfoTag(
                          icon: Icons.payments_outlined,
                          label: '\$${req.fieldPrice!.toStringAsFixed(0)} cancha',
                          color: const Color(0xFF059669),
                        ),
                    ],
                  ),

                  // Address
                  if (req.fieldAddress != null) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.place_outlined, size: 13, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          req.fieldAddress!,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  ],

                  // Description
                  if (req.description != null && req.description!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        req.description!,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSec, height: 1.5),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // CTA footer
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.go(AppRoutes.login),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_open_rounded,
                          size: 14,
                          color: _hovered ? AppTheme.primary : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Inicia sesión para aceptar este partido',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _hovered ? AppTheme.primary : AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
                          color: _hovered ? AppTheme.primary : AppTheme.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final TeamPreview team;
  const _StatsRow({required this.team});

  @override
  Widget build(BuildContext context) {
    final winPct = (team.totalGames ?? 0) > 0
        ? ((team.gamesWon ?? 0) / (team.totalGames ?? 1) * 100).toStringAsFixed(0)
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        _StatItem(label: 'PJ', value: '${team.totalGames ?? 0}', color: AppTheme.textSec),
        const _StatDivider(),
        _StatItem(label: 'G', value: '${team.gamesWon ?? 0}', color: AppTheme.success),
        const _StatDivider(),
        _StatItem(label: 'E', value: '${team.gamesDrawn ?? 0}', color: AppTheme.textMuted),
        const _StatDivider(),
        _StatItem(label: 'P', value: '${team.gamesLost ?? 0}', color: AppTheme.error),
        const Spacer(),
        if (winPct != null)
          Text(
            '$winPct% victorias',
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
          ),
      ]),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textMuted, letterSpacing: 0.5)),
    ]);
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

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

// ─── Info tag ─────────────────────────────────────────────────────────────────

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoTag({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
