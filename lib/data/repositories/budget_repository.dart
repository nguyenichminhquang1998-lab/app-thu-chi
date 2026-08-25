import '../../models/budget.dart';
import '../app_database.dart';

class BudgetRepository {
  Future<List<Budget>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('budgets', orderBy: 'created_at ASC');
    return rows.map(Budget.fromMap).toList();
  }

  Future<void> upsert(Budget budget) async {
    final db = await AppDatabase.instance.database;
    await db.insert('budgets', budget.toMap());
  }

  Future<void> update(Budget budget) async {
    final db = await AppDatabase.instance.database;
    await db.update('budgets', budget.toMap(), where: 'id = ?', whereArgs: [budget.id]);
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteByCategory(String categoryId) async {
    final db = await AppDatabase.instance.database;
    await db.delete('budgets', where: 'category_id = ?', whereArgs: [categoryId]);
  }
}
