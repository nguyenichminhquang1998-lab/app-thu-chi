import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction_entry.dart';
import '../../state/app_state.dart';
import '../../utils/formatters.dart';
import '../../utils/icon_catalog.dart';
import '../../widgets/amount_text.dart';
import '../add_transaction/add_transaction_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  final TxEntry transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final category = appState.categoryById(transaction.categoryId);
    final wallet = appState.walletById(transaction.walletId);
    final toWallet = appState.walletById(transaction.toWalletId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết giao dịch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AddTransactionScreen(existing: transaction)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, appState),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Color(category?.color ?? 0xFF9E9E9E).withValues(alpha: 0.15),
                  child: Icon(
                    IconCatalog.iconFor(category?.iconKey ?? 'other_expense'),
                    color: Color(category?.color ?? 0xFF9E9E9E),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                AmountText(
                  amount: transaction.amount,
                  type: transaction.type,
                  currency: transaction.currency,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _InfoRow(label: 'Danh mục', value: category?.name ?? '—'),
          _InfoRow(label: 'Ví', value: wallet?.name ?? '—'),
          if (toWallet != null) _InfoRow(label: 'Chuyển đến', value: toWallet.name),
          _InfoRow(
            label: 'Thời gian',
            value: '${formatDate(DateTime.fromMillisecondsSinceEpoch(transaction.date))} ${formatTime(DateTime.fromMillisecondsSinceEpoch(transaction.date))}',
          ),
          if (transaction.tag != null) _InfoRow(label: 'Chủ đề', value: transaction.tag!),
          if (transaction.note.isNotEmpty) _InfoRow(label: 'Ghi chú', value: transaction.note),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppState appState) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá giao dịch?'),
        content: const Text('Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Huỷ')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Xoá')),
        ],
      ),
    );
    if (confirmed == true) {
      await appState.deleteTransaction(transaction.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
