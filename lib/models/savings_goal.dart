class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final int? targetDate;
  final String iconKey;
  final int color;
  final int createdAt;
  final bool achieved;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    this.targetDate,
    this.iconKey = 'savings',
    required this.color,
    required this.createdAt,
    this.achieved = false,
  });

  double get progress =>
      targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0, 1);

  SavingsGoal copyWith({
    String? name,
    double? targetAmount,
    double? currentAmount,
    int? targetDate,
    String? iconKey,
    int? color,
    bool? achieved,
  }) {
    return SavingsGoal(
      id: id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      iconKey: iconKey ?? this.iconKey,
      color: color ?? this.color,
      createdAt: createdAt,
      achieved: achieved ?? this.achieved,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'target_date': targetDate,
        'icon_key': iconKey,
        'color': color,
        'created_at': createdAt,
        'achieved': achieved ? 1 : 0,
      };

  factory SavingsGoal.fromMap(Map<String, Object?> map) {
    return SavingsGoal(
      id: map['id'] as String,
      name: map['name'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      currentAmount: (map['current_amount'] as num).toDouble(),
      targetDate: map['target_date'] as int?,
      iconKey: map['icon_key'] as String? ?? 'savings',
      color: map['color'] as int,
      createdAt: map['created_at'] as int,
      achieved: (map['achieved'] as int? ?? 0) == 1,
    );
  }
}
