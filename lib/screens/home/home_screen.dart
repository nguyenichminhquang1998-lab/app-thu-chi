import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction_entry.dart';
import '../../state/app_state.dart';
import '../../state/settings_state.dart';
import '../../utils/formatters.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/period_selector.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/web_storage_notice.dart';
import '../add_transaction/add_transaction_screen.dart';
import '../search/search_screen.dart';
import '../transaction_detail/transaction_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final settings = context.watch<SettingsState>();
    final grouped = appState.transactionsGroupedByDay;
    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: appState.reloadAll,
        child: CustomScrollView(
          slivers: [
            // Web-only: warns when browser storage is at risk. Renders
            // nothing at all on native.
            const SliverToBoxAdapter(child: WebStorageNotice()),
            SliverToBoxAdapter(
              child: BalanceCard(
                balance: appState.totalBalance,
                income: appState.totalIncomeInRange,
                expense: appState.totalExpenseInRange,
                hidden: settings.balanceHidden,
                onToggleHidden: () => settings.setBalanceHidden(!settings.balanceHidden),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: PeriodSelector(
                  range: appState.selectedRange,
                  onPrevious: () => appState.shiftRange(-1),
                  onNext: () => appState.shiftRange(1),
                ),
              ),
            ),
            if (days.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              )
            else
              for (final day in days) ...[
                SliverToBoxAdapter(child: _DayHeader(day: day, transactions: grouped[day]!)),
                SliverList.builder(
                  itemCount: grouped[day]!.length,
                  itemBuilder: (context, index) {
                    final tx = grouped[day]![index];
                    return TransactionTile(
                      transaction: tx,
                      category: appState.categoryById(tx.categoryId),
                      wallet: appState.walletById(tx.walletId),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TransactionDetailScreen(transaction: tx),
                        ),
                      ),
                    );
                  },
                ),
              ],
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime day;
  final List<TxEntry> transactions;

  const _DayHeader({required this.day, required this.transactions});

  @override
  Widget build(BuildContext context) {
    double income = 0;
    double expense = 0;
    for (final tx in transactions) {
      if (tx.type == TxType.income) income += tx.amount;
      if (tx.type == TxType.expense) expense += tx.amount;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'ngày ${day.day} thg ${day.month}, ${day.year}',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          Text(
            [
              if (income > 0) 'Thu nhập: ${formatCurrency(income, withSign: true)}',
              if (expense > 0) 'Chi tiêu: ${formatCurrency(-expense)}',
            ].join('  '),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('Chưa có giao dịch nào trong kỳ này'),
            const SizedBox(height: 4),
            Text(
              'Nhấn nút + để thêm giao dịch đầu tiên',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
