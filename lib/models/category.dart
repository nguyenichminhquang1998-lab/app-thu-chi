enum CategoryType { expense, income }

/// Mirrors the "Cần thiết / Mong muốn / Loại bỏ" labels seen in the
/// reference app — lets a user tag how justified a spending category is.
enum CategoryPriority { essential, want, eliminate }

class Category {
  final String id;
  final String name;
  final CategoryType type;
  final String iconKey;
  final int color;
  final CategoryPriority? priority;
  final int sortOrder;
  final bool archived;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.iconKey,
    required this.color,
    this.priority,
    this.sortOrder = 0,
    this.archived = false,
  });

  Category copyWith({
    String? name,
    CategoryType? type,
    String? iconKey,
    int? color,
    CategoryPriority? priority,
    bool clearPriority = false,
    int? sortOrder,
    bool? archived,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconKey: iconKey ?? this.iconKey,
      color: color ?? this.color,
      priority: clearPriority ? null : (priority ?? this.priority),
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'type': type.name,
        'icon_key': iconKey,
        'color': color,
        'priority': priority?.name,
        'sort_order': sortOrder,
        'archived': archived ? 1 : 0,
      };

  factory Category.fromMap(Map<String, Object?> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      type: CategoryType.values.byName(map['type'] as String),
      iconKey: map['icon_key'] as String,
      color: map['color'] as int,
      priority: map['priority'] == null
          ? null
          : CategoryPriority.values.byName(map['priority'] as String),
      sortOrder: map['sort_order'] as int? ?? 0,
      archived: (map['archived'] as int? ?? 0) == 1,
    );
  }
}
