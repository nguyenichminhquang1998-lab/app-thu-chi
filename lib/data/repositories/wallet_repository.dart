import '../../models/wallet.dart';
import '../app_database.dart';

class WalletRepository {
  Future<List<Wallet>> getAll({bool includeArchived = false}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'wallets',
      where: includeArchived ? null : 'archived = 0',
      orderBy: 'sort_order ASC, created_at ASC',
    );
    return rows.map(Wallet.fromMap).toList();
  }

  Future<void> insert(Wallet wallet) async {
    final db = await AppDatabase.instance.database;
    await db.insert('wallets', wallet.toMap());
  }

  Future<void> update(Wallet wallet) async {
    final db = await AppDatabase.instance.database;
    await db.update('wallets', wallet.toMap(), where: 'id = ?', whereArgs: [wallet.id]);
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('wallets', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> archive(String id) async {
    final db = await AppDatabase.instance.database;
    await db.update('wallets', {'archived': 1}, where: 'id = ?', whereArgs: [id]);
  }
}
