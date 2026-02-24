import 'package:flutter/material.dart';
import '../core/theme.dart';

/// ──────────────────────────────────────────────────────────────────────────
/// Tercer Tiempo — Component Library 2026
/// Inspirado en: Stripe · Linear · Vercel · Notion
/// ──────────────────────────────────────────────────────────────────────────

export 'skeleton.dart';

enum AppToastType { success, error, info, warning }

// ─────────────────────────────────────────────────────────────────────────────
// SPINNER
// ─────────────────────────────────────────────────────────────────────────────

class AppSpinner extends StatelessWidget {
  final double size;
  final Color? color;

  const AppSpinner({super.key, this.size = 22, this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          color: color ?? AppTheme.primary,
          strokeCap: StrokeCap.round,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// LOADING SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class AppLoadingScreen extends StatelessWidget {
  final String? message;

  const AppLoadingScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppSpinner(size: 28),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final String? emoji;
  final String title;
  final String? subtitle;
  final Widget? action;
  final IconData? icon;

  const EmptyState({
    super.key,
    this.emoji,
    required this.title,
    this.subtitle,
    this.action,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: icon != null
                    ? Icon(icon, size: 32, color: AppTheme.textMuted)
                    : Center(
                        child: Text(
                          emoji ?? '📭',
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.text,
                    ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMuted,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: 24),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CARD
// ─────────────────────────────────────────────────────────────────────────────

class StatCard extends StatefulWidget {
  final String? label;
  final String? title;
  final String value;
  final String emoji;
  final VoidCallback? onTap;
  final Color? accentColor;

  const StatCard({
    super.key,
    this.label,
    this.title,
    required this.value,
    this.emoji = '',
    this.onTap,
    this.accentColor,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _hovered = false;

  String get _label => widget.label ?? widget.title ?? '';

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor ?? AppTheme.primary;

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: _hovered ? AppTheme.borderStrong : AppTheme.border,
              width: 1,
            ),
            boxShadow: _hovered ? AppTheme.shadowMd : AppTheme.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withAlpha(18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(widget.emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  if (widget.onTap != null)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      transform: _hovered
                          ? Matrix4.translationValues(2, 0, 0)
                          : Matrix4.identity(),
                      child: Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textMuted),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.value,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.text,
                      height: 1,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                _label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BADGE
// ─────────────────────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: config.dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            config.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: config.textColor,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getConfig(String status) {
    return switch (status) {
      'active' => _StatusConfig(
          label: 'Activa',
          bgColor: AppTheme.primaryLight,
          textColor: AppTheme.primaryDark,
          dotColor: AppTheme.primary,
        ),
      'matched' => _StatusConfig(
          label: 'Match',
          bgColor: AppTheme.infoLight,
          textColor: AppTheme.info,
          dotColor: AppTheme.info,
        ),
      'completed' => _StatusConfig(
          label: 'Completada',
          bgColor: AppTheme.surfaceVariant,
          textColor: AppTheme.textSec,
          dotColor: AppTheme.textMuted,
        ),
      'cancelled' => _StatusConfig(
          label: 'Cancelada',
          bgColor: AppTheme.errorLight,
          textColor: AppTheme.error,
          dotColor: AppTheme.error,
        ),
      'confirmed' => _StatusConfig(
          label: 'Confirmado',
          bgColor: AppTheme.infoLight,
          textColor: AppTheme.info,
          dotColor: AppTheme.info,
        ),
      'pending' => _StatusConfig(
          label: 'Pendiente',
          bgColor: AppTheme.warningLight,
          textColor: AppTheme.accentDark,
          dotColor: AppTheme.warning,
        ),
      _ => _StatusConfig(
          label: status,
          bgColor: AppTheme.surfaceElevated,
          textColor: AppTheme.textSec,
          dotColor: AppTheme.textMuted,
        ),
    };
  }
}

class _StatusConfig {
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color dotColor;

  const _StatusConfig({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.dotColor,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CONFIRM DIALOG
// ─────────────────────────────────────────────────────────────────────────────

Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Confirmar',
  String? confirmLabel,
  String cancelText = 'Cancelar',
  bool isDangerous = false,
  bool isDanger = false,
}) async {
  final dangerous = isDangerous || isDanger;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      contentPadding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
      titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: dangerous ? AppTheme.errorLight : AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              dangerous ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
              color: dangerous ? AppTheme.error : AppTheme.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
        ],
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(message, style: Theme.of(ctx).textTheme.bodyMedium),
      ),
      actionsPadding: const EdgeInsets.all(20),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelText),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: dangerous ? AppTheme.error : AppTheme.primary,
            foregroundColor: AppTheme.surface,
          ),
          child: Text(confirmLabel ?? confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}

// ─────────────────────────────────────────────────────────────────────────────
// TOAST
// ─────────────────────────────────────────────────────────────────────────────

void showAppToast(
  BuildContext context,
  String message, {
  AppToastType type = AppToastType.success,
}) {
  final config = switch (type) {
    AppToastType.success => (
        accent: AppTheme.success,
        icon: Icons.check_circle_rounded,
      ),
    AppToastType.error => (
        accent: AppTheme.error,
        icon: Icons.error_rounded,
      ),
    AppToastType.warning => (
        accent: AppTheme.warning,
        icon: Icons.warning_rounded,
      ),
    AppToastType.info => (
        accent: AppTheme.info,
        icon: Icons.info_rounded,
      ),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C2E),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border(left: BorderSide(color: config.accent, width: 3)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(config.icon, color: config.accent, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.zero,
      ),
    );
}

// ─────────────────────────────────────────────────────────────────────────────
// TEXT FIELD
// ─────────────────────────────────────────────────────────────────────────────

class AppTextField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int maxLines;
  final bool enabled;
  final void Function(String)? onChanged;
  final String? initialValue;
  final String? helperText;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    this.label = '',
    this.controller,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
    this.initialValue,
    this.helperText,
    this.focusNode,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focus;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus = widget.focusNode ?? FocusNode();
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _focused ? AppTheme.primary : AppTheme.textSec,
                ),
          ),
          const SizedBox(height: 6),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            boxShadow: _focused
                ? [BoxShadow(color: AppTheme.primary.withAlpha(30), blurRadius: 0, spreadRadius: 3)]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            initialValue: widget.controller == null ? widget.initialValue : null,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            maxLines: widget.maxLines,
            enabled: widget.enabled,
            onChanged: widget.onChanged,
            focusNode: _focus,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.text,
                  fontWeight: FontWeight.w400,
                ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              suffixIcon: widget.suffixIcon,
              prefixIcon: widget.prefixIcon,
              helperText: widget.helperText,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUTTON
// Variantes: primary | outlined | ghost | danger
// ─────────────────────────────────────────────────────────────────────────────

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool isLoading;
  final bool outlined;
  final bool danger;
  final bool ghost;
  final double? width;
  final EdgeInsets? padding;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.isLoading = false,
    this.outlined = false,
    this.danger = false,
    this.ghost = false,
    this.width,
    this.padding,
    this.icon,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hovered = false;

  bool get _isLoading => widget.loading || widget.isLoading;
  bool get _disabled => _isLoading || widget.onPressed == null;

  Widget get _child {
    if (_isLoading) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          strokeCap: StrokeCap.round,
          color: (widget.outlined || widget.ghost) ? AppTheme.primary : AppTheme.surface,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 15),
          const SizedBox(width: 6),
        ],
        Text(widget.label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectivePadding =
        widget.padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 11);

    if (widget.ghost) {
      final btn = TextButton(
        onPressed: _disabled ? null : widget.onPressed,
        style: TextButton.styleFrom(
          foregroundColor: widget.danger ? AppTheme.error : AppTheme.primary,
          padding: effectivePadding,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        child: _child,
      );
      return widget.width != null ? SizedBox(width: widget.width, child: btn) : btn;
    }

    if (widget.outlined) {
      final btn = MouseRegion(
        cursor: _disabled ? MouseCursor.defer : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: OutlinedButton(
          onPressed: _disabled ? null : widget.onPressed,
          style: OutlinedButton.styleFrom(
            padding: effectivePadding,
            side: BorderSide(
              color: widget.danger
                  ? AppTheme.error
                  : (_hovered ? AppTheme.borderStrong : AppTheme.border),
              width: 1.5,
            ),
            foregroundColor: widget.danger ? AppTheme.error : AppTheme.text,
            backgroundColor: _hovered ? AppTheme.surfaceVariant : AppTheme.surface,
          ),
          child: _child,
        ),
      );
      return widget.width != null ? SizedBox(width: widget.width, child: btn) : btn;
    }

    final bgNormal  = widget.danger ? AppTheme.error : AppTheme.primary;
    final bgHovered = widget.danger ? const Color(0xFFDC2626) : AppTheme.primaryDark;
    final bgColor   = _disabled ? AppTheme.borderStrong : (_hovered ? bgHovered : bgNormal);

    final btn = MouseRegion(
      cursor: _disabled ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          boxShadow: (!_disabled && _hovered && !widget.danger) ? AppTheme.shadowPrimary : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _disabled ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            splashColor: Colors.white.withAlpha(20),
            highlightColor: Colors.white.withAlpha(10),
            child: Padding(
              padding: effectivePadding,
              child: DefaultTextStyle(
                style: TextStyle(
                  color: _disabled ? AppTheme.textMuted : AppTheme.surface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
                child: IconTheme(
                  data: IconThemeData(
                    color: _disabled ? AppTheme.textMuted : AppTheme.surface,
                    size: 15,
                  ),
                  child: _child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return widget.width != null ? SizedBox(width: widget.width, child: btn) : btn;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD
// ─────────────────────────────────────────────────────────────────────────────

class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
  final bool noPadding;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderColor,
    this.borderWidth = 1,
    this.boxShadow,
    this.noPadding = false,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hasInteraction = widget.onTap != null;

    return MouseRegion(
      cursor: hasInteraction ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: hasInteraction ? (_) => setState(() => _hovered = true) : null,
      onExit: hasInteraction ? (_) => setState(() => _hovered = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color: widget.borderColor ??
                (_hovered ? AppTheme.borderStrong : AppTheme.border),
            width: widget.borderWidth,
          ),
          boxShadow: widget.boxShadow ??
              (_hovered ? AppTheme.shadowMd : AppTheme.shadowSm),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasInteraction
            ? InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                splashColor: AppTheme.primary.withAlpha(6),
                highlightColor: AppTheme.surfaceVariant,
                child: _content(),
              )
            : _content(),
      ),
    );
  }

  Widget _content() {
    if (widget.noPadding) return widget.child;
    return Padding(
      padding: widget.padding ?? const EdgeInsets.all(20),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (action != null) action!,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textMuted),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INFO ROW
// ─────────────────────────────────────────────────────────────────────────────

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: iconColor ?? AppTheme.textMuted),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 1),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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

// ─────────────────────────────────────────────────────────────────────────────
// ERROR BANNER
// ─────────────────────────────────────────────────────────────────────────────

class AppErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const AppErrorBanner({super.key, required this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return _AppBanner(
      message: message,
      onDismiss: onDismiss,
      bgColor: AppTheme.errorLight,
      borderColor: AppTheme.error,
      iconColor: AppTheme.error,
      icon: Icons.error_outline_rounded,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CALLOUT  (info / success / warning / error)
// ─────────────────────────────────────────────────────────────────────────────

enum AppCalloutType { info, success, warning, error }

class AppCallout extends StatelessWidget {
  final String message;
  final String? title;
  final AppCalloutType type;

  const AppCallout({
    super.key,
    required this.message,
    this.title,
    this.type = AppCalloutType.info,
  });

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color border, Color ic, IconData ico) = switch (type) {
      AppCalloutType.success => (AppTheme.primaryLight,  AppTheme.primary,  AppTheme.primaryDark,  Icons.check_circle_rounded),
      AppCalloutType.warning => (AppTheme.warningLight,  AppTheme.warning,  AppTheme.accentDark,   Icons.warning_amber_rounded),
      AppCalloutType.error   => (AppTheme.errorLight,    AppTheme.error,    AppTheme.error,        Icons.error_outline_rounded),
      AppCalloutType.info    => (AppTheme.infoLight,     AppTheme.info,     AppTheme.info,         Icons.info_outline_rounded),
    };

    return _AppBanner(
      message: message,
      title: title,
      bgColor: bg,
      borderColor: border,
      iconColor: ic,
      icon: ico,
    );
  }
}

class _AppBanner extends StatelessWidget {
  final String message;
  final String? title;
  final VoidCallback? onDismiss;
  final Color bgColor;
  final Color borderColor;
  final Color iconColor;
  final IconData icon;

  const _AppBanner({
    required this.message,
    this.title,
    this.onDismiss,
    required this.bgColor,
    required this.borderColor,
    required this.iconColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: borderColor.withAlpha(60), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: iconColor,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, color: iconColor, size: 15),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAG / CHIP
// ─────────────────────────────────────────────────────────────────────────────

class AppTag extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? bgColor;
  final IconData? icon;

  const AppTag({
    super.key,
    required this.label,
    this.color,
    this.bgColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = color ?? AppTheme.textSec;
    final bg = bgColor ?? AppTheme.surfaceVariant;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: icon != null ? 8 : 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIVIDER WITH LABEL
// ─────────────────────────────────────────────────────────────────────────────

class AppDividerLabel extends StatelessWidget {
  final String label;
  const AppDividerLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AVATAR
// ─────────────────────────────────────────────────────────────────────────────

class AppAvatar extends StatelessWidget {
  final String? name;
  final String? imageUrl;
  final double size;
  final Color? bgColor;

  const AppAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.size = 40,
    this.bgColor,
  });

  String get _initials {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) return parts[0][0].toUpperCase() + parts[1][0].toUpperCase();
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    const palette = [
      Color(0xFF059669), Color(0xFF3B82F6),
      Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFF8B5CF6),
    ];
    final idx = (name?.codeUnitAt(0) ?? 0) % palette.length;
    final bg = bgColor ?? palette[idx].withAlpha(24);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.border, width: 1.5),
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
            color: palette[idx],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE HEADER
// ─────────────────────────────────────────────────────────────────────────────

class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: 16),
          action!,
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK ACTION CARD
// ─────────────────────────────────────────────────────────────────────────────

class QuickActionCard extends StatefulWidget {
  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.color ?? AppTheme.primary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: 180,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: _hovered ? accent.withAlpha(80) : AppTheme.border,
              width: 1,
            ),
            boxShadow: _hovered ? AppTheme.shadowMd : AppTheme.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _hovered ? accent.withAlpha(28) : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(widget.icon, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
