import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthService {
  final ApiService api = ApiService();
  final storage = FlutterSecureStorage();

  // Login
  Future<bool> login(String email, String senha) async {
    try {
      final data = await api.login(email, senha);
      await storage.write(key: 'token', value: data['token']);
      return true;
    } catch (e) {
      print('Erro no login: $e');
      return false;
    }
  }

  // Registro de usuário
  Future<bool> register(String nome, String usuario, String email, String senha) async {
    try {
      final data = await api.register(nome, usuario, email, senha);
      return true;
    } catch (e) {
      print('Erro no cadastro: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async => await storage.delete(key: 'token');
}
