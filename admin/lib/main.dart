import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'state/auth_provider.dart';
import 'state/connectivity_provider.dart';
import 'state/doctors_provider.dart';
import 'state/live_stats_provider.dart';
import 'state/services.dart';
import 'state/settings_store.dart';
import 'state/trends_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = await SettingsStore.load();
  final services = Services.wire(settings: settings);

  runApp(AdminApp(services: services));
}

class AdminApp extends StatelessWidget {
  final Services services;
  const AdminApp({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Services>.value(value: services),
        ChangeNotifierProvider(create: (_) => AuthProvider(services)),
        ChangeNotifierProvider(
            create: (_) => ConnectivityProvider(services)..start()),
        ChangeNotifierProvider(create: (_) => LiveStatsProvider(services)),
        ChangeNotifierProvider(create: (_) => TrendsProvider(services)),
        ChangeNotifierProvider(create: (_) => DoctorsProvider(services)),
      ],
      child: MaterialApp(
        title: 'Aarvy Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _Root(),
      ),
    );
  }
}

/// Routes between login and the main shell based on admin auth status.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.signedOut:
        return const LoginScreen();
      case AuthStatus.signedIn:
        return const AppShell();
    }
  }
}
