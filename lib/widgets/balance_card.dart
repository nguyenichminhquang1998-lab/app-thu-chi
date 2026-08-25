import 'package:flutter/material.dart';

import '../utils/formatters.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;
  final bool hidden;
  final VoidCallback onToggleHidden;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
    required this.hidden,
    required this.onToggleHidden,
  });

  String _mask(String value) => hidden ? '••••••••' : value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Số dư', style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.85))),
              const SizedBox(width: 6),
              InkWell(
                onTap: onToggleHidden,
                child: Icon(
                  hidden ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: scheme.onPrimary.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _mask(formatCurrency(balance, withSign: true)),
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  label: 'Chi tiêu',
                  value: _mask(formatCurrency(-expense)),
                  color: scheme.onPrimary,
                ),
              ),
              Expanded(
                child: _StatColumn(
                  label: 'Thu nhập',
                  value: _mask(formatCurrency(income, withSign: true)),
                  color: scheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color.withValues(alpha: 0.85), fontSize: 13)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
