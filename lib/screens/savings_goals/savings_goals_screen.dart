import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/savings_goal.dart';
import '../../state/app_state.dart';
import '../../utils/color_palette.dart';
import '../../utils/formatters.dart';
import '../../utils/icon_catalog.dart';
import '../../utils/id_generator.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/thousands_input_formatter.dart';

class SavingsGoalsScreen extends StatelessWidget {
  const SavingsGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mục tiêu tiết kiệm'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _openEditor(context, appState)),
        ],
      ),
      body: appState.savingsGoals.isEmpty
          ? const Center(child: Text('Chưa có mục tiêu tiết kiệm nào'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appState.savingsGoals.length,
              itemBuilder: (context, index) {
                final goal = appState.savingsGoals[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CategoryIconAvatar(iconKey: goal.iconKey, color: goal.color),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(goal.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    '${formatCurrency(goal.currentAmount)} / ${formatCurrency(goal.targetAmount)}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') _openEditor(context, appState, existing: goal);
                                if (value == 'delete') appState.deleteSavingsGoal(goal.id);
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'edit', child: Text('Sửa')),
                                PopupMenuItem(value: 'delete', child: Text('Xoá')),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: goal.progress.toDouble(),
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation(Color(goal.color)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              goal.achieved ? 'Đã đạt mục tiêu 🎉' : '${(goal.progress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(color: goal.achieved ? Colors.green : Colors.grey.shade700),
                            ),
                            TextButton(
                              onPressed: () => _contribute(context, appState, goal),
                              child: const Text('Nạp tiền'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _contribute(BuildContext context, AppState appState, SavingsGoal goal) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nạp tiền vào "${goal.name}"'),
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
            child: const Text('Nạp'),
          ),
        ],
      ),
    );
    if (amount != null && amount > 0) {
      await appState.contributeToGoal(goal.id, amount);
    }
  }

  Future<void> _openEditor(BuildContext context, AppState appState, {SavingsGoal? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final targetController = TextEditingController(
      text: existing != null ? formatAmount(existing.targetAmount) : '',
    );
    String iconKey = existing?.iconKey ?? IconCatalog.goalKeys.first;
    int color = existing?.color ?? categoryColorPalette.first;

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
              Text(existing == null ? 'Mục tiêu mới' : 'Sửa mục tiêu', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên mục tiêu')),
              const SizedBox(height: 8),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsInputFormatter()],
                decoration: const InputDecoration(labelText: 'Số tiền mục tiêu', suffixText: '₫'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final key in IconCatalog.goalKeys)
                    InkWell(
                      onTap: () => setState(() => iconKey = key),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: key == iconKey ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
                        ),
                        child: CategoryIconAvatar(iconKey: key, color: color, size: 36),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final target = ThousandsInputFormatter.parse(targetController.text);
                  if (name.isEmpty || target <= 0) return;
                  if (existing == null) {
                    await appState.addSavingsGoal(SavingsGoal(
                      id: newId(),
                      name: name,
                      targetAmount: target,
                      iconKey: iconKey,
                      color: color,
                      createdAt: DateTime.now().millisecondsSinceEpoch,
                    ));
                  } else {
                    await appState.updateSavingsGoal(existing.copyWith(
                      name: name,
                      targetAmount: target,
                      iconKey: iconKey,
                      color: color,
                    ));
                  }
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
