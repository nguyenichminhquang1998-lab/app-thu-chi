import 'package:sqflite/sqflite.dart';

import '../platform/db_bootstrap.dart';

/// Thin singleton wrapper around the app's single sqflite database.
/// Repositories pull the opened [Database] from here rather than each
/// managing their own connection.
class AppDatabase {
  AppDatabase._internal();
  static final AppDatabase instance = AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    // Web and native disagree on where a database lives (a real directory vs
    // an IndexedDB key), so the platform module owns that decision.
    final path = await resolveDatabasePath('app_thu_chi.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE wallets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        kind TEXT NOT NULL,
        color INTEGER NOT NULL,
        currency TEXT NOT NULL,
        initial_balance REAL NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_key TEXT NOT NULL,
        color INTEGER NOT NULL,
        priority TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        archived INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE tx_entries (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        wallet_id TEXT NOT NULL,
        to_wallet_id TEXT,
        category_id TEXT,
        date INTEGER NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        tag TEXT,
        recurring_id TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (wallet_id) REFERENCES wallets(id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_tx_date ON tx_entries(date)');
    await db.execute('CREATE INDEX idx_tx_wallet ON tx_entries(wallet_id)');
    await db.execute('CREATE INDEX idx_tx_category ON tx_entries(category_id)');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        category_id TEXT,
        amount REAL NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring_transactions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        wallet_id TEXT NOT NULL,
        category_id TEXT,
        note TEXT NOT NULL DEFAULT '',
        frequency TEXT NOT NULL,
        interval_count INTEGER NOT NULL DEFAULT 1,
        start_date INTEGER NOT NULL,
        next_due_date INTEGER NOT NULL,
        end_date INTEGER,
        active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (wallet_id) REFERENCES wallets(id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_goals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0,
        target_date INTEGER,
        icon_key TEXT NOT NULL DEFAULT 'savings',
        color INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        achieved INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }

  /// Wipes all rows (used before a full JSON restore) without touching the
  /// schema itself.
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('tx_entries');
      await txn.delete('recurring_transactions');
      await txn.delete('budgets');
      await txn.delete('savings_goals');
      await txn.delete('categories');
      await txn.delete('wallets');
    });
  }
}
