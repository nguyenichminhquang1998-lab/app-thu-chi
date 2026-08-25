import 'package:app_thu_chi/models/category.dart';
import 'package:app_thu_chi/models/transaction_entry.dart';
import 'package:app_thu_chi/models/wallet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Category round-trips through toMap/fromMap', () {
    const category = Category(
      id: 'c1',
      name: 'Ăn uống',
      type: CategoryType.expense,
      iconKey: 'food',
      color: 0xFFFF0000,
      priority: CategoryPriority.essential,
      sortOrder: 2,
    );
    final restored = Category.fromMap(category.toMap());
    expect(restored.id, category.id);
    expect(restored.name, category.name);
    expect(restored.type, category.type);
    expect(restored.priority, category.priority);
  });

  test('Category with null priority round-trips', () {
    const category = Category(
      id: 'c2',
      name: 'Khác',
      type: CategoryType.income,
      iconKey: 'other_income',
      color: 0xFF00FF00,
    );
    final restored = Category.fromMap(category.toMap());
    expect(restored.priority, isNull);
  });

  test('Wallet round-trips through toMap/fromMap', () {
    final wallet = Wallet(
      id: 'w1',
      name: 'Tiền mặt',
      kind: WalletKind.cash,
      color: 0xFF00FF00,
      currency: 'VND',
      initialBalance: 1000,
      createdAt: 1000000,
    );
    final restored = Wallet.fromMap(wallet.toMap());
    expect(restored.name, wallet.name);
    expect(restored.kind, wallet.kind);
    expect(restored.initialBalance, wallet.initialBalance);
  });

  test('TxEntry signedAmount reflects type', () {
    final expense = TxEntry(
      id: 't1',
      type: TxType.expense,
      amount: 50000,
      currency: 'VND',
      walletId: 'w1',
      date: 0,
      createdAt: 0,
    );
    final income = expense.copyWith(type: TxType.income);
    expect(expense.signedAmount, -50000);
    expect(income.signedAmount, 50000);
  });

  test('TxEntry round-trips through toMap/fromMap', () {
    final tx = TxEntry(
      id: 't2',
      type: TxType.transfer,
      amount: 20000,
      currency: 'VND',
      walletId: 'w1',
      toWalletId: 'w2',
      date: 123456,
      note: 'test',
      tag: 'trip',
      createdAt: 999,
    );
    final restored = TxEntry.fromMap(tx.toMap());
    expect(restored.toWalletId, 'w2');
    expect(restored.tag, 'trip');
    expect(restored.type, TxType.transfer);
  });
}
