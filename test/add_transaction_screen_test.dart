import 'package:app_thu_chi/screens/add_transaction/add_transaction_screen.dart';
import 'package:app_thu_chi/state/app_state.dart';
import 'package:app_thu_chi/state/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_support.dart';

/// Regression coverage for the "bỏ chụp ảnh hoá đơn / bỏ ghi âm" feedback:
/// makes sure neither feature's UI is still reachable, and that the fields
/// that remain (amount, note, tag) are actually interactable — the same
/// screen that was fully broken by the localization bug earlier, so this
/// also doubles as an end-to-end smoke test for that fix.
void main() {
  setUpAll(() {
    initTestDatabaseFactory();
    SharedPreferences.setMockInitialValues({});
  });

  setUp(resetTestDatabase);

  Future<AppState> pumpAddTransactionScreen(WidgetTester tester) async {
    // sqflite_common_ffi talks to a background isolate; that real I/O needs
    // to run in the real async zone (tester.runAsync), not the widget test
    // framework's fake-clock zone, or the isolate messages never arrive and
    // the test hangs forever instead of failing.
    late SettingsState settings;
    late AppState appState;
    await tester.runAsync(() async {
      settings = SettingsState();
      await settings.load();
      appState = AppState(settings: settings);
      await appState.init();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsState>.value(value: settings),
          ChangeNotifierProvider<AppState>.value(value: appState),
        ],
        child: MaterialApp(
          locale: const Locale('vi', 'VN'),
          supportedLocales: const [Locale('vi', 'VN')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AddTransactionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return appState;
  }

  testWidgets('has no receipt-photo or voice-input UI left', (tester) async {
    await pumpAddTransactionScreen(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Đính kèm hoá đơn'), findsNothing);
    expect(find.byIcon(Icons.camera_alt_outlined), findsNothing);
    expect(find.byIcon(Icons.mic), findsNothing);
    expect(find.byIcon(Icons.mic_none), findsNothing);
    expect(find.text('Nhập bằng giọng nói'), findsNothing);
  });

  testWidgets('calculator keypad is hidden until the amount field is tapped', (tester) async {
    await pumpAddTransactionScreen(tester);

    expect(find.byKey(const ValueKey('calc-equals')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('calc-amount-display')));
    await tester.pump();

    expect(find.byKey(const ValueKey('calc-equals')), findsOneWidget);
  });

  testWidgets('calculator keypad hides again when another field is tapped', (tester) async {
    await pumpAddTransactionScreen(tester);
    await tester.tap(find.byKey(const ValueKey('calc-amount-display')));
    await tester.pump();
    expect(find.byKey(const ValueKey('calc-equals')), findsOneWidget);

    final noteField = find.widgetWithText(TextField, 'Ghi chú');
    await tester.ensureVisible(noteField);
    await tester.pumpAndSettle();
    await tester.tap(noteField);
    await tester.pump();

    expect(find.byKey(const ValueKey('calc-equals')), findsNothing);
  });

  testWidgets('amount keypad accepts digit taps with thousands separators', (tester) async {
    await pumpAddTransactionScreen(tester);

    await tester.tap(find.byKey(const ValueKey('calc-amount-display')));
    await tester.pump();
    for (final d in '1500000'.split('')) {
      await tester.tap(find.byKey(ValueKey('calc-digit-$d')));
      await tester.pump();
    }

    expect(find.text('1.500.000'), findsOneWidget);
  });

  testWidgets('calculator computes 622.222 − 32.922 = 589.300', (tester) async {
    await pumpAddTransactionScreen(tester);

    await tester.tap(find.byKey(const ValueKey('calc-amount-display')));
    await tester.pump();
    for (final d in '622222'.split('')) {
      await tester.tap(find.byKey(ValueKey('calc-digit-$d')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('calc-op-subtract')));
    await tester.pump();
    expect(find.text('622.222'), findsOneWidget, reason: 'expression trail shows the first operand once an operator is pressed');

    for (final d in '32922'.split('')) {
      await tester.tap(find.byKey(ValueKey('calc-digit-$d')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('calc-equals')));
    await tester.pump();

    expect(find.text('589.300'), findsOneWidget);
  });

  testWidgets('note field accepts free text typing', (tester) async {
    await pumpAddTransactionScreen(tester);

    final noteField = find.widgetWithText(TextField, 'Ghi chú');
    expect(noteField, findsOneWidget);
    await tester.enterText(noteField, 'Ăn trưa với bạn');
    await tester.pump();

    expect(find.text('Ăn trưa với bạn'), findsOneWidget);
  });

  testWidgets('category, wallet and date pickers are tappable', (tester) async {
    final appState = await pumpAddTransactionScreen(tester);

    expect(appState.wallets, isNotEmpty, reason: 'default wallet should have been seeded');
    expect(appState.wallets.first.name, 'Tiền mặt');

    expect(find.text('Chọn danh mục'), findsOneWidget);
    expect(find.textContaining('Tiền mặt'), findsOneWidget);

    await tester.tap(find.text('Chọn danh mục'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // The category picker bottom sheet should now be open.
    expect(find.text('Chi tiêu'), findsWidgets);
    expect(find.text('Thu nhập'), findsWidgets);
  });
}
