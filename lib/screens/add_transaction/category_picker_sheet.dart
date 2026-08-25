import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../widgets/transaction_tile.dart';

/// Bottom sheet matching the reference app's "Chọn" category picker:
/// two tabs (Chi tiêu / Thu nhập) with a grid of icon tiles.
Future<Category?> showCategoryPicker(
  BuildContext context, {
  required List<Category> expenseCategories,
  required List<Category> incomeCategories,
  required CategoryType initialType,
}) {
  return showModalBottomSheet<Category>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _CategoryPickerContent(
      expenseCategories: expenseCategories,
      incomeCategories: incomeCategories,
      initialType: initialType,
    ),
  );
}

class _CategoryPickerContent extends StatefulWidget {
  final List<Category> expenseCategories;
  final List<Category> incomeCategories;
  final CategoryType initialType;

  const _CategoryPickerContent({
    required this.expenseCategories,
    required this.incomeCategories,
    required this.initialType,
  });

  @override
  State<_CategoryPickerContent> createState() => _CategoryPickerContentState();
}

class _CategoryPickerContentState extends State<_CategoryPickerContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialType == CategoryType.expense ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Chọn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: const [Tab(text: 'Chi tiêu'), Tab(text: 'Thu nhập')],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CategoryGrid(categories: widget.expenseCategories, scrollController: scrollController),
                  _CategoryGrid(categories: widget.incomeCategories, scrollController: scrollController),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final ScrollController scrollController;

  const _CategoryGrid({required this.categories, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(child: Text('Chưa có danh mục nào'));
    }
    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return categoryGridTile(
          context: context,
          label: category.name,
          iconKey: category.iconKey,
          color: category.color,
          selected: false,
          onTap: () => Navigator.of(context).pop(category),
        );
      },
    );
  }
}
