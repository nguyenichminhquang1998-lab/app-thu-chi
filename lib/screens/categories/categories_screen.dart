import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../state/app_state.dart';
import '../../widgets/category_icon.dart';
import 'edit_category_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final expense = appState.categories.where((c) => c.type == CategoryType.expense).toList();
    final income = appState.categories.where((c) => c.type == CategoryType.income).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh mục'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Chi tiêu (${expense.length})'),
            Tab(text: 'Thu nhập (${income.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              final type = _tabController.index == 0 ? CategoryType.expense : CategoryType.income;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EditCategoryScreen(type: type)),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoryList(categories: expense, type: CategoryType.expense),
          _CategoryList(categories: income, type: CategoryType.income),
        ],
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<Category> categories;
  final CategoryType type;

  const _CategoryList({required this.categories, required this.type});

  String _priorityLabel(CategoryPriority? p) => switch (p) {
        CategoryPriority.essential => 'Cần thiết',
        CategoryPriority.want => 'Mong muốn',
        CategoryPriority.eliminate => 'Loại bỏ',
        null => '',
      };

  Color _priorityColor(CategoryPriority? p) => switch (p) {
        CategoryPriority.essential => Colors.green,
        CategoryPriority.want => Colors.orange,
        CategoryPriority.eliminate => Colors.red,
        null => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (categories.isEmpty) {
      return const Center(child: Text('Chưa có danh mục nào'));
    }
    return ReorderableListView.builder(
      itemCount: categories.length,
      onReorderItem: (oldIndex, newIndex) {
        final reordered = List<Category>.from(categories);
        final item = reordered.removeAt(oldIndex);
        reordered.insert(newIndex, item);
        appState.reorderCategories(reordered);
      },
      itemBuilder: (context, index) {
        final category = categories[index];
        return ListTile(
          key: ValueKey(category.id),
          leading: CategoryIconAvatar(iconKey: category.iconKey, color: category.color),
          title: Text(category.name),
          subtitle: category.priority != null
              ? Text(
                  _priorityLabel(category.priority),
                  style: TextStyle(color: _priorityColor(category.priority), fontSize: 12),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                onPressed: () => _confirmDelete(context, appState, category),
              ),
              const Icon(Icons.drag_handle),
            ],
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => EditCategoryScreen(type: type, existing: category)),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppState appState, Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xoá "${category.name}"?'),
        content: const Text(
          'Nếu danh mục đã có giao dịch, danh mục sẽ được ẩn thay vì xoá hẳn để giữ lịch sử.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Huỷ')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Xoá')),
        ],
      ),
    );
    if (confirmed == true) {
      await appState.deleteOrArchiveCategory(category);
    }
  }
}
