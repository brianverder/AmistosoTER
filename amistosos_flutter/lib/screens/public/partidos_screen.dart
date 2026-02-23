import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../providers/requests_provider.dart';
import '../../widgets/app_widgets.dart';

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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'TERCER TIEMPO',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('INGRESAR'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Hero section
          Container(
            width: double.infinity,
            color: Colors.black,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingLg,
              vertical: AppConstants.spacingXl,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PARTIDOS DISPONIBLES',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Encuentra un equipo rival y confirma tu próximo amistoso',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Filter bar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingLg,
              vertical: AppConstants.spacingMd,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.black, width: 2),
              ),
            ),
            child: Wrap(
              spacing: AppConstants.spacingSm,
              runSpacing: AppConstants.spacingSm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _FilterDropdown(
                  hint: 'Modalidad',
                  value: _footballTypeFilter,
                  items: AppConstants.footballTypes,
                  onChanged: (v) {
                    setState(() => _footballTypeFilter = v);
                    _updateFilters();
                  },
                  icon: Icons.sports_soccer,
                ),
                _FilterDropdown(
                  hint: 'País',
                  value: _countryFilter,
                  items: AppConstants.countries,
                  onChanged: (v) {
                    setState(() => _countryFilter = v);
                    _updateFilters();
                  },
                  icon: Icons.location_on,
                ),
                if (_footballTypeFilter != null || _countryFilter != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _footballTypeFilter = null;
                        _countryFilter = null;
                      });
                      ref.read(publicRequestFiltersProvider.notifier).state =
                          const RequestFilters();
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('LIMPIAR'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          // Results
          Expanded(
            child: requestsAsync.when(
              loading: () => const AppLoadingScreen(),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Error al cargar',
                subtitle: e.toString(),
              ),
              data: (requests) {
                if (requests.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    title: 'Sin solicitudes disponibles',
                    subtitle: 'Intenta con otros filtros o vuelve más tarde',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppConstants.spacingLg),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppConstants.spacingSm),
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    return AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.spacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.shield, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    req.team?.name ?? 'Equipo',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                StatusBadge(status: req.status.name),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: AppConstants.spacingSm,
                              runSpacing: 4,
                              children: [
                                _InfoChip(
                                  icon: Icons.sports_soccer,
                                  label: 'F${req.footballType}',
                                ),
                                _InfoChip(
                                  icon: Icons.location_on,
                                  label: req.country ?? '',
                                ),
                                if (req.state != null)
                                  _InfoChip(
                                    icon: Icons.map,
                                    label: req.state!,
                                  ),
                                if (req.matchDate != null)
                                  _InfoChip(
                                    icon: Icons.calendar_today,
                                    label: DateFormat('dd/MM/yyyy')
                                        .format(req.matchDate!),
                                  ),
                              ],
                            ),
                            if (req.fieldAddress != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                req.fieldAddress!,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: AppConstants.spacingMd),
                            const Divider(height: 1),
                            const SizedBox(height: AppConstants.spacingMd),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => context.go(AppRoutes.login),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  side: const BorderSide(
                                      color: Colors.black, width: 2),
                                  shape: const RoundedRectangleBorder(),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                ),
                                child: const Text(
                                  'INGRESAR PARA ACEPTAR',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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
          color: value != null ? Colors.black : Colors.grey.shade400,
          width: value != null ? 2 : 1,
        ),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(hint,
                style:
                    const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
        underline: const SizedBox.shrink(),
        items: items
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: onChanged,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
