import 'package:sqflite/sqflite.dart';

import '../../models/category.dart';
import '../app_database.dart';

class CategoryRepository {
  Future<List<Category>> getAll({bool includeArchived = false}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'categories',
      where: includeArchived ? null : 'archived = 0',
      orderBy: 'sort_order ASC',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<void> insert(Category category) async {
    final db = await AppDatabase.instance.database;
    await db.insert('categories', category.toMap());
  }

  Future<void> update(Category category) async {
    final db = await AppDatabase.instance.database;
    await db.update('categories', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reorder(List<Category> orderedCategories) async {
    final db = await AppDatabase.instance.database;
    final batch = db.batch();
    for (var i = 0; i < orderedCategories.length; i++) {
      batch.update(
        'categories',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [orderedCategories[i].id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<int> transactionCount(String categoryId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as c FROM tx_entries WHERE category_id = ?',
      [categoryId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
