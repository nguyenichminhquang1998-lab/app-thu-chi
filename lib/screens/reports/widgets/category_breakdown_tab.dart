import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../models/category.dart';
import '../../../models/transaction_entry.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/category_icon.dart';

class CategoryBreakdownTab extends StatefulWidget {
  final List<TxEntry> transactions;
  final Category? Function(String? id) categoryOf;

  const CategoryBreakdownTab({super.key, required this.transactions, required this.categoryOf});

  @override
  State<CategoryBreakdownTab> createState() => _CategoryBreakdownTabState();
}

class _CategoryBreakdownTabState extends State<CategoryBreakdownTab> {
  TxType _type = TxType.expense;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.transactions.where((t) => t.type == _type).toList();
    final totals = <String, double>{};
    for (final tx in filtered) {
      final key = tx.categoryId ?? '';
      totals[key] = (totals[key] ?? 0) + tx.amount;
    }
    final total = totals.values.fold<double>(0, (a, b) => a + b);
    final entries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SegmentedButton<TxType>(
            segments: const [
              ButtonSegment(value: TxType.expense, label: Text('Chi tiêu')),
              ButtonSegment(value: TxType.income, label: Text('Thu nhập')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
        ),
        if (total == 0)
          const Expanded(child: Center(child: Text('Chưa có dữ liệu trong kỳ này')))
        else ...[
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 60,
                    sections: [
                      for (final e in entries)
                        PieChartSectionData(
                          value: e.value,
                          color: Color(widget.categoryOf(e.key.isEmpty ? null : e.key)?.color ?? 0xFF9E9E9E),
                          title: '${(e.value / total * 100).toStringAsFixed(0)}%',
                          radius: 45,
                          titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Tổng', style: TextStyle(color: Colors.grey.shade600)),
                    Text(formatCurrency(total), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final e = entries[index];
                final category = widget.categoryOf(e.key.isEmpty ? null : e.key);
                final percent = total == 0 ? 0.0 : e.value / total;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      CategoryIconAvatar(iconKey: category?.iconKey ?? 'other_expense', color: category?.color ?? 0xFF9E9E9E, size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(category?.name ?? 'Không phân loại', overflow: TextOverflow.ellipsis),
                                ),
                                Text('${(percent * 100).toStringAsFixed(1)}%'),
                                const SizedBox(width: 8),
                                Text(formatCurrency(e.value), style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percent,
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation(Color(category?.color ?? 0xFF9E9E9E)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
