import 'dart:convert';
import 'api_service.dart';

class AuthService {
  final ApiService api = ApiService();

  Future<Map<String, dynamic>> login(String email, String senha) async {
    final res = await api.post('auth/login', {
      'email': email,
      'senha': senha,
    });

    // ignore: avoid_print
    print("FLUTTER LOGIN STATUS: ${res.statusCode}");
    // ignore: avoid_print
    print("FLUTTER LOGIN BODY: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception("Erro no login: ${res.body}");
    }

    Map<String, dynamic> data;

    try {
      data = jsonDecode(res.body);
    } catch (e) {
      throw Exception("Erro ao interpretar resposta do servidor: $e");
    }

    if (!data.containsKey('token')) {
      throw Exception("Resposta inválida: token ausente.");
    }

    return data;
  }

  Future<Map<String, dynamic>> register(
    String nome, String usuario, String email, String senha) async {
  final res = await api.post(
    'auth/register',
    {
      'nome': nome,
      'usuario': usuario,
      'email': email,
      'senha': senha,
    },
  );

  if (res.statusCode == 201 || res.statusCode == 200) {
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  throw Exception('Erro no cadastro: ${res.body}');
}


  Map<String, dynamic> parseUser(String json) =>
      jsonDecode(json) as Map<String, dynamic>;
  String userToJson(Map<String, dynamic> user) => jsonEncode(user);
}
