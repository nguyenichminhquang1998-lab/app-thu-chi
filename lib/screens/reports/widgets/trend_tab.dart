import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../models/transaction_entry.dart';
import '../../../utils/formatters.dart';

class TrendTab extends StatelessWidget {
  final List<TxEntry> transactions;
  final DateTime start;
  final DateTime end;

  const TrendTab({super.key, required this.transactions, required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    final days = end.difference(start).inDays + 1;
    final dailyIncome = List<double>.filled(days, 0);
    final dailyExpense = List<double>.filled(days, 0);
    for (final tx in transactions) {
      final d = DateTime.fromMillisecondsSinceEpoch(tx.date);
      final index = DateTime(d.year, d.month, d.day).difference(DateTime(start.year, start.month, start.day)).inDays;
      if (index < 0 || index >= days) continue;
      if (tx.type == TxType.income) dailyIncome[index] += tx.amount;
      if (tx.type == TxType.expense) dailyExpense[index] += tx.amount;
    }
    final totalIncome = dailyIncome.fold<double>(0, (a, b) => a + b);
    final totalExpense = dailyExpense.fold<double>(0, (a, b) => a + b);
    final maxY = [...dailyIncome, ...dailyExpense].fold<double>(0, (a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          height: 220,
          child: maxY == 0
              ? const Center(child: Text('Chưa có dữ liệu trong kỳ này'))
              : LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxY * 1.2,
                    gridData: const FlGridData(show: true, drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          interval: (days / 6).clamp(1, days).toDouble(),
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= days) return const SizedBox.shrink();
                            final date = start.add(Duration(days: index));
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(formatDateShort(date), style: const TextStyle(fontSize: 10)),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        spots: [for (var i = 0; i < days; i++) FlSpot(i.toDouble(), dailyIncome[i])],
                      ),
                      LineChartBarData(
                        isCurved: true,
                        color: Colors.red,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        spots: [for (var i = 0; i < days; i++) FlSpot(i.toDouble(), dailyExpense[i])],
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: Colors.green, label: 'Thu nhập'),
            SizedBox(width: 16),
            _LegendDot(color: Colors.red, label: 'Chi tiêu'),
          ],
        ),
        const SizedBox(height: 16),
        _SummaryRow(
          label: 'T.bình / ngày',
          expense: totalExpense / days,
          income: totalIncome / days,
          balance: (totalIncome - totalExpense) / days,
          bold: true,
        ),
        const Divider(),
        for (var i = days - 1; i >= 0; i--)
          if (dailyIncome[i] != 0 || dailyExpense[i] != 0)
            _SummaryRow(
              label: formatDateShort(start.add(Duration(days: i))),
              expense: dailyExpense[i],
              income: dailyIncome[i],
              balance: dailyIncome[i] - dailyExpense[i],
            ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double expense;
  final double income;
  final double balance;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.expense,
    required this.income,
    required this.balance,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: 13);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: style)),
          Expanded(flex: 2, child: Text(formatCurrency(-expense), style: style.copyWith(color: Colors.red))),
          Expanded(flex: 2, child: Text(formatCurrency(income, withSign: true), style: style.copyWith(color: Colors.green))),
          Expanded(flex: 2, child: Text(formatCurrency(balance, withSign: true), style: style)),
        ],
      ),
    );
  }
}
