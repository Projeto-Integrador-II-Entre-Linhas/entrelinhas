import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class AuthService {
  final ApiService api = ApiService();

  Future<Map<String, dynamic>> login(String email, String senha) async {
    final res = await api.post('auth/login', {'email': email, 'senha': senha});
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Erro no login: ${res.body}');
  }

  Future<Map<String, dynamic>> register(String nome, String usuario, String email, String senha) async {
    final res = await api.post('auth/register', {'nome': nome, 'usuario': usuario, 'email': email, 'senha': senha});
    if (res.statusCode == 201 || res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Erro no cadastro: ${res.body}');
  }

  Map<String,dynamic> parseUser(String json) => jsonDecode(json) as Map<String,dynamic>;
  String userToJson(Map<String,dynamic> user) => jsonEncode(user);
}
