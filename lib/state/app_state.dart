import 'package:flutter/material.dart';

import '../data/repositories/budget_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/recurring_repository.dart';
import '../data/repositories/savings_goal_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/wallet_repository.dart';
import '../data/seed/default_data.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/recurring_transaction.dart';
import '../models/savings_goal.dart';
import '../models/transaction_entry.dart';
import '../models/wallet.dart';
import '../services/notification_service.dart';
import '../utils/date_range_utils.dart';
import '../utils/id_generator.dart';
import 'settings_state.dart';

/// Single source of truth for all financial data in memory. Screens read
/// from this via `context.watch<AppState>()` and mutate through its
/// methods, which persist to sqflite then refresh the in-memory caches.
class AppState extends ChangeNotifier {
  AppState({required this.settings})
      : walletRepository = WalletRepository(),
        categoryRepository = CategoryRepository(),
        transactionRepository = TransactionRepository(),
        budgetRepository = BudgetRepository(),
        recurringRepository = RecurringRepository(),
        savingsGoalRepository = SavingsGoalRepository(),
        selectedRange = currentMonthlyPeriod(1);

  final SettingsState settings;
  final WalletRepository walletRepository;
  final CategoryRepository categoryRepository;
  final TransactionRepository transactionRepository;
  final BudgetRepository budgetRepository;
  final RecurringRepository recurringRepository;
  final SavingsGoalRepository savingsGoalRepository;

  bool isLoading = true;
  List<Wallet> wallets = [];
  List<Category> categories = [];
  List<Budget> budgets = [];
  List<RecurringTransaction> recurringTransactions = [];
  List<SavingsGoal> savingsGoals = [];
  Map<String, double> _walletDeltas = {};

  DateRange selectedRange;
  List<TxEntry> transactionsInRange = [];

  Future<void> init() async {
    selectedRange = currentMonthlyPeriod(settings.monthStartDay);
    await DefaultDataSeeder(
      walletRepository: walletRepository,
      categoryRepository: categoryRepository,
    ).seedIfEmpty();
    await reloadAll();
    await processDueRecurring();
    isLoading = false;
    notifyListeners();
  }

  Future<void> reloadAll() async {
    wallets = await walletRepository.getAll();
    categories = await categoryRepository.getAll();
    budgets = await budgetRepository.getAll();
    recurringTransactions = await recurringRepository.getAll();
    savingsGoals = await savingsGoalRepository.getAll();
    _walletDeltas = await transactionRepository.walletDeltas();
    await _reloadTransactionsInRange();
    notifyListeners();
  }

  Future<void> _reloadTransactionsInRange() async {
    transactionsInRange = await transactionRepository.getInRange(
      selectedRange.start,
      selectedRange.end,
    );
  }

  Future<void> setRange(DateRange range) async {
    selectedRange = range;
    await _reloadTransactionsInRange();
    notifyListeners();
  }

  Future<void> shiftRange(int direction) async {
    await setRange(shiftPeriod(selectedRange, settings.monthStartDay, direction));
  }

  Future<void> resetToCurrentPeriod() async {
    await setRange(currentMonthlyPeriod(settings.monthStartDay));
  }

  // ---------------------------------------------------------------------
  // Derived data
  // ---------------------------------------------------------------------

  Category? categoryById(String? id) {
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Wallet? walletById(String? id) {
    if (id == null) return null;
    for (final w in wallets) {
      if (w.id == id) return w;
    }
    return null;
  }

  double walletBalance(Wallet wallet) =>
      wallet.initialBalance + (_walletDeltas[wallet.id] ?? 0);

  double get totalBalance => wallets.fold<double>(
        0,
        (sum, w) => sum + settings.convertToBase(walletBalance(w), w.currency),
      );

  double get totalIncomeInRange => transactionsInRange
      .where((t) => t.type == TxType.income)
      .fold<double>(0, (sum, t) => sum + settings.convertToBase(t.amount, t.currency));

  double get totalExpenseInRange => transactionsInRange
      .where((t) => t.type == TxType.expense)
      .fold<double>(0, (sum, t) => sum + settings.convertToBase(t.amount, t.currency));

  double get netInRange => totalIncomeInRange - totalExpenseInRange;

  Map<DateTime, List<TxEntry>> get transactionsGroupedByDay {
    final map = <DateTime, List<TxEntry>>{};
    for (final tx in transactionsInRange) {
      final d = DateTime.fromMillisecondsSinceEpoch(tx.date);
      final day = DateTime(d.year, d.month, d.day);
      (map[day] ??= []).add(tx);
    }
    return map;
  }

  /// Amount already spent this budget period for a category (or overall
  /// when [categoryId] is null).
  double spentForBudget(String? categoryId) {
    final txs = transactionsInRange.where((t) => t.type == TxType.expense);
    if (categoryId == null) {
      return txs.fold<double>(0, (s, t) => s + t.amount);
    }
    return txs
        .where((t) => t.categoryId == categoryId)
        .fold<double>(0, (s, t) => s + t.amount);
  }

  // ---------------------------------------------------------------------
  // Transactions
  // ---------------------------------------------------------------------

  Future<void> addTransaction(TxEntry entry) async {
    await transactionRepository.insert(entry);
    await reloadAll();
    if (entry.type == TxType.expense) await _checkBudgetAlert(entry.categoryId);
  }

  Future<void> updateTransaction(TxEntry entry) async {
    await transactionRepository.update(entry);
    await reloadAll();
    if (entry.type == TxType.expense) await _checkBudgetAlert(entry.categoryId);
  }

  /// Fires a local notification once a category (or the overall budget)
  /// crosses 90% or 100% of its monthly limit. Best-effort: silently no-ops
  /// when budget mode is off or no limit is configured for this category.
  Future<void> _checkBudgetAlert(String? categoryId) async {
    if (!settings.budgetModeEnabled) return;
    final budget = budgetForCategory(categoryId) ?? (categoryId == null ? null : budgetForCategory(null));
    final targetCategoryId = budgetForCategory(categoryId) != null ? categoryId : null;
    if (budget == null) return;
    final spent = spentForBudget(targetCategoryId);
    if (spent < budget.amount * 0.9) return;
    final categoryName = targetCategoryId == null ? 'Tổng chi tiêu' : (categoryById(targetCategoryId)?.name ?? '');
    await NotificationService.instance.showBudgetAlert(
      categoryName: categoryName,
      spent: spent,
      budget: budget.amount,
    );
  }

  Future<void> deleteTransaction(String id) async {
    await transactionRepository.delete(id);
    await reloadAll();
  }

  Future<List<TxEntry>> searchTransactions(String query) {
    return transactionRepository.search(query);
  }

  // ---------------------------------------------------------------------
  // Wallets
  // ---------------------------------------------------------------------

  Future<void> addWallet(Wallet wallet) async {
    await walletRepository.insert(wallet);
    await reloadAll();
  }

  Future<void> updateWallet(Wallet wallet) async {
    await walletRepository.update(wallet);
    await reloadAll();
  }

  Future<void> archiveWallet(String id) async {
    await walletRepository.archive(id);
    await reloadAll();
  }

  Future<void> transferBetweenWallets({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    required String currency,
    String note = '',
    DateTime? date,
  }) async {
    final entry = TxEntry(
      id: newId(),
      type: TxType.transfer,
      amount: amount,
      currency: currency,
      walletId: fromWalletId,
      toWalletId: toWalletId,
      date: (date ?? DateTime.now()).millisecondsSinceEpoch,
      note: note,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await addTransaction(entry);
  }

  // ---------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------

  Future<void> addCategory(Category category) async {
    await categoryRepository.insert(category);
    await reloadAll();
  }

  Future<void> updateCategory(Category category) async {
    await categoryRepository.update(category);
    await reloadAll();
  }

  /// Deletes a category outright if it has never been used; otherwise
  /// archives it so historical transactions keep their label.
  Future<void> deleteOrArchiveCategory(Category category) async {
    final usageCount = await categoryRepository.transactionCount(category.id);
    if (usageCount == 0) {
      await budgetRepository.deleteByCategory(category.id);
      await categoryRepository.delete(category.id);
    } else {
      await categoryRepository.update(category.copyWith(archived: true));
    }
    await reloadAll();
  }

  Future<void> reorderCategories(List<Category> ordered) async {
    await categoryRepository.reorder(ordered);
    await reloadAll();
  }

  int categoryTransactionCount(String categoryId) =>
      transactionsInRange.where((t) => t.categoryId == categoryId).length;

  // ---------------------------------------------------------------------
  // Budgets
  // ---------------------------------------------------------------------

  Budget? budgetForCategory(String? categoryId) {
    for (final b in budgets) {
      if (b.categoryId == categoryId) return b;
    }
    return null;
  }

  Future<void> setBudget(String? categoryId, double amount) async {
    final existing = budgetForCategory(categoryId);
    if (existing != null) {
      await budgetRepository.update(existing.copyWith(amount: amount));
    } else {
      await budgetRepository.upsert(Budget(
        id: newId(),
        categoryId: categoryId,
        amount: amount,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
    }
    await reloadAll();
  }

  Future<void> deleteBudget(String id) async {
    await budgetRepository.delete(id);
    await reloadAll();
  }

  // ---------------------------------------------------------------------
  // Recurring transactions
  // ---------------------------------------------------------------------

  Future<void> addRecurring(RecurringTransaction item) async {
    await recurringRepository.insert(item);
    await reloadAll();
  }

  Future<void> updateRecurring(RecurringTransaction item) async {
    await recurringRepository.update(item);
    await reloadAll();
  }

  Future<void> deleteRecurring(String id) async {
    await recurringRepository.delete(id);
    await reloadAll();
  }

  /// Generates concrete transactions for every recurring rule whose next
  /// due date has passed, then advances each rule. Capped per-rule so a
  /// rule left untouched for years can't hang the app on first launch.
  Future<void> processDueRecurring() async {
    final now = DateTime.now();
    final due = await recurringRepository.getDue(now);
    for (final rule in due) {
      var current = rule;
      var safety = 0;
      while (current.nextDueDate <= now.millisecondsSinceEpoch && safety < 240) {
        if (current.endDate != null && current.nextDueDate > current.endDate!) {
          current = current.copyWith(active: false);
          break;
        }
        final dueDate = DateTime.fromMillisecondsSinceEpoch(current.nextDueDate);
        await transactionRepository.insert(TxEntry(
          id: newId(),
          type: current.type,
          amount: current.amount,
          currency: current.currency,
          walletId: current.walletId,
          categoryId: current.categoryId,
          date: current.nextDueDate,
          note: current.note,
          recurringId: current.id,
          createdAt: now.millisecondsSinceEpoch,
        ));
        final next = current.computeNextDueDate(dueDate);
        current = current.copyWith(nextDueDate: next.millisecondsSinceEpoch);
        safety++;
      }
      await recurringRepository.update(current);
    }
  }

  // ---------------------------------------------------------------------
  // Savings goals
  // ---------------------------------------------------------------------

  Future<void> addSavingsGoal(SavingsGoal goal) async {
    await savingsGoalRepository.insert(goal);
    await reloadAll();
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    await savingsGoalRepository.update(goal);
    await reloadAll();
  }

  Future<void> contributeToGoal(String id, double amount) async {
    final goal = savingsGoals.firstWhere((g) => g.id == id);
    final newAmount = goal.currentAmount + amount;
    await savingsGoalRepository.update(goal.copyWith(
      currentAmount: newAmount,
      achieved: newAmount >= goal.targetAmount,
    ));
    await reloadAll();
  }

  Future<void> deleteSavingsGoal(String id) async {
    await savingsGoalRepository.delete(id);
    await reloadAll();
  }
}
