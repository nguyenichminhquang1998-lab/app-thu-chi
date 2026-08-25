import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../state/app_state.dart';
import '../../state/settings_state.dart';
import '../../utils/formatters.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/thousands_input_formatter.dart';
import '../savings_goals/savings_goals_screen.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final settings = context.watch<SettingsState>();
    final expenseCategories = appState.categories.where((c) => c.type == CategoryType.expense).toList();
    final overallSpent = appState.spentForBudget(null);
    final overallBudget = appState.budgetForCategory(null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ngân sách'),
        actions: [
          IconButton(
            icon: const Icon(Icons.savings_outlined),
            tooltip: 'Mục tiêu tiết kiệm',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SavingsGoalsScreen()),
            ),
          ),
        ],
      ),
      body: !settings.budgetModeEnabled
          ? _DisabledState(onEnable: () => settings.setBudgetModeEnabled(true))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _BudgetTile(
                  title: 'Tổng chi tiêu tháng này',
                  icon: Icons.pie_chart_outline,
                  color: Theme.of(context).colorScheme.primary,
                  spent: overallSpent,
                  budget: overallBudget?.amount,
                  onTap: () => _editBudget(context, appState, null, overallBudget?.amount),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(),
                ),
                const Text('Ngân sách theo danh mục', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                for (final category in expenseCategories)
                  _BudgetTile(
                    title: category.name,
                    iconKey: category.iconKey,
                    color: Color(category.color),
                    spent: appState.spentForBudget(category.id),
                    budget: appState.budgetForCategory(category.id)?.amount,
                    onTap: () => _editBudget(
                      context,
                      appState,
                      category.id,
                      appState.budgetForCategory(category.id)?.amount,
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _editBudget(BuildContext context, AppState appState, String? categoryId, double? current) async {
    final controller = TextEditingController(text: current != null ? formatAmount(current) : '');
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đặt hạn mức ngân sách'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [ThousandsInputFormatter()],
          decoration: const InputDecoration(suffixText: '₫'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Huỷ')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(ThousandsInputFormatter.parse(controller.text)),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (result != null) {
      await appState.setBudget(categoryId, result);
    }
  }
}

class _BudgetTile extends StatelessWidget {
  final String title;
  final String? iconKey;
  final IconData? icon;
  final Color color;
  final double spent;
  final double? budget;
  final VoidCallback onTap;

  const _BudgetTile({
    required this.title,
    this.iconKey,
    this.icon,
    required this.color,
    required this.spent,
    required this.budget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasBudget = budget != null && budget! > 0;
    final percent = hasBudget ? (spent / budget!).clamp(0, 1.5) : 0.0;
    final overBudget = hasBudget && spent > budget!;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            iconKey != null
                ? CategoryIconAvatar(iconKey: iconKey!, color: color.toARGB32())
                : CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        hasBudget
                            ? '${formatCurrency(spent)} / ${formatCurrency(budget!)}'
                            : 'Chưa đặt hạn mức',
                        style: TextStyle(
                          fontSize: 12,
                          color: overBudget ? Colors.red : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: hasBudget ? percent.clamp(0, 1).toDouble() : 0,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(overBudget ? Colors.red : color),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisabledState extends StatelessWidget {
  final VoidCallback onEnable;
  const _DisabledState({required this.onEnable});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pie_chart_outline, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Chế độ ngân sách đang tắt'),
            const SizedBox(height: 12),
            FilledButton(onPressed: onEnable, child: const Text('Bật chế độ ngân sách')),
          ],
        ),
      ),
    );
  }
}
