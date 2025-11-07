import 'dart:convert';
import 'dart:io';
import 'dart:async'; // necessário para TimeoutException
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Endereço base da API — ajuste conforme o ambiente
  static const String API_BASE_URL = 'http://192.168.100.12:3000/api';
  // Para o emulador Android, use:
  // static const String API_BASE_URL = 'http://10.0.2.2:3000/api';

  Uri _uri(String endpoint) => Uri.parse(
        endpoint.startsWith('/')
            ? '$API_BASE_URL$endpoint'
            : '$API_BASE_URL/$endpoint',
      );

  // ----------------------------------------------------------
  // HEADERS PADRÕES
  // ----------------------------------------------------------
  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'token');
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  // ----------------------------------------------------------
  // TRATAMENTO DE ERROS (NETWORK SAFE)
  // ----------------------------------------------------------
  Future<http.Response> _safeRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request();
    } on SocketException {
      return http.Response(
          jsonEncode({'error': 'Sem conexão com o servidor'}), 503);
    } on HttpException {
      return http.Response(jsonEncode({'error': 'Erro HTTP genérico'}), 500);
    } on FormatException {
      return http.Response(jsonEncode({'error': 'Erro de formato na resposta'}), 500);
    } on TimeoutException {
      return http.Response(jsonEncode({'error': 'Tempo limite excedido'}), 504);
    } catch (e) {
      return http.Response(jsonEncode({'error': 'Erro inesperado: $e'}), 500);
    }
  }

  // ----------------------------------------------------------
  // MÉTODOS HTTP
  // ----------------------------------------------------------

  Future<http.Response> get(String endpoint,
      {Map<String, String>? query}) async {
    final headers = await _headers();
    final uri = _uri(endpoint);
    final finalUri = (query == null || query.isEmpty)
        ? uri
        : uri.replace(queryParameters: {...uri.queryParameters, ...query});

    return _safeRequest(() async {
      return http
          .get(finalUri, headers: headers)
          .timeout(const Duration(seconds: 20));
    });
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _headers();
    return _safeRequest(() async {
      return http
          .post(_uri(endpoint),
              headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));
    });
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _headers();
    return _safeRequest(() async {
      return http
          .put(_uri(endpoint),
              headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));
    });
  }

  Future<http.Response> delete(String endpoint) async {
    final headers = await _headers();
    return _safeRequest(() async {
      return http
          .delete(_uri(endpoint), headers: headers)
          .timeout(const Duration(seconds: 20));
    });
  }

  // ----------------------------------------------------------
  // UPLOAD MULTIPART GENÉRICO (IMAGENS, ARQUIVOS ETC.)
  // ----------------------------------------------------------
  Future<http.StreamedResponse> uploadFile(
    String endpoint,
    File file, {
    String fieldName = 'file',
    String method = 'POST',
  }) async {
    final token = await _storage.read(key: 'token');
    final uri = _uri(endpoint);

    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final mimeParts = mimeType.split('/');

    final req = http.MultipartRequest(method, uri);

    if (token != null) {
      req.headers['Authorization'] = 'Bearer $token';
    }

    req.files.add(await http.MultipartFile.fromPath(
      fieldName,
      file.path,
      contentType: MediaType(mimeParts[0], mimeParts[1]),
    ));

    return req.send();
  }

  Future<http.StreamedResponse> uploadAvatar(
      String endpoint, File file) async {
    return uploadFile(endpoint, file, fieldName: 'avatar', method: 'PUT');
  }
}
