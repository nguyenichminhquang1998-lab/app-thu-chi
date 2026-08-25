import '../../models/recurring_transaction.dart';
import '../app_database.dart';

class RecurringRepository {
  Future<List<RecurringTransaction>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('recurring_transactions', orderBy: 'next_due_date ASC');
    return rows.map(RecurringTransaction.fromMap).toList();
  }

  Future<List<RecurringTransaction>> getDue(DateTime asOf) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'recurring_transactions',
      where: 'active = 1 AND next_due_date <= ?',
      whereArgs: [asOf.millisecondsSinceEpoch],
    );
    return rows.map(RecurringTransaction.fromMap).toList();
  }

  Future<void> insert(RecurringTransaction item) async {
    final db = await AppDatabase.instance.database;
    await db.insert('recurring_transactions', item.toMap());
  }

  Future<void> update(RecurringTransaction item) async {
    final db = await AppDatabase.instance.database;
    await db.update('recurring_transactions', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('recurring_transactions', where: 'id = ?', whereArgs: [id]);
  }
}
