import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/wallet.dart';
import '../../state/app_state.dart';
import '../../utils/color_palette.dart';
import '../../utils/formatters.dart';
import '../../utils/icon_catalog.dart';
import '../../utils/id_generator.dart';
import '../../widgets/thousands_input_formatter.dart';

class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

  static const _kindLabels = {
    WalletKind.cash: 'Tiền mặt',
    WalletKind.bank: 'Ngân hàng',
    WalletKind.card: 'Thẻ tín dụng',
    WalletKind.eWallet: 'Ví điện tử',
    WalletKind.other: 'Khác',
  };

  static const _kindIcons = {
    WalletKind.cash: 'cash',
    WalletKind.bank: 'bank',
    WalletKind.card: 'card',
    WalletKind.eWallet: 'ewallet',
    WalletKind.other: 'wallet_other',
  };

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ví / Tài khoản'),
        actions: [
          if (appState.wallets.length > 1)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Chuyển tiền giữa các ví',
              onPressed: () => _openTransfer(context, appState),
            ),
          IconButton(icon: const Icon(Icons.add), onPressed: () => _openEditor(context, appState)),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appState.wallets.length,
        itemBuilder: (context, index) {
          final wallet = appState.wallets[index];
          final balance = appState.walletBalance(wallet);
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(wallet.color).withValues(alpha: 0.15),
                child: Icon(IconCatalog.iconFor(_kindIcons[wallet.kind]!), color: Color(wallet.color)),
              ),
              title: Text(wallet.name),
              subtitle: Text(_kindLabels[wallet.kind]!),
              trailing: Text(
                formatCurrency(balance, currency: wallet.currency),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () => _openEditor(context, appState, existing: wallet),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, AppState appState, {Wallet? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final initialBalanceController = TextEditingController(
      text: existing != null ? formatAmount(existing.initialBalance) : '0',
    );
    WalletKind kind = existing?.kind ?? WalletKind.cash;
    int color = existing?.color ?? categoryColorPalette.first;
    String currency = existing?.currency ?? 'VND';

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
              Text(existing == null ? 'Ví mới' : 'Sửa ví', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên ví')),
              const SizedBox(height: 8),
              DropdownButtonFormField<WalletKind>(
                initialValue: kind,
                decoration: const InputDecoration(labelText: 'Loại ví'),
                items: [
                  for (final k in WalletKind.values)
                    DropdownMenuItem(value: k, child: Text(_kindLabels[k]!)),
                ],
                onChanged: (v) => setState(() => kind = v ?? WalletKind.cash),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: initialBalanceController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsInputFormatter()],
                decoration: const InputDecoration(labelText: 'Số dư ban đầu', suffixText: '₫'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: currency,
                decoration: const InputDecoration(labelText: 'Đơn vị tiền tệ'),
                items: const [
                  DropdownMenuItem(value: 'VND', child: Text('VND')),
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  DropdownMenuItem(value: 'JPY', child: Text('JPY')),
                ],
                onChanged: (v) => setState(() => currency = v ?? 'VND'),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final c in categoryColorPalette)
                    InkWell(
                      onTap: () => setState(() => color = c),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(c),
                        child: c == color ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  final initialBalance = ThousandsInputFormatter.parse(initialBalanceController.text);
                  if (existing == null) {
                    await appState.addWallet(Wallet(
                      id: newId(),
                      name: name,
                      kind: kind,
                      color: color,
                      currency: currency,
                      initialBalance: initialBalance,
                      sortOrder: appState.wallets.length,
                      createdAt: DateTime.now().millisecondsSinceEpoch,
                    ));
                  } else {
                    await appState.updateWallet(existing.copyWith(
                      name: name,
                      kind: kind,
                      color: color,
                      currency: currency,
                      initialBalance: initialBalance,
                    ));
                  }
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Lưu'),
              ),
              if (existing != null)
                TextButton(
                  onPressed: () async {
                    await appState.archiveWallet(existing.id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Ẩn ví này', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTransfer(BuildContext context, AppState appState) async {
    Wallet from = appState.wallets.first;
    Wallet to = appState.wallets[1];
    final amountController = TextEditingController();
    final noteController = TextEditingController();

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
              const Text('Chuyển tiền giữa ví', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<Wallet>(
                initialValue: from,
                decoration: const InputDecoration(labelText: 'Từ ví'),
                items: [for (final w in appState.wallets) DropdownMenuItem(value: w, child: Text(w.name))],
                onChanged: (v) => setState(() => from = v ?? from),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Wallet>(
                initialValue: to,
                decoration: const InputDecoration(labelText: 'Đến ví'),
                items: [for (final w in appState.wallets) DropdownMenuItem(value: w, child: Text(w.name))],
                onChanged: (v) => setState(() => to = v ?? to),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsInputFormatter()],
                decoration: const InputDecoration(labelText: 'Số tiền', suffixText: '₫'),
              ),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Ghi chú (tuỳ chọn)'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final amount = ThousandsInputFormatter.parse(amountController.text);
                  if (amount <= 0 || from.id == to.id) return;
                  await appState.transferBetweenWallets(
                    fromWalletId: from.id,
                    toWalletId: to.id,
                    amount: amount,
                    currency: from.currency,
                    note: noteController.text.trim(),
                  );
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Chuyển tiền'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
