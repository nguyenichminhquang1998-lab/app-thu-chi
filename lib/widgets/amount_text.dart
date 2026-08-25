import 'package:flutter/material.dart';

import '../models/transaction_entry.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class AmountText extends StatelessWidget {
  final double amount;
  final TxType type;
  final String currency;
  final TextStyle? style;

  const AmountText({
    super.key,
    required this.amount,
    required this.type,
    this.currency = 'VND',
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = type == TxType.expense;
    final color = switch (type) {
      TxType.expense => AppColors.expense,
      TxType.income => AppColors.income,
      TxType.transfer => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    final sign = type == TxType.transfer ? '' : (isExpense ? '-' : '+');
    return Text(
      '$sign${formatCurrency(amount, currency: currency)}',
      style: (style ?? const TextStyle(fontWeight: FontWeight.w600)).copyWith(color: color),
    );
  }
}
