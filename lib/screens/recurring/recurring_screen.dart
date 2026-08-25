import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/recurring_transaction.dart';
import '../../models/transaction_entry.dart';
import '../../models/wallet.dart';
import '../../state/app_state.dart';
import '../../utils/formatters.dart';
import '../../utils/icon_catalog.dart';
import '../../utils/id_generator.dart';
import '../../widgets/amount_text.dart';
import '../../widgets/thousands_input_formatter.dart';
import '../add_transaction/category_picker_sheet.dart';

class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  static const _frequencyLabels = {
    RecurrenceFrequency.daily: 'Hằng ngày',
    RecurrenceFrequency.weekly: 'Hằng tuần',
    RecurrenceFrequency.monthly: 'Hằng tháng',
    RecurrenceFrequency.yearly: 'Hằng năm',
  };

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giao dịch định kỳ'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _openEditor(context, appState)),
        ],
      ),
      body: appState.recurringTransactions.isEmpty
          ? const Center(child: Text('Chưa có giao dịch định kỳ nào'))
          : ListView.builder(
              itemCount: appState.recurringTransactions.length,
              itemBuilder: (context, index) {
                final item = appState.recurringTransactions[index];
                final category = appState.categoryById(item.categoryId);
                final wallet = appState.walletById(item.walletId);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(category?.color ?? 0xFF9E9E9E).withValues(alpha: 0.15),
                    child: Icon(IconCatalog.iconFor(category?.iconKey ?? 'other_expense'), color: Color(category?.color ?? 0xFF9E9E9E)),
                  ),
                  title: Text(category?.name ?? (item.note.isEmpty ? 'Giao dịch định kỳ' : item.note)),
                  subtitle: Text(
                    '${_frequencyLabels[item.frequency]} · ${wallet?.name ?? ''} · Kế tiếp: ${formatDate(DateTime.fromMillisecondsSinceEpoch(item.nextDueDate))}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AmountText(amount: item.amount, type: item.type),
                      Switch(
                        value: item.active,
                        onChanged: (v) => appState.updateRecurring(item.copyWith(active: v)),
                      ),
                    ],
                  ),
                  onLongPress: () => _confirmDelete(context, appState, item),
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppState appState, RecurringTransaction item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá giao dịch định kỳ?'),
        content: const Text('Các giao dịch đã tạo trước đó sẽ không bị xoá.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Huỷ')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Xoá')),
        ],
      ),
    );
    if (confirmed == true) await appState.deleteRecurring(item.id);
  }

  Future<void> _openEditor(BuildContext context, AppState appState) async {
    TxType type = TxType.expense;
    Category? category;
    Wallet? wallet = appState.wallets.isNotEmpty ? appState.wallets.first : null;
    RecurrenceFrequency frequency = RecurrenceFrequency.monthly;
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    DateTime startDate = DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Giao dịch định kỳ mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SegmentedButton<TxType>(
                segments: const [
                  ButtonSegment(value: TxType.expense, label: Text('Chi tiêu')),
                  ButtonSegment(value: TxType.income, label: Text('Thu nhập')),
                ],
                selected: {type},
                onSelectionChanged: (s) => setState(() {
                  type = s.first;
                  category = null;
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsInputFormatter()],
                decoration: const InputDecoration(labelText: 'Số tiền', suffixText: '₫'),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(category?.name ?? 'Chọn danh mục'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final selected = await showCategoryPicker(
                    context,
                    expenseCategories: appState.categories.where((c) => c.type == CategoryType.expense).toList(),
                    incomeCategories: appState.categories.where((c) => c.type == CategoryType.income).toList(),
                    initialType: type.asCategoryType ?? CategoryType.expense,
                  );
                  if (selected != null) {
                    setState(() {
                      category = selected;
                      type = selected.type == CategoryType.expense ? TxType.expense : TxType.income;
                    });
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(wallet?.name ?? 'Chọn ví'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final selected = await showModalBottomSheet<Wallet>(
                    context: context,
                    builder: (context) => SafeArea(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final w in appState.wallets)
                            ListTile(title: Text(w.name), onTap: () => Navigator.of(context).pop(w)),
                        ],
                      ),
                    ),
                  );
                  if (selected != null) setState(() => wallet = selected);
                },
              ),
              DropdownButtonFormField<RecurrenceFrequency>(
                initialValue: frequency,
                decoration: const InputDecoration(labelText: 'Tần suất'),
                items: [
                  for (final f in RecurrenceFrequency.values)
                    DropdownMenuItem(value: f, child: Text(_frequencyLabels[f]!)),
                ],
                onChanged: (v) => setState(() => frequency = v ?? RecurrenceFrequency.monthly),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Bắt đầu từ: ${formatDate(startDate)}'),
                trailing: const Icon(Icons.event),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => startDate = picked);
                },
              ),
              TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Ghi chú')),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final amount = ThousandsInputFormatter.parse(amountController.text);
                  if (amount <= 0 || wallet == null) return;
                  final rule = RecurringTransaction(
                    id: newId(),
                    type: type,
                    amount: amount,
                    currency: wallet!.currency,
                    walletId: wallet!.id,
                    categoryId: category?.id,
                    note: noteController.text.trim(),
                    frequency: frequency,
                    startDate: startDate.millisecondsSinceEpoch,
                    nextDueDate: startDate.millisecondsSinceEpoch,
                  );
                  await appState.addRecurring(rule);
                  await appState.processDueRecurring();
                  await appState.reloadAll();
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Lưu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
