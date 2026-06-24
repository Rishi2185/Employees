import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'db/app_database.dart';
import 'screens/app_shell.dart';
import 'screens/login_screen.dart';
import 'state/appointments_provider.dart';
import 'state/archive_provider.dart';
import 'state/auth_provider.dart';
import 'state/connectivity_provider.dart';
import 'state/dashboard_provider.dart';
import 'state/doctors_provider.dart';
import 'state/eod_provider.dart';
import 'state/services.dart';
import 'state/settings_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop window chrome — a comfortable single-station default.
  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(1280, 820),
    minimumSize: Size(1040, 680),
    center: true,
    title: 'Aarvy Reception',
    titleBarStyle: TitleBarStyle.normal,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Open the durable local archive and load settings before wiring services.
  final database = AppDatabase.instance;
  await database.open();
  final settings = await SettingsStore.load();
  final services = Services.wire(settings: settings, database: database);

  runApp(ReceptionApp(services: services));
}

class ReceptionApp extends StatelessWidget {
  final Services services;
  const ReceptionApp({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Services>.value(value: services),
        ChangeNotifierProvider(create: (_) => AuthProvider(services)),
        ChangeNotifierProvider(
            create: (_) => ConnectivityProvider(services)..start()),
        ChangeNotifierProvider(create: (_) => DashboardProvider(services)),
        ChangeNotifierProvider(create: (_) => AppointmentsProvider(services)),
        ChangeNotifierProvider(create: (_) => DoctorsProvider(services)),
        ChangeNotifierProvider(create: (_) => ArchiveProvider(services)),
        ChangeNotifierProvider(create: (_) => EodProvider(services)),
      ],
      child: MaterialApp(
        title: 'Aarvy Reception',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _Root(),
      ),
    );
  }
}

/// Switches between the login screen and the main shell based on auth status.
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
