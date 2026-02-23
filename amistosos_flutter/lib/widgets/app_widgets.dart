import 'package:flutter/material.dart';
import '../core/theme.dart';

enum AppToastType { success, error, info, warning }

// ─── Spinner ──────────────────────────────────────────────────────────────────

class AppSpinner extends StatelessWidget {
  final double size;
  final Color? color;

  const AppSpinner({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: color ?? AppTheme.primary,
        strokeCap: StrokeCap.round,
      ),
    );
  }
}

// ─── Loading Screen ───────────────────────────────────────────────────────────

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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryFaint,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: const AppSpinner(size: 32),
          ),
          if (message != null) ...[
            const SizedBox(height: 20),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

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
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: icon != null
                  ? Icon(icon, size: 40, color: AppTheme.textMuted)
                  : Text(
                      emoji ?? '📭',
                      style: const TextStyle(fontSize: 40),
                    ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 28),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
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

  String get _label => label ?? title ?? '';

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.border, width: 1),
            boxShadow: AppTheme.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                  if (onTap != null)
                    Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                value,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.text,
                      height: 1,
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

// ─── Status Badge ─────────────────────────────────────────────────────────────

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
            decoration: BoxDecoration(
              color: config.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            config.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: config.textColor,
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

// ─── Confirm Dialog ───────────────────────────────────────────────────────────

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
      contentPadding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
      titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: dangerous ? AppTheme.errorLight : AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              dangerous ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
              color: dangerous ? AppTheme.error : AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
        ],
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(
          message,
          style: Theme.of(ctx).textTheme.bodyMedium,
        ),
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
          ),
          child: Text(confirmLabel ?? confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}

// ─── Toast ────────────────────────────────────────────────────────────────────

void showAppToast(
  BuildContext context,
  String message, {
  AppToastType type = AppToastType.success,
}) {
  final config = switch (type) {
    AppToastType.success => (
        bg: AppTheme.primary,
        icon: Icons.check_circle_rounded,
        text: AppTheme.surface,
      ),
    AppToastType.error => (
        bg: AppTheme.error,
        icon: Icons.error_rounded,
        text: AppTheme.surface,
      ),
    AppToastType.warning => (
        bg: AppTheme.warning,
        icon: Icons.warning_rounded,
        text: AppTheme.surface,
      ),
    AppToastType.info => (
        bg: AppTheme.info,
        icon: Icons.info_rounded,
        text: AppTheme.surface,
      ),
  };

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(config.icon, color: config.text, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: config.text,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: config.bg,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      margin: const EdgeInsets.all(16),
    ),
  );
}

// ─── Text Field ───────────────────────────────────────────────────────────────

class AppTextField extends StatelessWidget {
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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSec,
                ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          enabled: enabled,
          onChanged: onChanged,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w400,
              ),
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
          ),
        ),
      ],
    );
  }
}

// ─── Button ───────────────────────────────────────────────────────────────────

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool isLoading;
  final bool outlined;
  final bool danger;
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
    this.width,
    this.padding,
    this.icon,
  });

  bool get _isLoading => loading || isLoading;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ??
        const EdgeInsets.symmetric(horizontal: 20, vertical: 13);

    final buttonChild = _isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: outlined ? AppTheme.primary : AppTheme.surface,
              strokeCap: StrokeCap.round,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16),
                const SizedBox(width: 6),
              ],
              Text(label),
            ],
          );

    Widget button;
    if (outlined) {
      button = OutlinedButton(
        onPressed: _isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: effectivePadding,
          side: BorderSide(
            color: danger ? AppTheme.error : AppTheme.border,
            width: 1.5,
          ),
          foregroundColor: danger ? AppTheme.error : AppTheme.text,
        ),
        child: buttonChild,
      );
    } else {
      button = ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: effectivePadding,
          backgroundColor: danger ? AppTheme.error : AppTheme.primary,
          foregroundColor: AppTheme.surface,
        ),
        child: buttonChild,
      );
    }

    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    return button;
  }
}

// ─── App Card ─────────────────────────────────────────────────────────────────

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderColor,
    this.borderWidth = 1,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: borderColor ?? AppTheme.border,
          width: borderWidth,
        ),
        boxShadow: boxShadow ?? AppTheme.shadowSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: Padding(
                padding: padding ?? const EdgeInsets.all(20),
                child: child,
              ),
            )
          : Padding(
              padding: padding ?? const EdgeInsets.all(20),
              child: child,
            ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

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
              ),
            ),
            if (action != null) action!,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor ?? AppTheme.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSec,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(color: AppTheme.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error Banner ─────────────────────────────────────────────────────────────

class AppErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const AppErrorBanner({super.key, required this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.errorLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.error.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, color: AppTheme.error, size: 16),
            ),
        ],
      ),
    );
  }
}
