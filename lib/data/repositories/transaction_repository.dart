import '../../models/transaction_entry.dart';
import '../app_database.dart';

class TransactionRepository {
  Future<List<TxEntry>> getInRange(DateTime start, DateTime end) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'tx_entries',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date DESC, created_at DESC',
    );
    return rows.map(TxEntry.fromMap).toList();
  }

  Future<List<TxEntry>> search(String query, {DateTime? start, DateTime? end}) async {
    final db = await AppDatabase.instance.database;
    final where = <String>['(note LIKE ? OR tag LIKE ?)'];
    final args = <Object?>['%$query%', '%$query%'];
    if (start != null && end != null) {
      where.add('date >= ? AND date <= ?');
      args.addAll([start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);
    }
    final rows = await db.query(
      'tx_entries',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'date DESC',
      limit: 200,
    );
    return rows.map(TxEntry.fromMap).toList();
  }

  Future<void> insert(TxEntry entry) async {
    final db = await AppDatabase.instance.database;
    await db.insert('tx_entries', entry.toMap());
  }

  Future<void> update(TxEntry entry) async {
    final db = await AppDatabase.instance.database;
    await db.update('tx_entries', entry.toMap(), where: 'id = ?', whereArgs: [entry.id]);
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('tx_entries', where: 'id = ?', whereArgs: [id]);
  }

  /// Net balance contribution of every wallet, combining initial balance +
  /// every transaction/transfer that touches it. Returns walletId -> delta
  /// (does NOT include the wallet's own initial_balance).
  Future<Map<String, double>> walletDeltas() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('tx_entries');
    final deltas = <String, double>{};
    for (final row in rows) {
      final tx = TxEntry.fromMap(row);
      switch (tx.type) {
        case TxType.expense:
          deltas[tx.walletId] = (deltas[tx.walletId] ?? 0) - tx.amount;
        case TxType.income:
          deltas[tx.walletId] = (deltas[tx.walletId] ?? 0) + tx.amount;
        case TxType.transfer:
          deltas[tx.walletId] = (deltas[tx.walletId] ?? 0) - tx.amount;
          if (tx.toWalletId != null) {
            deltas[tx.toWalletId!] = (deltas[tx.toWalletId!] ?? 0) + tx.amount;
          }
      }
    }
    return deltas;
  }

  /// Sum of expense/income per category within [start, end], keyed by
  /// categoryId ('' for uncategorized/transfers are excluded).
  Future<Map<String, double>> sumByCategory(
    DateTime start,
    DateTime end,
    TxType type,
  ) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT category_id, SUM(amount) as total
      FROM tx_entries
      WHERE type = ? AND date >= ? AND date <= ? AND category_id IS NOT NULL
      GROUP BY category_id
      ''',
      [type.name, start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    final map = <String, double>{};
    for (final row in rows) {
      final catId = row['category_id'] as String?;
      if (catId == null) continue;
      map[catId] = (row['total'] as num).toDouble();
    }
    return map;
  }

  /// Daily totals of income vs expense between [start, end], inclusive.
  Future<Map<DateTime, ({double income, double expense})>> dailyTotals(
    DateTime start,
    DateTime end,
  ) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT date, type, amount FROM tx_entries
      WHERE date >= ? AND date <= ? AND type IN ('expense', 'income')
      ''',
      [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
    );
    final result = <DateTime, ({double income, double expense})>{};
    for (final row in rows) {
      final date = DateTime.fromMillisecondsSinceEpoch(row['date'] as int);
      final day = DateTime(date.year, date.month, date.day);
      final current = result[day] ?? (income: 0.0, expense: 0.0);
      final amount = (row['amount'] as num).toDouble();
      if (row['type'] == 'income') {
        result[day] = (income: current.income + amount, expense: current.expense);
      } else {
        result[day] = (income: current.income, expense: current.expense + amount);
      }
    }
    return result;
  }

  Future<double> sumByCategoryAndMonth(String categoryId, DateTime monthStart, DateTime monthEnd) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT SUM(amount) as total FROM tx_entries
      WHERE category_id = ? AND type = 'expense' AND date >= ? AND date <= ?
      ''',
      [categoryId, monthStart.millisecondsSinceEpoch, monthEnd.millisecondsSinceEpoch],
    );
    final total = rows.first['total'] as num?;
    return total?.toDouble() ?? 0;
  }

  Future<List<TxEntry>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('tx_entries', orderBy: 'date DESC');
    return rows.map(TxEntry.fromMap).toList();
  }
}
