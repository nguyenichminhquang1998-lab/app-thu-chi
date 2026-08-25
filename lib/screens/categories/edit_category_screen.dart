import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../state/app_state.dart';
import '../../utils/color_palette.dart';
import '../../utils/icon_catalog.dart';
import '../../utils/id_generator.dart';
import '../../widgets/category_icon.dart';

class EditCategoryScreen extends StatefulWidget {
  final CategoryType type;
  final Category? existing;

  const EditCategoryScreen({super.key, required this.type, this.existing});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  late final TextEditingController _nameController;
  late String _iconKey;
  late int _color;
  CategoryPriority? _priority;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _iconKey = existing?.iconKey ??
        (widget.type == CategoryType.expense
            ? IconCatalog.expenseKeys.first
            : IconCatalog.incomeKeys.first);
    _color = existing?.color ?? categoryColorPalette.first;
    _priority = existing?.priority;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final iconKeys = widget.type == CategoryType.expense ? IconCatalog.expenseKeys : IconCatalog.incomeKeys;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Thêm danh mục' : 'Sửa danh mục'),
        actions: [
          TextButton(
            onPressed: () => _save(context, appState),
            child: const Text('Lưu'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: CategoryIconAvatar(iconKey: _iconKey, color: _color, size: 64)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Tên danh mục'),
          ),
          const SizedBox(height: 20),
          const Text('Biểu tượng', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final key in iconKeys)
                InkWell(
                  onTap: () => setState(() => _iconKey = key),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: key == _iconKey
                          ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                          : null,
                    ),
                    child: CategoryIconAvatar(iconKey: key, color: _color, size: 40),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Màu sắc', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final color in categoryColorPalette)
                InkWell(
                  onTap: () => setState(() => _color = color),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(color),
                    child: color == _color ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                  ),
                ),
            ],
          ),
          if (widget.type == CategoryType.expense) ...[
            const SizedBox(height: 20),
            const Text('Mức độ ưu tiên', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Giúp bạn tự đánh giá thói quen chi tiêu: khoản nào cần thiết, chỉ là mong muốn, hay nên loại bỏ.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Cần thiết'),
                  selected: _priority == CategoryPriority.essential,
                  onSelected: (_) => setState(() => _priority = CategoryPriority.essential),
                ),
                ChoiceChip(
                  label: const Text('Mong muốn'),
                  selected: _priority == CategoryPriority.want,
                  onSelected: (_) => setState(() => _priority = CategoryPriority.want),
                ),
                ChoiceChip(
                  label: const Text('Loại bỏ'),
                  selected: _priority == CategoryPriority.eliminate,
                  onSelected: (_) => setState(() => _priority = CategoryPriority.eliminate),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context, AppState appState) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên danh mục')),
      );
      return;
    }
    if (widget.existing == null) {
      await appState.addCategory(Category(
        id: newId(),
        name: name,
        type: widget.type,
        iconKey: _iconKey,
        color: _color,
        priority: _priority,
        sortOrder: appState.categories.length,
      ));
    } else {
      await appState.updateCategory(widget.existing!.copyWith(
        name: name,
        iconKey: _iconKey,
        color: _color,
        priority: _priority,
        clearPriority: _priority == null,
      ));
    }
    if (context.mounted) Navigator.of(context).pop();
  }
}
