import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/recurring_transaction.dart';
import '../../models/transaction_entry.dart';
import '../../models/wallet.dart';
import '../../state/app_state.dart';
import '../../utils/formatters.dart';
import '../../utils/icon_catalog.dart';
import '../../utils/id_generator.dart';
import '../../widgets/thousands_input_formatter.dart';
import '../../widgets/voice_input_button.dart';
import 'category_picker_sheet.dart';

class AddTransactionScreen extends StatefulWidget {
  final TxEntry? existing;

  const AddTransactionScreen({super.key, this.existing});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late TxType _type;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _tagController = TextEditingController();
  Category? _category;
  Wallet? _wallet;
  DateTime _date = DateTime.now();
  String? _photoPath;
  bool _isRecurring = false;
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _type = existing?.type == TxType.transfer ? TxType.expense : (existing?.type ?? TxType.expense);
    if (existing != null) {
      _amountController.text = formatAmount(existing.amount);
      _noteController.text = existing.note;
      _tagController.text = existing.tag ?? '';
      _date = DateTime.fromMillisecondsSinceEpoch(existing.date);
      _photoPath = existing.photoPath;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // Resolve default wallet/category once data is available.
    _wallet ??= widget.existing != null
        ? appState.walletById(widget.existing!.walletId)
        : (appState.wallets.isNotEmpty ? appState.wallets.first : null);
    if (_category == null && widget.existing?.categoryId != null) {
      _category = appState.categoryById(widget.existing!.categoryId);
    }

    final expenseCategories = appState.categories.where((c) => c.type == CategoryType.expense).toList();
    final incomeCategories = appState.categories.where((c) => c.type == CategoryType.income).toList();
    final currentTypeCategories = _type == TxType.expense ? expenseCategories : incomeCategories;
    if (_category != null && _category!.type != _type.asCategoryType) {
      _category = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa giao dịch' : 'Thêm giao dịch'),
        actions: [
          TextButton(
            onPressed: () => _save(context, appState),
            child: const Text('Lưu'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<TxType>(
              segments: const [
                ButtonSegment(value: TxType.expense, label: Text('Chi tiêu')),
                ButtonSegment(value: TxType.income, label: Text('Thu nhập')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsInputFormatter()],
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: InputBorder.none,
                filled: false,
                hintText: '0',
                suffixText: '₫',
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _category == null
                  ? const CircleAvatar(child: Icon(Icons.category_outlined))
                  : CircleAvatar(
                      backgroundColor: Color(_category!.color).withValues(alpha: 0.15),
                      child: Icon(IconCatalog.iconFor(_category!.iconKey), color: Color(_category!.color)),
                    ),
              title: Text(_category?.name ?? 'Chọn danh mục'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final selected = await showCategoryPicker(
                  context,
                  expenseCategories: expenseCategories,
                  incomeCategories: incomeCategories,
                  initialType: _type.asCategoryType ?? CategoryType.expense,
                );
                if (selected != null) {
                  setState(() {
                    _category = selected;
                    _type = selected.type == CategoryType.expense ? TxType.expense : TxType.income;
                  });
                }
              },
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: Text(_wallet?.name ?? 'Chọn ví'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickWallet(context, appState.wallets),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text('${formatDate(_date)}  ${formatTime(_date)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickDateTime(context),
            ),
            const Divider(height: 1),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Ghi chú',
                border: InputBorder.none,
                suffixIcon: VoiceInputButton(
                  onResult: (text) => _noteController.text = text,
                ),
              ),
            ),
            TextField(
              controller: _tagController,
              decoration: const InputDecoration(
                labelText: 'Chủ đề (tuỳ chọn)',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.sell_outlined),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickReceiptPhoto,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(_photoPath == null ? 'Đính kèm hoá đơn' : 'Đã đính kèm ảnh'),
                  ),
                ),
                if (_photoPath != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _photoPath = null),
                  ),
              ],
            ),
            if (currentTypeCategories.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Chưa có danh mục ${_type == TxType.expense ? 'chi tiêu' : 'thu nhập'} nào. Hãy tạo trong mục Danh mục.',
                  style: const TextStyle(color: Colors.orange),
                ),
              ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Giao dịch định kỳ'),
              subtitle: const Text('Tự động lặp lại giao dịch này'),
              value: _isRecurring,
              onChanged: (v) => setState(() => _isRecurring = v),
            ),
            if (_isRecurring)
              DropdownButtonFormField<RecurrenceFrequency>(
                initialValue: _frequency,
                decoration: const InputDecoration(labelText: 'Tần suất lặp lại'),
                items: const [
                  DropdownMenuItem(value: RecurrenceFrequency.daily, child: Text('Hằng ngày')),
                  DropdownMenuItem(value: RecurrenceFrequency.weekly, child: Text('Hằng tuần')),
                  DropdownMenuItem(value: RecurrenceFrequency.monthly, child: Text('Hằng tháng')),
                  DropdownMenuItem(value: RecurrenceFrequency.yearly, child: Text('Hằng năm')),
                ],
                onChanged: (v) => setState(() => _frequency = v ?? RecurrenceFrequency.monthly),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickWallet(BuildContext context, List<Wallet> wallets) async {
    final selected = await showModalBottomSheet<Wallet>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final w in wallets)
              ListTile(
                leading: Icon(IconCatalog.iconFor(_walletIconKey(w.kind)), color: Color(w.color)),
                title: Text(w.name),
                onTap: () => Navigator.of(context).pop(w),
              ),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _wallet = selected);
  }

  String _walletIconKey(WalletKind kind) => switch (kind) {
        WalletKind.cash => 'cash',
        WalletKind.bank => 'bank',
        WalletKind.card => 'card',
        WalletKind.eWallet => 'ewallet',
        WalletKind.other => 'wallet_other',
      };

  Future<void> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
    if (time == null) return;
    setState(() {
      _date = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickReceiptPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'receipt_${newId()}.jpg';
    final saved = await File(picked.path).copy('${dir.path}/$fileName');
    setState(() => _photoPath = saved.path);
  }

  Future<void> _save(BuildContext context, AppState appState) async {
    final amount = ThousandsInputFormatter.parse(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
      );
      return;
    }
    if (_wallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ví')),
      );
      return;
    }

    final now = DateTime.now();
    if (_isEditing) {
      final updated = widget.existing!.copyWith(
        type: _type,
        amount: amount,
        walletId: _wallet!.id,
        categoryId: _category?.id,
        date: _date.millisecondsSinceEpoch,
        note: _noteController.text.trim(),
        tag: _tagController.text.trim().isEmpty ? null : _tagController.text.trim(),
        photoPath: _photoPath,
      );
      await appState.updateTransaction(updated);
    } else {
      String? recurringId;
      if (_isRecurring) {
        final recurring = RecurringTransaction(
          id: newId(),
          type: _type,
          amount: amount,
          currency: _wallet!.currency,
          walletId: _wallet!.id,
          categoryId: _category?.id,
          note: _noteController.text.trim(),
          frequency: _frequency,
          startDate: _date.millisecondsSinceEpoch,
          nextDueDate: DateTime.now()
              .add(const Duration(days: 1))
              .millisecondsSinceEpoch, // placeholder, corrected below
        );
        final nextDue = recurring.computeNextDueDate(_date);
        final corrected = recurring.copyWith(nextDueDate: nextDue.millisecondsSinceEpoch);
        await appState.addRecurring(corrected);
        recurringId = corrected.id;
      }
      final entry = TxEntry(
        id: newId(),
        type: _type,
        amount: amount,
        currency: _wallet!.currency,
        walletId: _wallet!.id,
        categoryId: _category?.id,
        date: _date.millisecondsSinceEpoch,
        note: _noteController.text.trim(),
        tag: _tagController.text.trim().isEmpty ? null : _tagController.text.trim(),
        photoPath: _photoPath,
        recurringId: recurringId,
        createdAt: now.millisecondsSinceEpoch,
      );
      await appState.addTransaction(entry);
    }
    if (context.mounted) Navigator.of(context).pop();
  }
}
