import 'dart:convert';

import 'package:app_thu_chi/models/category.dart';
import 'package:app_thu_chi/models/transaction_entry.dart';
import 'package:app_thu_chi/models/wallet.dart';
import 'package:app_thu_chi/services/export_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Covers the report export after it stopped returning dart:io Files (which
/// don't exist in a browser) and started returning raw bytes that both the
/// native share sheet and the web download path can deliver.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // main() does this before runApp; the report formatters need it too.
  setUpAll(() => initializeDateFormatting('vi_VN'));

  const wallet = Wallet(
    id: 'w1',
    name: 'Tiền mặt',
    kind: WalletKind.cash,
    color: 0xFF4CAF50,
    currency: 'VND',
    createdAt: 0,
  );
  const category = Category(
    id: 'c1',
    name: 'Ăn uống',
    type: CategoryType.expense,
    iconKey: 'food',
    color: 0xFFFF7043,
  );
  final transactions = [
    TxEntry(
      id: 't1',
      type: TxType.expense,
      amount: 45000,
      currency: 'VND',
      walletId: wallet.id,
      categoryId: category.id,
      date: DateTime(2026, 3, 15).millisecondsSinceEpoch,
      note: 'Ăn trưa ở quán ưa thích',
      createdAt: 0,
    ),
  ];

  Category? categoryOf(String? id) => id == category.id ? category : null;
  Wallet? walletOf(String id) => id == wallet.id ? wallet : null;

  test('CSV report is UTF-8 bytes that keep Vietnamese text intact', () async {
    final file = await ExportService().buildCsvReport(
      transactions: transactions,
      categoryOf: categoryOf,
      walletOf: walletOf,
    );

    expect(file.name, 'bao-cao-thu-chi.csv');
    expect(file.mimeType, 'text/csv');
    final content = utf8.decode(file.bytes);
    expect(content, contains('Ăn uống'));
    expect(content, contains('Tiền mặt'));
    expect(content, contains('Ăn trưa ở quán ưa thích'));
  });

  test('PDF report is produced as real PDF bytes', () async {
    final file = await ExportService().buildPdfReport(
      transactions: transactions,
      categoryOf: categoryOf,
      walletOf: walletOf,
      start: DateTime(2026, 3, 1),
      end: DateTime(2026, 3, 31),
    );

    expect(file.name, 'bao-cao-thu-chi.pdf');
    expect(file.mimeType, 'application/pdf');
    // Every PDF starts with the "%PDF-" magic bytes.
    expect(utf8.decode(file.bytes.sublist(0, 5)), '%PDF-');
    expect(file.bytes.length, greaterThan(1000));
  });

  test('PDF embeds a font so Vietnamese diacritics are not dropped', () async {
    final file = await ExportService().buildPdfReport(
      transactions: transactions,
      categoryOf: categoryOf,
      walletOf: walletOf,
      start: DateTime(2026, 3, 1),
      end: DateTime(2026, 3, 31),
    );

    // The default Helvetica has no Vietnamese glyphs, so the fix was to embed
    // Roboto. A PDF that embeds a font carries a FontFile2 stream; one that
    // falls back to a built-in font does not.
    final raw = latin1.decode(file.bytes, allowInvalid: true);
    expect(raw, contains('FontFile2'), reason: 'no embedded font means broken Vietnamese text');
    expect(raw, contains('Roboto'));
  });
}
