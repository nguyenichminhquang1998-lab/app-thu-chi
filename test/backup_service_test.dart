import 'dart:convert';

import 'package:app_thu_chi/models/category.dart';
import 'package:app_thu_chi/models/transaction_entry.dart';
import 'package:app_thu_chi/models/wallet.dart';
import 'package:app_thu_chi/services/backup_service.dart';
import 'package:app_thu_chi/utils/id_generator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'test_support.dart';

/// Exercises "Sao lưu dữ liệu" / "Khôi phục dữ liệu" against a real (FFI)
/// SQLite database instead of a mock, so this actually proves round-trip
/// restore integrity and the new export formats produce readable output —
/// not just that the code compiles.
void main() {
  setUpAll(() {
    initTestDatabaseFactory();
    PathProviderPlatform.instance = FakePathProviderPlatform();
  });

  setUp(resetTestDatabase);

  Future<(Wallet, Category, TxEntry)> seedSampleData() async {
    final backup = BackupService();
    final wallet = Wallet(
      id: newId(),
      name: 'Ví thử nghiệm',
      kind: WalletKind.cash,
      color: 0xFF4CAF50,
      currency: 'VND',
      initialBalance: 500000,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await backup.walletRepository.insert(wallet);

    const category = Category(
      id: 'cat-test',
      name: 'Ăn uống',
      type: CategoryType.expense,
      iconKey: 'food',
      color: 0xFFFF7043,
      priority: CategoryPriority.essential,
    );
    await backup.categoryRepository.insert(category);

    final tx = TxEntry(
      id: newId(),
      type: TxType.expense,
      amount: 45000,
      currency: 'VND',
      walletId: wallet.id,
      categoryId: category.id,
      date: DateTime.now().millisecondsSinceEpoch,
      note: 'Ăn trưa',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await backup.transactionRepository.insert(tx);

    return (wallet, category, tx);
  }

  test('JSON backup round-trips exactly through restore', () async {
    final backup = BackupService();
    final (wallet, category, tx) = await seedSampleData();

    final file = await backup.buildJsonBackup();
    expect(file.bytes, isNotEmpty);
    expect(file.name, endsWith('.json'));
    expect(file.mimeType, 'application/json');

    // Wipe everything, then restore from the bytes we just produced — this is
    // exactly what "Khôi phục dữ liệu" does after picking a file, on both
    // native and web.
    await backup.restoreFromBytes(file.bytes);

    final wallets = await backup.walletRepository.getAll();
    final categories = await backup.categoryRepository.getAll();
    final transactions = await backup.transactionRepository.getAll();

    expect(wallets, hasLength(1));
    expect(wallets.single.name, wallet.name);
    expect(wallets.single.initialBalance, wallet.initialBalance);

    expect(categories, hasLength(1));
    expect(categories.single.name, category.name);
    expect(categories.single.priority, CategoryPriority.essential);

    expect(transactions, hasLength(1));
    expect(transactions.single.amount, tx.amount);
    expect(transactions.single.note, 'Ăn trưa');
  });

  test('CSV export contains every table with real data', () async {
    final backup = BackupService();
    await seedSampleData();

    final content = utf8.decode((await backup.buildCsvExport()).bytes);

    expect(content, contains('Ví'));
    expect(content, contains('Danh mục'));
    expect(content, contains('Giao dịch'));
    expect(content, contains('Ví thử nghiệm'));
    expect(content, contains('Ăn uống'));
    expect(content, contains('45000'));
  });

  test('Markdown export renders valid tables with real data', () async {
    final backup = BackupService();
    await seedSampleData();

    final content = utf8.decode((await backup.buildMarkdownExport()).bytes);

    expect(content, contains('# Dữ liệu Thu Chi'));
    expect(content, contains('## Ví'));
    expect(content, contains('| --- |'));
    expect(content, contains('Ví thử nghiệm'));
    expect(content, contains('Ăn trưa'));
  });

  test('restoring replaces old data rather than appending to it', () async {
    final backup = BackupService();
    await seedSampleData();
    final firstExport = await backup.buildJsonBackup();

    // Add a second, different wallet before restoring the first snapshot.
    await backup.walletRepository.insert(Wallet(
      id: newId(),
      name: 'Ví thứ hai',
      kind: WalletKind.bank,
      color: 0xFF1E88E5,
      currency: 'VND',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    expect(await backup.walletRepository.getAll(), hasLength(2));

    await backup.restoreFromBytes(firstExport.bytes);

    final wallets = await backup.walletRepository.getAll();
    expect(wallets, hasLength(1), reason: 'restore should wipe data added after the backup, not merge it');
    expect(wallets.single.name, 'Ví thử nghiệm');
  });
}
