import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

/// Dashboard layout — responsive sidebar (≥768px) or bottom nav (mobile)
class DashboardLayout extends ConsumerWidget {
  final Widget child;

  const DashboardLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 768;
    final currentPath = GoRouterState.of(context).matchedLocation;

    if (isWide) {
      return Scaffold(
        backgroundColor: AppTheme.bg,
        body: Row(
          children: [
            _SideNav(currentPath: currentPath, user: user, ref: ref),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: _MobileAppBar(user: user, ref: ref),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
      bottomNavigationBar: _BottomNav(currentPath: currentPath),
    );
  }
}

// ─── Sidebar (desktop) ────────────────────────────────────────────────────────

class _SideNav extends StatelessWidget {
  final String currentPath;
  final dynamic user;
  final WidgetRef ref;

  const _SideNav({required this.currentPath, required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryFaint,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Image.asset(
                    'assets/images/ter.png',
                    width: 24,
                    height: 24,
                    errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer_rounded, color: AppTheme.primary, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Tercer Tiempo',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.text,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 8),

          // Nav
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              children: [
                _NavItem(icon: Icons.grid_view_rounded, label: 'Dashboard', path: '/dashboard', currentPath: currentPath),
                _NavItem(icon: Icons.groups_rounded, label: 'Mis Equipos', path: '/dashboard/teams', currentPath: currentPath),
                _NavItem(icon: Icons.assignment_rounded, label: 'Solicitudes', path: '/dashboard/requests', currentPath: currentPath),
                _NavItem(icon: Icons.handshake_rounded, label: 'Mis Partidos', path: '/dashboard/matches', currentPath: currentPath),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Divider(height: 1, color: AppTheme.border),
                ),
                const SizedBox(height: 8),
                _NavItem(icon: Icons.public_rounded, label: 'Vista Pública', path: '/partidos', currentPath: currentPath, muted: true),
              ],
            ),
          ),

          // User footer
          Divider(height: 1, color: AppTheme.border),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    (user?.name?.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(user?.name ?? 'Usuario',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.text),
                          overflow: TextOverflow.ellipsis),
                      Text(user?.email ?? '',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).signOut();
                    if (context.mounted) context.go('/login');
                  },
                  icon: Icon(Icons.logout_rounded, size: 18, color: AppTheme.textMuted),
                  tooltip: 'Cerrar sesión',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final String currentPath;
  final bool muted;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.currentPath,
    this.muted = false,
  });

  bool get isActive =>
      currentPath == path || (path != '/dashboard' && currentPath.startsWith(path));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isActive ? AppTheme.primaryFaint : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: InkWell(
          onTap: () => context.go(path),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          splashColor: AppTheme.primaryFaint,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: isActive
                ? BoxDecoration(
                    border: Border(left: BorderSide(color: AppTheme.primary, width: 3)),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  )
                : null,
            child: Row(
              children: [
                Icon(icon, size: 18,
                    color: isActive ? AppTheme.primary : muted ? AppTheme.textMuted : AppTheme.textSec),
                const SizedBox(width: 12),
                Text(label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? AppTheme.primary : muted ? AppTheme.textMuted : AppTheme.text,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Mobile AppBar ────────────────────────────────────────────────────────────

class _MobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final dynamic user;
  final WidgetRef ref;

  const _MobileAppBar({required this.user, required this.ref});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryFaint,
              borderRadius: BorderRadius.circular(AppTheme.radiusXs),
            ),
            child: Image.asset(
              'assets/images/ter.png',
              width: 22,
              height: 22,
              errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer_rounded, color: AppTheme.primary, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Text('Tercer Tiempo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.text)),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          offset: const Offset(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primary,
              child: Text(
                (user?.name?.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
          onSelected: (value) async {
            if (value == 'logout') {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              enabled: false,
              child: Text(user?.name ?? 'Usuario', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(children: [
                Icon(Icons.logout_rounded, size: 18),
                SizedBox(width: 8),
                Text('Cerrar sesión'),
              ]),
            ),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: AppTheme.border),
      ),
    );
  }
}

// ─── Bottom Nav (mobile) ──────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final String currentPath;
  const _BottomNav({required this.currentPath});

  int get _selectedIndex {
    if (currentPath.startsWith('/dashboard/teams')) return 1;
    if (currentPath.startsWith('/dashboard/requests')) return 2;
    if (currentPath.startsWith('/dashboard/matches')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: NavigationBar(
        selectedIndex: _selectedIndex,
        backgroundColor: AppTheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppTheme.primaryFaint,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) {
          const paths = ['/dashboard', '/dashboard/teams', '/dashboard/requests', '/dashboard/matches'];
          context.go(paths[i]);
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined, color: AppTheme.textMuted),
            selectedIcon: Icon(Icons.grid_view_rounded, color: AppTheme.primary),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined, color: AppTheme.textMuted),
            selectedIcon: Icon(Icons.groups_rounded, color: AppTheme.primary),
            label: 'Equipos',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined, color: AppTheme.textMuted),
            selectedIcon: Icon(Icons.assignment_rounded, color: AppTheme.primary),
            label: 'Solicitudes',
          ),
          NavigationDestination(
            icon: Icon(Icons.handshake_outlined, color: AppTheme.textMuted),
            selectedIcon: Icon(Icons.handshake_rounded, color: AppTheme.primary),
            label: 'Partidos',
          ),
        ],
      ),
    );
  }
}

