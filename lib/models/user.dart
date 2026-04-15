class User {
  final int id;
  final String name;
  final String email;
  final bool isAdmin;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.isAdmin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isAdmin: json['isAdmin'] as bool? ?? false,
    );
  }
}
