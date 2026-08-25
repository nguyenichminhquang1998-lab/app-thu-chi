/// A standing monthly budget limit for a category (or the whole wallet set
/// when [categoryId] is null — an overall monthly spending cap).
class Budget {
  final String id;
  final String? categoryId;
  final double amount;
  final int createdAt;

  const Budget({
    required this.id,
    this.categoryId,
    required this.amount,
    required this.createdAt,
  });

  Budget copyWith({double? amount}) => Budget(
        id: id,
        categoryId: categoryId,
        amount: amount ?? this.amount,
        createdAt: createdAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'category_id': categoryId,
        'amount': amount,
        'created_at': createdAt,
      };

  factory Budget.fromMap(Map<String, Object?> map) {
    return Budget(
      id: map['id'] as String,
      categoryId: map['category_id'] as String?,
      amount: (map['amount'] as num).toDouble(),
      createdAt: map['created_at'] as int,
    );
  }
}
