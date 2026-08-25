import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/lock/lock_screen.dart';
import 'screens/root_shell.dart';
import 'state/app_state.dart';
import 'state/settings_state.dart';
import 'theme/app_theme.dart';

class AppThuChi extends StatelessWidget {
  const AppThuChi({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    return MaterialApp(
      title: 'Thu Chi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      supportedLocales: const [Locale('vi', 'VN')],
      locale: const Locale('vi', 'VN'),
      home: const _AppGate(),
    );
  }
}

class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final settings = context.watch<SettingsState>();

    if (appState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (settings.lockEnabled && !_unlocked) {
      return LockScreen(onUnlocked: () => setState(() => _unlocked = true));
    }
    return const RootShell();
  }
}
