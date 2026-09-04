import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

import '../data/app_database.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/recurring_repository.dart';
import '../data/repositories/savings_goal_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/wallet_repository.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/recurring_transaction.dart';
import '../models/savings_goal.dart';
import '../models/transaction_entry.dart';
import '../models/wallet.dart';
import '../platform/exported_file.dart';

/// Exports/imports the whole database as a single JSON file so users can
/// back up their data to any cloud drive/Files app, or move it to a new
/// phone, without depending on a specific cloud provider.
class BackupService {
  static const int schemaVersion = 1;

  final walletRepository = WalletRepository();
  final categoryRepository = CategoryRepository();
  final transactionRepository = TransactionRepository();
  final budgetRepository = BudgetRepository();
  final recurringRepository = RecurringRepository();
  final savingsGoalRepository = SavingsGoalRepository();

  Future<Map<String, Object?>> _buildSnapshot() async {
    final wallets = await walletRepository.getAll(includeArchived: true);
    final categories = await categoryRepository.getAll(includeArchived: true);
    final transactions = await transactionRepository.getAll();
    final budgets = await budgetRepository.getAll();
    final recurring = await recurringRepository.getAll();
    final goals = await savingsGoalRepository.getAll();
    return {
      'schema_version': schemaVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'wallets': wallets.map((e) => e.toMap()).toList(),
      'categories': categories.map((e) => e.toMap()).toList(),
      'transactions': transactions.map((e) => e.toMap()).toList(),
      'budgets': budgets.map((e) => e.toMap()).toList(),
      'recurring_transactions': recurring.map((e) => e.toMap()).toList(),
      'savings_goals': goals.map((e) => e.toMap()).toList(),
    };
  }

  String _stamp() => DateTime.now().toIso8601String().replaceAll(':', '-');

  /// The only format "Khôi phục dữ liệu" can read back.
  Future<ExportedFile> buildJsonBackup() async {
    final snapshot = await _buildSnapshot();
    return ExportedFile(
      name: 'app-thu-chi-backup-${_stamp()}.json',
      mimeType: 'application/json',
      bytes: utf8.encode(const JsonEncoder.withIndent('  ').convert(snapshot)),
    );
  }

  /// Builds one file containing every table for outside viewing/analysis
  /// (spreadsheet or note apps). Unlike the JSON backup above, these are
  /// not meant to be re-imported — only the JSON format round-trips
  /// exactly through "Khôi phục dữ liệu".
  Future<Map<String, List<Map<String, Object?>>>> _buildTables() async {
    return {
      'Ví': (await walletRepository.getAll(includeArchived: true)).map((e) => e.toMap()).toList(),
      'Danh mục': (await categoryRepository.getAll(includeArchived: true)).map((e) => e.toMap()).toList(),
      'Giao dịch': (await transactionRepository.getAll()).map((e) => e.toMap()).toList(),
      'Ngân sách': (await budgetRepository.getAll()).map((e) => e.toMap()).toList(),
      'Giao dịch định kỳ': (await recurringRepository.getAll()).map((e) => e.toMap()).toList(),
      'Mục tiêu tiết kiệm': (await savingsGoalRepository.getAll()).map((e) => e.toMap()).toList(),
    };
  }

  Future<ExportedFile> buildCsvExport() async {
    final tables = await _buildTables();
    final rows = <List<Object?>>[];
    tables.forEach((title, records) {
      rows.add(['## $title']);
      if (records.isNotEmpty) {
        rows.add(records.first.keys.toList());
        for (final record in records) {
          rows.add(record.values.toList());
        }
      }
      rows.add([]);
    });
    return ExportedFile(
      name: 'app-thu-chi-du-lieu-${_stamp()}.csv',
      mimeType: 'text/csv',
      bytes: utf8.encode(Csv().encode(rows)),
    );
  }

  Future<ExportedFile> buildMarkdownExport() async {
    final tables = await _buildTables();
    final buffer = StringBuffer('# Dữ liệu Thu Chi\n\nXuất lúc: ${DateTime.now()}\n\n');
    tables.forEach((title, records) {
      buffer.writeln('## $title\n');
      if (records.isEmpty) {
        buffer.writeln('_Không có dữ liệu_\n');
        return;
      }
      final headers = records.first.keys.toList();
      buffer.writeln('| ${headers.join(' | ')} |');
      buffer.writeln('| ${headers.map((_) => '---').join(' | ')} |');
      for (final record in records) {
        buffer.writeln('| ${headers.map((h) => record[h]?.toString() ?? '').join(' | ')} |');
      }
      buffer.writeln();
    });
    return ExportedFile(
      name: 'app-thu-chi-du-lieu-${_stamp()}.md',
      mimeType: 'text/markdown',
      bytes: utf8.encode(buffer.toString()),
    );
  }

  /// Restores from the raw bytes of a picked backup file. Taking bytes rather
  /// than a file path is what makes restore work in the browser too, where a
  /// picked file is a Blob with no path at all.
  Future<void> restoreFromBytes(Uint8List bytes) async {
    final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    await restoreFromSnapshot(decoded);
  }

  Future<void> restoreFromSnapshot(Map<String, dynamic> snapshot) async {
    await AppDatabase.instance.clearAllData();

    final wallets = (snapshot['wallets'] as List<dynamic>? ?? [])
        .map((e) => Wallet.fromMap((e as Map).cast<String, Object?>()));
    for (final w in wallets) {
      await walletRepository.insert(w);
    }

    final categories = (snapshot['categories'] as List<dynamic>? ?? [])
        .map((e) => Category.fromMap((e as Map).cast<String, Object?>()));
    for (final c in categories) {
      await categoryRepository.insert(c);
    }

    final transactions = (snapshot['transactions'] as List<dynamic>? ?? [])
        .map((e) => TxEntry.fromMap((e as Map).cast<String, Object?>()));
    for (final t in transactions) {
      await transactionRepository.insert(t);
    }

    final budgets = (snapshot['budgets'] as List<dynamic>? ?? [])
        .map((e) => Budget.fromMap((e as Map).cast<String, Object?>()));
    for (final b in budgets) {
      await budgetRepository.upsert(b);
    }

    final recurring = (snapshot['recurring_transactions'] as List<dynamic>? ?? [])
        .map((e) => RecurringTransaction.fromMap((e as Map).cast<String, Object?>()));
    for (final r in recurring) {
      await recurringRepository.insert(r);
    }

    final goals = (snapshot['savings_goals'] as List<dynamic>? ?? [])
        .map((e) => SavingsGoal.fromMap((e as Map).cast<String, Object?>()));
    for (final g in goals) {
      await savingsGoalRepository.insert(g);
    }
  }
}
