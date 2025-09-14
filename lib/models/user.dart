class User {
  final int id;
  final String email;
  final String name;

  User({required this.id, required this.email, required this.name});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: (json['id'] as num).toInt(),
        email: json['email'] as String,
        name: (json['name'] ?? '') as String,
      );
}

