import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  ///bse da API. Passe seu IP local quando rodar no CELULAR FÍSICO.
  /// Ex.: ApiService(baseUrl: 'http://127.0.0.1:3000/api)
  /// para EMULADOR ANDROID use 'http://10.0.2.2:3000/api'
  final String baseUrl;

  /// Armazenamento seguro para o token
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  /// Timeout padrão das requisições
  final Duration _timeout = const Duration(seconds: 20);

  ApiService({String? baseUrl})
      : baseUrl = baseUrl ??
            // Permite definir via --dart-define=API_BASE_URL=...
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://127.0.0.1:3000/api', // <-- troque pelo seu IP
            );

  /// Lê o token salvo
  Future<String?> getToken() => storage.read(key: 'token');

  /// Constrói a URI unindo base + endpoint (sem barra inicial no endpoint)
  Uri _uri(String endpoint) => Uri.parse(
        endpoint.startsWith('/')
            ? '$baseUrl${endpoint}'
            : '$baseUrl/$endpoint',
      );

  Map<String, String> _headers([String? token]) => {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Map<String, dynamic> _safeJsonDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    } catch (_) {
      return {'raw': body};
    }
  }

  Never _throwHttpError(http.Response res, Map<String, dynamic> data, String what) {
    final msg = data['error'] ??
        data['message'] ??
        data['msg'] ??
        data['detail'] ??
        res.reasonPhrase ??
        'Erro $what';
    throw HttpException('$what (${res.statusCode}): $msg');
  }

  // =========================
  // Requests genéricos
  // =========================
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final token = await getToken();
    return http
        .post(
          _uri(endpoint),
          headers: _headers(token),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
  }

  Future<http.Response> get(String endpoint, {Map<String, String>? query}) async {
    final token = await getToken();
    final uriBase = _uri(endpoint);
    final uri = (query == null || query.isEmpty)
        ? uriBase
        : uriBase.replace(queryParameters: {
            ...uriBase.queryParameters,
            ...query,
          });
    return http.get(uri, headers: _headers(token)).timeout(_timeout);
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final token = await getToken();
    return http
        .put(
          _uri(endpoint),
          headers: _headers(token),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
  }

  Future<http.Response> delete(String endpoint) async {
    final token = await getToken();
    return http.delete(_uri(endpoint), headers: _headers(token)).timeout(_timeout);
  }

  // =========================
  // Auth
  // =========================
  Future<Map<String, dynamic>> login(String email, String senha) async {
    final res = await post('auth/login', {'email': email, 'senha': senha});
    final data = _safeJsonDecode(res.body);

    if (res.statusCode == 200) {

      if (data['token'] != null) {
        await storage.write(key: 'token', value: data['token']);
        return data;
      }

      if (data['success'] == true && data['token'] != null) {
        await storage.write(key: 'token', value: data['token']);
        return data;
      }
      _throwHttpError(res, data, 'login');
    } else {
      _throwHttpError(res, data, 'login');
    }

    throw HttpException('Falha no login (desconhecida).');
  }

  Future<Map<String, dynamic>> register(
    String nome,
    String usuario,
    String email,
    String senha,
  ) async {
    final res = await post('auth/register', {
      'nome': nome,
      'usuario': usuario,
      'email': email,
      'senha': senha,
    });

    final data = _safeJsonDecode(res.body);

    // Aceita 200 OK e 201 Created como sucesso
    if (res.statusCode == 200 || res.statusCode == 201) {

      if (data['success'] == true || data['user'] != null) {
        return data;
      }
      // Se não vier success, mas veio algo coerente, considera ok:
      if (data.containsKey('id') || data.containsKey('id_usuario')) {
        return data;
      }
      // Caso contrário, trate como erro sem travar o app
      _throwHttpError(res, data, 'cadastro');
    } else {
      _throwHttpError(res, data, 'cadastro');
    }

    throw HttpException('Falha no cadastro (desconhecida).');
  }

  /// Remove o token salvo (logout)
  Future<void> clearToken() => storage.delete(key: 'token');
}
