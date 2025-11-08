import '../data/fake_users.dart';
import '../models/user.dart';

class AuthService {
  User? login(String username, String password) {
    try {
      return fakeUsers.firstWhere(
            (u) => u.username == username && u.password == password,
      );
    } catch (e) {
      return null;
    }
  }
}
