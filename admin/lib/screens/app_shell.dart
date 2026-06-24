import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_provider.dart';
import '../state/connectivity_provider.dart';
import '../theme/app_colors.dart';
import 'dashboard_screen.dart';
import 'doctors_screen.dart';
import 'trends_screen.dart';

/// The authenticated admin frame: a bottom navigation bar across the three
/// sections (Live dashboard, Trends, Doctors), with a shared app bar showing
/// the connectivity badge + sign-out.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _titles = ['Live overview', 'Trends', 'Doctors'];

  Widget _page(int i) {
    switch (i) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const TrendsScreen();
      case 2:
        return const DoctorsScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.local_hospital_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(_titles[_index]),
          ],
        ),
        actions: const [
          _ConnectivityDot(),
          _SignOutButton(),
          SizedBox(width: 8),
        ],
      ),
      body: _page(_index),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Live',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart_rounded),
            label: 'Trends',
          ),
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge_rounded),
            label: 'Doctors',
          ),
        ],
      ),
    );
  }
}

class _ConnectivityDot extends StatelessWidget {
  const _ConnectivityDot();

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityProvider>().online;
    final color = online ? AppColors.success : AppColors.warning;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: online ? 'Cloud connected' : 'Offline',
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(online ? 'Online' : 'Offline',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Sign out',
      icon: const Icon(Icons.logout_rounded, size: 20),
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Sign out?'),
            content: const Text('You’ll need to sign in again to manage the hospital.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Sign out')),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          context.read<AuthProvider>().logout();
        }
      },
    );
  }
}
