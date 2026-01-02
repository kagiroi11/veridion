class Category {
  final String id;
  final String name;
  final String icon;
  final String color;
  final bool isExpense;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isExpense,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      icon: map['icon'] ?? '',
      color: map['color'] ?? '#000000',
      isExpense: map['is_expense'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'is_expense': isExpense,
    };
  }
}
