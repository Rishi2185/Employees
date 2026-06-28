import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../state/auth_provider.dart';
import '../state/connectivity_provider.dart';
import 'appointments_screen.dart';
import 'archive_screen.dart';
import 'dashboard_screen.dart';
import 'doctors_screen.dart';
import 'eod_screen.dart';
import 'settings_screen.dart';
import 'walk_in_screen.dart';

/// The main authenticated frame: a left navigation rail + the active section.
/// Designed for a wide desktop window (the reception terminal).
/// Features premium hover highlights, page slide/fade transitions, and a pulsing connectivity badge.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  late final PageController _pageController = PageController(initialPage: 0);

  static const _destinations = <_NavItem>[
    _NavItem('Dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded),
    _NavItem('Appointments', Icons.event_note_outlined, Icons.event_note_rounded),
    _NavItem('Walk-in', Icons.person_add_alt_outlined, Icons.person_add_alt_1_rounded),
    _NavItem('Doctors', Icons.badge_outlined, Icons.badge_rounded),
    _NavItem('Archive', Icons.inventory_2_outlined, Icons.inventory_2_rounded),
    _NavItem('End of Day', Icons.nightlight_outlined, Icons.nightlight_round),
    _NavItem('Settings', Icons.settings_outlined, Icons.settings_rounded),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSelect(int i) {
    setState(() => _index = i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Rail(
            items: _destinations,
            index: _index,
            onSelect: _onSelect,
          ),
          Container(
            width: 1,
            color: AppColors.border,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _index = i),
              physics: const NeverScrollableScrollPhysics(), // navigation via rail only
              children: const [
                DashboardScreen(),
                AppointmentsScreen(),
                WalkInScreen(),
                DoctorsScreen(),
                ArchiveScreen(),
                EodScreen(),
                SettingsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem(this.label, this.icon, this.activeIcon);
}

class _Rail extends StatelessWidget {
  final List<_NavItem> items;
  final int index;
  final ValueChanged<int> onSelect;

  const _Rail({
    required this.items,
    required this.index,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Container(
      width: 240,
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand + logo badge
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.local_hospital_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Aarvy',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const _ConnectivityBadge(),
          const SizedBox(height: 14),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final selected = i == index;
                final item = items[i];
                return Padding(
                  key: ValueKey(item.label),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _RailItem(
                    label: item.label,
                    icon: selected ? item.activeIcon : item.icon,
                    selected: selected,
                    onTap: () => onSelect(i),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),
          // Account Profile Card
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.scaffold,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.mint, AppColors.mintDark],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      (auth.displayName.isNotEmpty ? auth.displayName[0] : 'R')
                          .toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.displayName.isEmpty ? 'Receptionist' : auth.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                        Text(
                          auth.session?.role.toUpperCase() ?? 'RECEPTION',
                          style: const TextStyle(
                              fontSize: 10,
                              letterSpacing: 0.3,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sign out',
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    color: AppColors.textSecondary,
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Sign out?'),
                          content: const Text(
                              'Are you sure you want to sign out from the Reception Station?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.danger,
                                foregroundColor: AppColors.white,
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Sign out'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        context.read<AuthProvider>().logout();
                      }
                    },
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

class _RailItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RailItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppTheme.fast,
        curve: AppTheme.curve,
        decoration: BoxDecoration(
          color: widget.selected
              ? AppColors.primary
              : _hovered
                  ? AppColors.primary.withValues(alpha: 0.05)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: widget.selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 20,
                    color: widget.selected
                        ? AppColors.white
                        : _hovered
                            ? AppColors.primary
                            : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 14),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w600,
                      color: widget.selected
                          ? AppColors.white
                          : _hovered
                              ? AppColors.primary
                              : AppColors.textSecondary,
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

class _ConnectivityBadge extends StatefulWidget {
  const _ConnectivityBadge();

  @override
  State<_ConnectivityBadge> createState() => _ConnectivityBadgeState();
}

class _ConnectivityBadgeState extends State<_ConnectivityBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectivityProvider>();
    final online = conn.online;
    final color = online ? AppColors.success : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 2.2).animate(
                    CurvedAnimation(
                      parent: _pulseController,
                      curve: Curves.easeOut,
                    ),
                  ),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0.6, end: 0.0).animate(
                      CurvedAnimation(
                        parent: _pulseController,
                        curve: Curves.easeOut,
                      ),
                    ),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              online ? 'Connected' : 'Offline',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const Spacer(),
            if (conn.checking)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.6),
              )
            else
              InkWell(
                onTap: () => context.read<ConnectivityProvider>().refresh(),
                child: Icon(Icons.refresh_rounded,
                    size: 15, color: color.withValues(alpha: 0.7)),
              ),
          ],
        ),
      ),
    );
  }
}
