import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/notification_service.dart';
import 'state/app_state.dart';
import 'state/settings_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN');
  await NotificationService.instance.init();

  final settings = SettingsState();
  await settings.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsState>.value(value: settings),
        ChangeNotifierProvider<AppState>(
          create: (_) => AppState(settings: settings)..init(),
        ),
      ],
      child: const AppThuChi(),
    ),
  );
}
