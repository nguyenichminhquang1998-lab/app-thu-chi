import '../../models/category.dart';
import '../../models/wallet.dart';
import '../../utils/id_generator.dart';
import '../repositories/category_repository.dart';
import '../repositories/wallet_repository.dart';

/// Populates a brand-new database with a starter wallet and a sensible set
/// of Vietnamese expense/income categories (tagged Cần thiết / Mong muốn /
/// Loại bỏ) so first-run users see a working app instead of an empty list.
class DefaultDataSeeder {
  final WalletRepository walletRepository;
  final CategoryRepository categoryRepository;

  DefaultDataSeeder({
    required this.walletRepository,
    required this.categoryRepository,
  });

  Future<void> seedIfEmpty() async {
    final wallets = await walletRepository.getAll(includeArchived: true);
    if (wallets.isEmpty) {
      await walletRepository.insert(Wallet(
        id: newId(),
        name: 'Tiền mặt',
        kind: WalletKind.cash,
        color: 0xFF4CAF50,
        currency: 'VND',
        initialBalance: 0,
        sortOrder: 0,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
    }

    final categories = await categoryRepository.getAll(includeArchived: true);
    if (categories.isEmpty) {
      var order = 0;
      for (final def in _expenseDefaults) {
        await categoryRepository.insert(Category(
          id: newId(),
          name: def.name,
          type: CategoryType.expense,
          iconKey: def.iconKey,
          color: def.color,
          priority: def.priority,
          sortOrder: order++,
        ));
      }
      order = 0;
      for (final def in _incomeDefaults) {
        await categoryRepository.insert(Category(
          id: newId(),
          name: def.name,
          type: CategoryType.income,
          iconKey: def.iconKey,
          color: def.color,
          sortOrder: order++,
        ));
      }
    }
  }
}

class _CategorySeed {
  final String name;
  final String iconKey;
  final int color;
  final CategoryPriority? priority;
  const _CategorySeed(this.name, this.iconKey, this.color, [this.priority]);
}

const _expenseDefaults = [
  _CategorySeed('Ăn uống', 'food', 0xFFFF7043, CategoryPriority.essential),
  _CategorySeed('Nhà ở', 'housing', 0xFFFFB300, CategoryPriority.essential),
  _CategorySeed('Điện nước', 'utilities', 0xFF29B6F6, CategoryPriority.essential),
  _CategorySeed('Đi lại', 'transport', 0xFF66BB6A, CategoryPriority.essential),
  _CategorySeed('Sức khoẻ', 'health', 0xFFEF5350, CategoryPriority.essential),
  _CategorySeed('Giáo dục', 'education', 0xFF8D6E63, CategoryPriority.essential),
  _CategorySeed('Mua sắm', 'shopping', 0xFFEC407A, CategoryPriority.want),
  _CategorySeed('Giải trí', 'entertainment', 0xFFAB47BC, CategoryPriority.want),
  _CategorySeed('Du lịch', 'travel', 0xFF26A69A, CategoryPriority.want),
  _CategorySeed('Cà phê', 'coffee', 0xFF8D6E63, CategoryPriority.want),
  _CategorySeed('Quần áo', 'clothes', 0xFF7E57C2, CategoryPriority.want),
  _CategorySeed('Rượu bia', 'alcohol', 0xFF5C6BC0, CategoryPriority.eliminate),
  _CategorySeed('Cho vay', 'loan_out', 0xFF78909C, CategoryPriority.eliminate),
  _CategorySeed('Khác', 'other_expense', 0xFF9E9E9E),
];

const _incomeDefaults = [
  _CategorySeed('Lương', 'salary', 0xFF43A047),
  _CategorySeed('Thưởng', 'bonus', 0xFFFFA000),
  _CategorySeed('Cổ tức', 'dividend', 0xFF1E88E5),
  _CategorySeed('Thu nhập khác', 'other_income', 0xFF9E9E9E),
];
