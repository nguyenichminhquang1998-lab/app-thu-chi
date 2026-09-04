import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/category.dart';
import '../models/transaction_entry.dart';
import '../models/wallet.dart';
import '../platform/exported_file.dart';
import '../utils/formatters.dart';

/// Exports a set of transactions (typically the currently selected report
/// range) to CSV or PDF. Building the bytes is pure Dart so both the mobile
/// share sheet and the browser download produce identical files.
class ExportService {
  pw.ThemeData? _pdfTheme;

  /// The PDF library's built-in Helvetica has no Vietnamese glyphs, so every
  /// accented character came out broken. Roboto (bundled in assets) covers
  /// the full Vietnamese range.
  Future<pw.ThemeData> _loadPdfTheme() async {
    return _pdfTheme ??= pw.ThemeData.withFont(
      base: pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf')),
      bold: pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Medium.ttf')),
    );
  }

  Future<ExportedFile> buildCsvReport({
    required List<TxEntry> transactions,
    required Category? Function(String? id) categoryOf,
    required Wallet? Function(String id) walletOf,
  }) async {
    final rows = <List<Object?>>[
      ['Ngày', 'Loại', 'Danh mục', 'Ví', 'Số tiền', 'Ghi chú', 'Thẻ'],
      for (final tx in transactions)
        [
          formatDate(DateTime.fromMillisecondsSinceEpoch(tx.date)),
          switch (tx.type) {
            TxType.expense => 'Chi tiêu',
            TxType.income => 'Thu nhập',
            TxType.transfer => 'Chuyển khoản',
          },
          categoryOf(tx.categoryId)?.name ?? '',
          walletOf(tx.walletId)?.name ?? '',
          tx.amount,
          tx.note,
          tx.tag ?? '',
        ],
    ];
    return ExportedFile(
      name: 'bao-cao-thu-chi.csv',
      mimeType: 'text/csv',
      bytes: utf8.encode(Csv().encode(rows)),
    );
  }

  Future<ExportedFile> buildPdfReport({
    required List<TxEntry> transactions,
    required Category? Function(String? id) categoryOf,
    required Wallet? Function(String id) walletOf,
    required DateTime start,
    required DateTime end,
  }) async {
    final doc = pw.Document(theme: await _loadPdfTheme());
    final income = transactions.where((t) => t.type == TxType.income).fold<double>(0, (s, t) => s + t.amount);
    final expense = transactions.where((t) => t.type == TxType.expense).fold<double>(0, (s, t) => s + t.amount);

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, text: 'Báo cáo thu chi'),
          pw.Text('Khoảng thời gian: ${formatDateRange(start, end)}'),
          pw.SizedBox(height: 8),
          pw.Text('Tổng thu nhập: ${formatCurrency(income)}'),
          pw.Text('Tổng chi tiêu: ${formatCurrency(expense)}'),
          pw.Text('Chênh lệch: ${formatCurrency(income - expense)}'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['Ngày', 'Loại', 'Danh mục', 'Ví', 'Số tiền', 'Ghi chú'],
            data: [
              for (final tx in transactions)
                [
                  formatDate(DateTime.fromMillisecondsSinceEpoch(tx.date)),
                  switch (tx.type) {
                    TxType.expense => 'Chi tiêu',
                    TxType.income => 'Thu nhập',
                    TxType.transfer => 'Chuyển khoản',
                  },
                  categoryOf(tx.categoryId)?.name ?? '',
                  walletOf(tx.walletId)?.name ?? '',
                  formatCurrency(tx.amount),
                  tx.note,
                ],
            ],
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
        pageFormat: PdfPageFormat.a4,
      ),
    );

    return ExportedFile(
      name: 'bao-cao-thu-chi.pdf',
      mimeType: 'application/pdf',
      bytes: await doc.save(),
    );
  }
}
