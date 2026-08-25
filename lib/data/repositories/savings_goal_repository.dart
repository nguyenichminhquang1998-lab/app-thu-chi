import '../../models/savings_goal.dart';
import '../app_database.dart';

class SavingsGoalRepository {
  Future<List<SavingsGoal>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('savings_goals', orderBy: 'created_at ASC');
    return rows.map(SavingsGoal.fromMap).toList();
  }

  Future<void> insert(SavingsGoal goal) async {
    final db = await AppDatabase.instance.database;
    await db.insert('savings_goals', goal.toMap());
  }

  Future<void> update(SavingsGoal goal) async {
    final db = await AppDatabase.instance.database;
    await db.update('savings_goals', goal.toMap(), where: 'id = ?', whereArgs: [goal.id]);
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
  }
}
