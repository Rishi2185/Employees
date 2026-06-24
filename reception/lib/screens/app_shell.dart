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
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _destinations = <_NavItem>[
    _NavItem('Dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded),
    _NavItem('Appointments', Icons.event_note_outlined, Icons.event_note_rounded),
    _NavItem('Walk-in', Icons.person_add_alt_outlined, Icons.person_add_alt_1_rounded),
    _NavItem('Doctors', Icons.badge_outlined, Icons.badge_rounded),
    _NavItem('Archive', Icons.inventory_2_outlined, Icons.inventory_2_rounded),
    _NavItem('End of Day', Icons.nightlight_outlined, Icons.nightlight_round),
    _NavItem('Settings', Icons.settings_outlined, Icons.settings_rounded),
  ];

  Widget _page(int i) {
    switch (i) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const AppointmentsScreen();
      case 2:
        return const WalkInScreen();
      case 3:
        return const DoctorsScreen();
      case 4:
        return const ArchiveScreen();
      case 5:
        return const EodScreen();
      case 6:
        return const SettingsScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Rail(
            items: _destinations,
            index: _index,
            onSelect: (i) => setState(() => _index = i),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppTheme.fast,
              child: KeyedSubtree(
                key: ValueKey(_index),
                child: _page(_index),
              ),
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
      width: 232,
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand + connectivity
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(Icons.local_hospital_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Aarvy',
                      style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ),
              ],
            ),
          ),
          const _ConnectivityBadge(),
          const SizedBox(height: 8),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final selected = i == index;
                final item = items[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Material(
                    color: selected ? AppColors.mint : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      onTap: () => onSelect(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              selected ? item.activeIcon : item.icon,
                              size: 21,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),
          // Account + sign out
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.mint,
                  child: Text(
                    (auth.displayName.isNotEmpty ? auth.displayName[0] : 'R')
                        .toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.displayName.isEmpty ? 'Reception' : auth.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        auth.session?.role ?? '',
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  color: AppColors.textSecondary,
                  onPressed: () => context.read<AuthProvider>().logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectivityBadge extends StatelessWidget {
  const _ConnectivityBadge();

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
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              online ? 'Cloud connected' : 'Offline',
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: color),
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
                child: const Icon(Icons.refresh_rounded,
                    size: 15, color: AppColors.textTertiary),
              ),
          ],
        ),
      ),
    );
  }
}
