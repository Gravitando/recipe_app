import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'database_service.dart';

class AuthService {
  static const String _userIdKey = 'user_id';
  static const String _isLoggedInKey = 'is_logged_in';

  Future<User?> login(String email, String password) async {
    final user = await DatabaseService.instance.getUserByEmail(email);

    if (user != null && user.password == password) {
      await _saveLoginSession(user.id!);
      return user;
    }
    return null;
  }

  Future<User?> signup(String name, String email, String password) async {
    final existingUser = await DatabaseService.instance.getUserByEmail(email);

    if (existingUser != null) {
      return null;
    }

    final newUser = User(
      name: name,
      email: email,
      password: password,
    );

    final createdUser = await DatabaseService.instance.createUser(newUser);
    await _saveLoginSession(createdUser.id!);
    return createdUser;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Future<User?> getCurrentUser() async {
    final userId = await getCurrentUserId();
    if (userId != null) {
      return await DatabaseService.instance.getUserById(userId);
    }
    return null;
  }

  Future<void> _saveLoginSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    await prefs.setBool(_isLoggedInKey, true);
  }
}