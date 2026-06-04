import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UserDatabase {
  static final UserDatabase instance = UserDatabase._init();

  static const String _usersKey = 'users';

  UserDatabase._init();

  Future<List<Map<String, dynamic>>> _getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_usersKey);

    if (data == null || data.isEmpty) return [];

    final decoded = jsonDecode(data) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> _saveUsers(List<Map<String, dynamic>> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  Future<void> insertUser(Map<String, dynamic> row) async {
    final users = await _getUsers();
    final email = (row['email'] as String).trim().toLowerCase();

    final existingUser = users.any(
      (user) => (user['email'] as String).trim().toLowerCase() == email,
    );

    if (existingUser) {
      throw Exception('El correo ya esta registrado');
    }

    users.add({
      'id': DateTime.now().millisecondsSinceEpoch,
      'name': (row['name'] as String).trim(),
      'email': email,
      'password': (row['password'] as String).trim(),
    });

    await _saveUsers(users);
  }

  Future<bool> loginUser(String email, String password) async {
    final users = await _getUsers();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    return users.any(
      (user) =>
          (user['email'] as String).trim().toLowerCase() == cleanEmail &&
          (user['password'] as String).trim() == cleanPassword,
    );
  }
}
