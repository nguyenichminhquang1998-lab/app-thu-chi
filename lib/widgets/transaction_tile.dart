import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/transaction_entry.dart';
import '../models/wallet.dart';
import 'amount_text.dart';
import 'category_icon.dart';

class TransactionTile extends StatelessWidget {
  final TxEntry transaction;
  final Category? category;
  final Wallet? wallet;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    required this.wallet,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTransfer = transaction.type == TxType.transfer;
    return ListTile(
      onTap: onTap,
      leading: isTransfer
          ? const CircleAvatar(child: Icon(Icons.swap_horiz))
          : CategoryIconAvatar(
              iconKey: category?.iconKey ?? 'other_expense',
              color: category?.color ?? 0xFF9E9E9E,
            ),
      title: Text(
        isTransfer ? 'Chuyển ví' : (category?.name ?? 'Không phân loại'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          if (transaction.note.isNotEmpty) transaction.note,
          if (wallet != null) wallet!.name,
          if (transaction.tag != null) transaction.tag!,
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: AmountText(amount: transaction.amount, type: transaction.type, currency: transaction.currency),
    );
  }
}

/// Small reusable helper for screens that render a category's icon without
/// the full tile (e.g. picker grids).
Widget categoryGridTile({
  required BuildContext context,
  required String label,
  required String iconKey,
  required int color,
  required bool selected,
  required VoidCallback onTap,
}) {
  final scheme = Theme.of(context).colorScheme;
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: selected ? Border.all(color: scheme.primary, width: 2) : null,
          ),
          child: CategoryIconAvatar(iconKey: iconKey, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}
