class User {
  final String username;
  final String password;
  final String role; // "admin" hoặc "user"

  User({
    required this.username,
    required this.password,
    required this.role,
  });
}
