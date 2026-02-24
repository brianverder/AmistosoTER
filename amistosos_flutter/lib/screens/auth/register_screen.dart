import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';

/// Pantalla de registro — equivalente directo a app/register/page.tsx
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirm = false;
  String? _errorMessage;
  bool _success = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Las contraseñas no coinciden');
      return;
    }
    if (_passwordController.text.length < 6) {
      setState(() =>
          _errorMessage = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() => _errorMessage = null);

    await ref.read(authNotifierProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    ref.listen(authNotifierProvider, (_, next) {
      if (next is AuthError) {
        setState(() => _errorMessage = next.message);
      } else if (next is AuthAuthenticated) {
        setState(() => _success = true);
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) context.go('/dashboard');
        });
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryFaint,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 50,
                          height: 50,
                          errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer_rounded, color: AppTheme.primary, size: 36),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Crear cuenta',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Empieza a coordinar partidos',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Card ────────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: AppTheme.shadowMd,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Success banner ─────────────────────────────
                          if (_success) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.successLight,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      color: AppTheme.success, size: 18),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '¡Registro exitoso! Redirigiendo...',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ── Error banner ────────────────────────────────
                          if (_errorMessage != null && !_success) ...[
                            AppErrorBanner(message: _errorMessage!),
                            const SizedBox(height: 16),
                          ],

                          // ── Nombre ──────────────────────────────────────
                          AppTextField(
                            label: 'Nombre completo',
                            controller: _nameController,
                            hintText: 'Juan Pérez',
                            validator: (v) => v == null || v.isEmpty
                                ? 'Ingresa tu nombre'
                                : null,
                          ),
                          const SizedBox(height: 14),

                          // ── Email ────────────────────────────────────────
                          AppTextField(
                            label: 'Email',
                            controller: _emailController,
                            hintText: 'tu@email.com',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Ingresa tu email';
                              if (!v.contains('@')) return 'Email inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // ── Teléfono ─────────────────────────────────────
                          AppTextField(
                            label: 'Teléfono (opcional)',
                            controller: _phoneController,
                            hintText: '+598 99 123 456',
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),

                          // ── Contraseña ───────────────────────────────────
                          AppTextField(
                            label: 'Contraseña',
                            controller: _passwordController,
                            hintText: 'Mínimo 6 caracteres',
                            obscureText: !_showPassword,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Ingresa una contraseña';
                              if (v.length < 6) return 'Mínimo 6 caracteres';
                              return null;
                            },
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _showPassword = !_showPassword),
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 20,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // ── Confirmar ─────────────────────────────────────
                          AppTextField(
                            label: 'Confirmar contraseña',
                            controller: _confirmPasswordController,
                            hintText: 'Repite tu contraseña',
                            obscureText: !_showConfirm,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Confirma tu contraseña';
                              if (v != _passwordController.text)
                                return 'Las contraseñas no coinciden';
                              return null;
                            },
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _showConfirm = !_showConfirm),
                              icon: Icon(
                                _showConfirm
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 20,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── Submit ────────────────────────────────────────
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed:
                                  isLoading || _success ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSm),
                                ),
                              ),
                              child: isLoading
                                  ? const AppSpinner(
                                      size: 20, color: AppTheme.surface)
                                  : const Text(
                                      'Crear cuenta',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Login link ───────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Ya tienes cuenta? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
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
