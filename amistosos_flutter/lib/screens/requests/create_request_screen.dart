import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/requests_provider.dart';
import '../../providers/teams_provider.dart';
import '../../widgets/app_widgets.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() =>
      _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fieldNameCtrl = TextEditingController();
  final _fieldAddressCtrl = TextEditingController();
  final _fieldPriceCtrl = TextEditingController();
  final _leagueCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();

  String? _teamId;
  String? _footballType;
  String? _country;
  DateTime? _matchDate;

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _fieldNameCtrl.dispose();
    _fieldAddressCtrl.dispose();
    _fieldPriceCtrl.dispose();
    _leagueCtrl.dispose();
    _descCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_teamId == null) {
      setState(() => _error = 'Selecciona un equipo');
      return;
    }
    if (_footballType == null) {
      setState(() => _error = 'Selecciona la modalidad');
      return;
    }
    if (_country == null) {
      setState(() => _error = 'Selecciona el país');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = ref.read(requestsServiceProvider);
      await service.createRequest(
        teamId: _teamId!,
        footballType: _footballType!,
        country: _country!,
        state: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
        fieldName: _fieldNameCtrl.text.trim().isEmpty
            ? null
            : _fieldNameCtrl.text.trim(),
        fieldAddress: _fieldAddressCtrl.text.trim().isEmpty
            ? null
            : _fieldAddressCtrl.text.trim(),
        fieldPrice: _fieldPriceCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_fieldPriceCtrl.text.trim()),
        matchDate: _matchDate,
        league: _leagueCtrl.text.trim().isEmpty
            ? null
            : _leagueCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
      );
      ref.invalidate(requestsProvider);
      if (mounted) {
        showAppToast(context, 'Solicitud creada exitosamente');
        context.go('${AppRoutes.requests}?tab=1');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _matchDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          dialogBackgroundColor: Colors.white,
          colorScheme: ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _matchDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsNotifierProvider);
    final teams = teamsAsync.value ?? [];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => context.go(AppRoutes.requests),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: SectionHeader(title: 'NUEVA SOLICITUD'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spacingLg),
                  if (_error != null) ...[
                    _ErrorBanner(message: _error!),
                    const SizedBox(height: AppConstants.spacingMd),
                  ],
                  // Team selector
                  _FieldLabel('EQUIPO *'),
                  if (teams.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange, width: 2),
                        color: Colors.orange.shade50,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Necesitas un equipo para crear una solicitud'),
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.createTeam),
                            child: const Text('CREAR'),
                          ),
                        ],
                      ),
                    )
                  else
                    _DropdownField<String>(
                      value: _teamId,
                      hint: 'Selecciona tu equipo',
                      items: teams
                          .map(
                            (t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(t.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _teamId = v),
                    ),
                  const SizedBox(height: AppConstants.spacingMd),
                  _FieldLabel('MODALIDAD *'),
                  _DropdownField<String>(
                    value: _footballType,
                    hint: 'Ej: Fútbol 5',
                    items: AppConstants.footballTypes
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(AppConstants.footballTypeLabel(v)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _footballType = v),
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  _FieldLabel('PAÍS *'),
                  _DropdownField<String>(
                    value: _country,
                    hint: 'Selecciona el país',
                    items: AppConstants.countries
                        .map(
                          (v) => DropdownMenuItem(value: v, child: Text(v)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _country = v),
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  _FieldLabel('DEPARTAMENTO / ESTADO'),
                  AppTextField(
                    controller: _stateCtrl,
                    hintText: 'Ej: Montevideo',
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  _FieldLabel('NOMBRE DE LA CANCHA'),
                  AppTextField(
                    controller: _fieldNameCtrl,
                    hintText: 'Ej: Complejo Olimpia',
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  _FieldLabel('DIRECCIÓN DE LA CANCHA'),
                  AppTextField(
                    controller: _fieldAddressCtrl,
                    hintText: 'Ej: Av. 18 de Julio 1234',
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  _FieldLabel('PRECIO DE LA CANCHA'),
                  AppTextField(
                    controller: _fieldPriceCtrl,
                    hintText: 'Ej: \$1200 (pesos)',
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  _FieldLabel('POSIBLE FECHA DEL PARTIDO'),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _matchDate != null
                              ? AppTheme.primary
                              : AppTheme.border,
                          width: _matchDate != null ? 1.5 : 1,
                        ),
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _matchDate != null
                                ? DateFormat('dd/MM/yyyy').format(_matchDate!)
                                : 'Seleccionar fecha',
                            style: TextStyle(
                              color: _matchDate != null
                                  ? AppTheme.text
                                  : AppTheme.textMuted,
                            ),
                          ),
                          const Spacer(),
                          if (_matchDate != null)
                            GestureDetector(
                              onTap: () => setState(() => _matchDate = null),
                              child: const Icon(Icons.clear,
                                  size: 16, color: AppTheme.textMuted),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  _FieldLabel('LIGA / TORNEO'),
                  AppTextField(
                    controller: _leagueCtrl,
                    hintText: 'Ej: Liga Casual 2025',
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  _FieldLabel('DESCRIPCIÓN'),
                  AppTextField(
                    controller: _descCtrl,
                    hintText: 'Información adicional...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppConstants.spacingXl),
                  AppButton(
                    label: 'PUBLICAR SOLICITUD',
                    onPressed: _submit,
                    isLoading: _loading,
                    width: double.infinity,
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => context.go(AppRoutes.requests),
                      child: const Text(
                        'CANCELAR',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: value != null ? AppTheme.text : AppTheme.textMuted,
          width: value != null ? 2 : 1,
        ),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(color: AppTheme.textMuted),
          ),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorLight,
        border: Border.all(color: AppTheme.error),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_rounded, color: AppTheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
