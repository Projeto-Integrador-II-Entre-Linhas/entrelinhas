import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  Map<String, dynamic>? user;

  Future<void> tryAutoLogin() async {
    final token = await _storage.read(key: 'token');
    if (token != null) {
      // opcional: verificar validade do token (decoding) ou consultar /api/users/me
      _isAuthenticated = true;
      // carregar user salvo
      final userJson = await _storage.read(key: 'user');
      if (userJson != null) user = _auth.parseUser(userJson);
      notifyListeners();
    }
  }

  Future<bool> login(String email, String senha) async {
    try {
      final data = await _auth.login(email, senha);
      await _storage.write(key: 'token', value: data['token']);
      if (data['user'] != null) {
        await _storage.write(key: 'user', value: _auth.userToJson(data['user']));
        user = data['user'];
      }
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user');
    _isAuthenticated = false;
    user = null;
    notifyListeners();
  }
}
