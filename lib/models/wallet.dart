enum WalletKind { cash, bank, card, eWallet, other }

class Wallet {
  final String id;
  final String name;
  final WalletKind kind;
  final int color;
  final String currency;
  final double initialBalance;
  final int sortOrder;
  final bool archived;
  final int createdAt;

  const Wallet({
    required this.id,
    required this.name,
    required this.kind,
    required this.color,
    required this.currency,
    this.initialBalance = 0,
    this.sortOrder = 0,
    this.archived = false,
    required this.createdAt,
  });

  Wallet copyWith({
    String? name,
    WalletKind? kind,
    int? color,
    String? currency,
    double? initialBalance,
    int? sortOrder,
    bool? archived,
  }) {
    return Wallet(
      id: id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      color: color ?? this.color,
      currency: currency ?? this.currency,
      initialBalance: initialBalance ?? this.initialBalance,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        'color': color,
        'currency': currency,
        'initial_balance': initialBalance,
        'sort_order': sortOrder,
        'archived': archived ? 1 : 0,
        'created_at': createdAt,
      };

  factory Wallet.fromMap(Map<String, Object?> map) {
    return Wallet(
      id: map['id'] as String,
      name: map['name'] as String,
      kind: WalletKind.values.byName(map['kind'] as String),
      color: map['color'] as int,
      currency: map['currency'] as String,
      initialBalance: (map['initial_balance'] as num).toDouble(),
      sortOrder: map['sort_order'] as int? ?? 0,
      archived: (map['archived'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as int,
    );
  }
}
