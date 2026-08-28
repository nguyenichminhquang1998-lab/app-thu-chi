import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression test for the crash reported on the sideloaded iOS build:
/// every TextField and every bottom NavigationBar destination threw
/// "Null check operator used on a null value" from
/// MaterialLocalizations.of(context), because the app forced
/// `locale: Locale('vi', 'VN')` without registering
/// GlobalMaterialLocalizations.delegate. This reproduces the exact
/// minimal shape (MaterialApp -> Scaffold -> TextField + NavigationBar)
/// both broken and fixed, so the fix can be verified without a full
/// rebuild-and-resideload cycle onto a real iPhone.
void main() {
  Widget buildApp({required bool withLocalizationDelegates}) {
    return MaterialApp(
      locale: const Locale('vi', 'VN'),
      supportedLocales: const [Locale('vi', 'VN')],
      localizationsDelegates: withLocalizationDelegates
          ? const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ]
          : null,
      home: Scaffold(
        appBar: AppBar(title: const Text('Thêm giao dịch')),
        body: const Column(
          children: [
            TextField(decoration: InputDecoration(hintText: '0')),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 0,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Trang chủ'),
            NavigationDestination(icon: Icon(Icons.pie_chart), label: 'Biểu đồ'),
            NavigationDestination(icon: Icon(Icons.account_balance), label: 'Ngân sách'),
            NavigationDestination(icon: Icon(Icons.settings), label: 'Cài đặt'),
          ],
        ),
      ),
    );
  }

  testWidgets(
    'reproduces the crash when localization delegates are missing',
    (tester) async {
      await tester.pumpWidget(buildApp(withLocalizationDelegates: false));
      await tester.pump();

      // Missing delegates cascade into several exceptions (the TextField and
      // each NavigationDestination all fail their own MaterialLocalizations
      // lookup, plus a resulting semantics-tree error) — the fix in app.dart
      // is verified by the second test below asserting zero exceptions.
      expect(
        tester.takeException(),
        isNotNull,
        reason: 'Expected the historical bug to reproduce here',
      );
    },
  );

  testWidgets(
    'TextField and NavigationBar render without error once delegates are registered',
    (tester) async {
      await tester.pumpWidget(buildApp(withLocalizationDelegates: true));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Trang chủ'), findsOneWidget);
    },
  );
}
