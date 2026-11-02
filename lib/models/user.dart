class User {
  final String id;
  final String email;
  final String name;
  final String currency;
  final String role;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.currency,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      currency: json['currency'] ?? 'COP',
      role: json['role'] ?? 'USER',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'currency': currency,
      'role': role,
    };
  }
}