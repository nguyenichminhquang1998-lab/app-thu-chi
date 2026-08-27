import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/notification_service.dart';
import 'state/app_state.dart';
import 'state/settings_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Show the real exception text on screen instead of Flutter's default
  // blank grey box in release builds — without this, a widget-build error
  // is invisible on a sideloaded (non-debugger-attached) device.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    final allLines = details.stack.toString().split('\n');
    final appLines = allLines.where((l) => l.contains('package:app_thu_chi/')).take(6).toList();
    final stackLines = (appLines.isNotEmpty ? appLines : allLines.take(10).toList()).join('\n');
    return Container(
      color: const Color(0xFFFFCDD2),
      padding: const EdgeInsets.all(12),
      alignment: Alignment.topLeft,
      child: SingleChildScrollView(
        child: Text(
          '${details.exceptionAsString()}\n\n$stackLines',
          style: const TextStyle(color: Colors.black, fontSize: 10),
        ),
      ),
    );
  };
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

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
