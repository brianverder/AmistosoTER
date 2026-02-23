import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
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
                        const SectionHeader(title: 'DETALLE DEL PARTIDO'),
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
