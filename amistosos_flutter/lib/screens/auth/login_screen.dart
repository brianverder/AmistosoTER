import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? returnUrl;

  const LoginScreen({super.key, this.returnUrl});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);

    await ref.read(authNotifierProvider.notifier).signIn(
          _emailController.text.trim(),
          _passwordController.text,
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
        final target = widget.returnUrl ?? '/dashboard';
        context.go(target);
      }
    });

    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: isWide ? _WideLayout(
        formContent: _FormContent(
          formKey: _formKey,
          emailController: _emailController,
          passwordController: _passwordController,
          showPassword: _showPassword,
          errorMessage: _errorMessage,
          isLoading: isLoading,
          onTogglePassword: () => setState(() => _showPassword = !_showPassword),
          onSubmit: _handleSubmit,
          onGoRegister: () => context.go('/register'),
        ),
      ) : _NarrowLayout(
        formContent: _FormContent(
          formKey: _formKey,
          emailController: _emailController,
          passwordController: _passwordController,
          showPassword: _showPassword,
          errorMessage: _errorMessage,
          isLoading: isLoading,
          onTogglePassword: () => setState(() => _showPassword = !_showPassword),
          onSubmit: _handleSubmit,
          onGoRegister: () => context.go('/register'),
        ),
      ),
    );
  }
}

// ─── Wide layout (split panel) ────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  final Widget formContent;
  const _WideLayout({required this.formContent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: Branding panel
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF14532D), // green-900
                  Color(0xFF166534), // green-800
                  Color(0xFF15803D), // green-700
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: const Text('⚽', style: TextStyle(fontSize: 28)),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tercer Tiempo',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Coordina tus partidos',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Hero text
                    Text(
                      'Encuentra\ntu rival\nperfecto.',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sports_soccer, color: Colors.white.withOpacity(0.8), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Fútbol 5 • 7 • 8 • 11 • Futsal',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Stats
                    _StatsRow(),

                    const SizedBox(height: 32),
                    Text(
                      '© 2025 Tercer Tiempo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Right: Form panel
        SizedBox(
          width: 480,
          child: formContent,
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBubble(number: '500+', label: 'Equipos'),
        const SizedBox(width: 20),
        _StatBubble(number: '3', label: 'Países'),
        const SizedBox(width: 20),
        _StatBubble(number: '∞', label: 'Partidos'),
      ],
    );
  }
}

class _StatBubble extends StatelessWidget {
  final String number;
  final String label;
  const _StatBubble({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.6),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─── Narrow layout (mobile) ───────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  final Widget formContent;
  const _NarrowLayout({required this.formContent});

  @override
  Widget build(BuildContext context) {
    return formContent;
  }
}

// ─── Form content ─────────────────────────────────────────────────────────────

class _FormContent extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool showPassword;
  final String? errorMessage;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onGoRegister;

  const _FormContent({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.showPassword,
    required this.errorMessage,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onGoRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mobile logo
                    Builder(builder: (ctx) {
                      final isNarrow = MediaQuery.sizeOf(ctx).width < 900;
                      if (!isNarrow) return const SizedBox.shrink();
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryFaint,
                              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                            ),
                            child: const Text('⚽', style: TextStyle(fontSize: 36)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tercer Tiempo',
                            style: Theme.of(ctx).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      );
                    }),

                    // Header
                    Text(
                      'Bienvenido 👋',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Inicia sesión para coordinar tu próximo partido',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),

                    // Error banner
                    if (errorMessage != null) ...[
                      AppErrorBanner(message: errorMessage!),
                      const SizedBox(height: 20),
                    ],

                    // Email
                    AppTextField(
                      label: 'Email',
                      controller: emailController,
                      hintText: 'tu@email.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa tu email';
                        if (!v.contains('@')) return 'Email inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    AppTextField(
                      label: 'Contraseña',
                      controller: passwordController,
                      hintText: '••••••••',
                      obscureText: !showPassword,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                        return null;
                      },
                      suffixIcon: IconButton(
                        onPressed: onTogglePassword,
                        icon: Icon(
                          showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 20,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Submit
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : onSubmit,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                        ),
                        child: isLoading
                            ? const AppSpinner(size: 20, color: AppTheme.surface)
                            : const Text(
                                'Iniciar sesión',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿No tienes cuenta? ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: onGoRegister,
                          child: Text(
                            'Registrarse',
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
      ),
    );
  }
}

