class Category {
  final int id;
  final int userId;
  final String name;
  final String type; // income | expense
  final String color;
  final String icon;
  final String description;

  Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.color,
    required this.icon,
    required this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: (json['id'] as num).toInt(),
        userId: (json['userId'] as num).toInt(),
        name: (json['name'] ?? '') as String,
        type: (json['type'] ?? 'expense') as String,
        color: (json['color'] ?? '#999999') as String,
        icon: (json['icon'] ?? '') as String,
        description: (json['description'] ?? '') as String,
      );
}

