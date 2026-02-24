import 'package:flutter/material.dart';
import '../core/theme.dart';

/// ──────────────────────────────────────────────────────────────────────────
/// Skeleton Loading System — Tercer Tiempo DS 2026
/// Animación shimmer nativa (sin paquetes externos).
/// ──────────────────────────────────────────────────────────────────────────

// ─── Shimmer Container ────────────────────────────────────────────────────────

class AppSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double? borderRadius;
  final bool circle;

  const AppSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
    this.circle = false,
  });

  // Constructores de conveniencia
  const AppSkeleton.line({super.key, this.width, this.height = 14, this.borderRadius = 6})
      : circle = false;

  const AppSkeleton.circle({super.key, required double size})
      : width = size,
        height = size,
        borderRadius = null,
        circle = true;

  const AppSkeleton.rect({super.key, this.width, this.height = 120, this.borderRadius = 12})
      : circle = false;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.circle
        ? BorderRadius.circular(9999)
        : BorderRadius.circular(widget.borderRadius ?? AppTheme.radiusSm);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Container(
        width: widget.circle ? widget.height : widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
            colors: const [
              Color(0xFFEEEEEE),
              Color(0xFFE0E0E0),
              Color(0xFFEEEEEE),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

// ─── Skeleton Composites ──────────────────────────────────────────────────────

/// Skeleton de una card genérica
class AppSkeletonCard extends StatelessWidget {
  final int lines;
  const AppSkeletonCard({super.key, this.lines = 3});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            AppSkeleton.circle(size: 40),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton.line(width: 140),
                const SizedBox(height: 6),
                AppSkeleton.line(width: 90, height: 12),
              ],
            )),
          ]),
          const SizedBox(height: 16),
          ...List.generate(lines, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppSkeleton.line(
              width: i == lines - 1 ? 160 : double.infinity,
              height: 12,
            ),
          )),
        ],
      ),
    );
  }
}

/// Skeleton de stat card
class AppSkeletonStatCard extends StatelessWidget {
  const AppSkeletonStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppSkeleton.rect(width: 40, height: 40, borderRadius: 10),
              AppSkeleton.line(width: 60, height: 12),
            ],
          ),
          const SizedBox(height: 16),
          AppSkeleton.line(width: 60, height: 28),
          const SizedBox(height: 6),
          AppSkeleton.line(width: 100, height: 12),
        ],
      ),
    );
  }
}

/// Skeleton de lista de items
class AppSkeletonList extends StatelessWidget {
  final int count;
  const AppSkeletonList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Row(children: [
              AppSkeleton.circle(size: 44),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeleton.line(width: double.infinity, height: 14),
                  const SizedBox(height: 6),
                  AppSkeleton.line(width: 160, height: 12),
                ],
              )),
              const SizedBox(width: 12),
              AppSkeleton.line(width: 60, height: 12),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Skeleton de grid
class AppSkeletonGrid extends StatelessWidget {
  final int count;
  final int crossAxisCount;
  const AppSkeletonGrid({super.key, this.count = 4, this.crossAxisCount = 2});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: List.generate(count, (_) => const AppSkeletonStatCard()),
    );
  }
}
