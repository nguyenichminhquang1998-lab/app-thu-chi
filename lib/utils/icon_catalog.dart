import 'package:flutter/material.dart';

/// Maps a stable string key (stored in the database) to an [IconData].
/// Keeping a string key instead of persisting `IconData.codePoint` directly
/// means the icon set can change between app versions without corrupting
/// old data.
class IconCatalog {
  IconCatalog._();

  static const Map<String, IconData> _icons = {
    'food': Icons.restaurant,
    'coffee': Icons.local_cafe,
    'groceries': Icons.local_grocery_store,
    'transport': Icons.directions_car,
    'fuel': Icons.local_gas_station,
    'housing': Icons.home,
    'utilities': Icons.bolt,
    'water': Icons.water_drop,
    'health': Icons.local_hospital,
    'pharmacy': Icons.medication,
    'shopping': Icons.shopping_bag,
    'clothes': Icons.checkroom,
    'entertainment': Icons.movie,
    'travel': Icons.flight,
    'education': Icons.school,
    'gift': Icons.card_giftcard,
    'electronics': Icons.devices,
    'sports': Icons.fitness_center,
    'pet': Icons.pets,
    'alcohol': Icons.liquor,
    'debt': Icons.money_off,
    'loan_out': Icons.people_outline,
    'family': Icons.family_restroom,
    'phone': Icons.smartphone,
    'insurance': Icons.shield,
    'tax': Icons.receipt_long,
    'repair': Icons.build,
    'other_expense': Icons.category,
    // income
    'salary': Icons.payments,
    'bonus': Icons.emoji_events,
    'dividend': Icons.show_chart,
    'investment': Icons.trending_up,
    'refund': Icons.replay,
    'freelance': Icons.laptop_mac,
    'gift_income': Icons.redeem,
    'other_income': Icons.attach_money,
    // wallets
    'cash': Icons.money,
    'bank': Icons.account_balance,
    'card': Icons.credit_card,
    'ewallet': Icons.account_balance_wallet,
    'wallet_other': Icons.savings,
    // savings goals
    'savings': Icons.savings,
    'house': Icons.house,
    'car': Icons.directions_car_filled,
    'wedding': Icons.favorite,
    'emergency': Icons.health_and_safety,
  };

  static IconData iconFor(String key) => _icons[key] ?? Icons.category;

  static List<String> get expenseKeys => const [
        'food', 'coffee', 'groceries', 'transport', 'fuel', 'housing',
        'utilities', 'water', 'health', 'pharmacy', 'shopping', 'clothes',
        'entertainment', 'travel', 'education', 'gift', 'electronics',
        'sports', 'pet', 'alcohol', 'debt', 'loan_out', 'family', 'phone',
        'insurance', 'tax', 'repair', 'other_expense',
      ];

  static List<String> get incomeKeys => const [
        'salary', 'bonus', 'dividend', 'investment', 'refund', 'freelance',
        'gift_income', 'other_income',
      ];

  static List<String> get walletKeys => const [
        'cash', 'bank', 'card', 'ewallet', 'wallet_other',
      ];

  static List<String> get goalKeys => const [
        'savings', 'house', 'car', 'wedding', 'emergency', 'travel',
        'electronics', 'education',
      ];

  static List<String> get allKeys => _icons.keys.toList(growable: false);
}
