import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/category.dart';
import '../models/transaction_entry.dart';
import '../models/wallet.dart';
import '../utils/formatters.dart';

/// Exports a set of transactions (typically the currently selected report
/// range) to CSV or PDF, then hands the file to the OS share sheet so the
/// user can save it, email it to an accountant, etc.
class ExportService {
  Future<File> exportCsv({
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
    final csv = Csv().encode(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/bao-cao-thu-chi.csv');
    await file.writeAsString(csv, encoding: SystemEncoding());
    return file;
  }

  Future<File> exportPdf({
    required List<TxEntry> transactions,
    required Category? Function(String? id) categoryOf,
    required Wallet? Function(String id) walletOf,
    required DateTime start,
    required DateTime end,
  }) async {
    final doc = pw.Document();
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

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/bao-cao-thu-chi.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  Future<void> shareFile(File file, {String? text}) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: text),
    );
  }
}
