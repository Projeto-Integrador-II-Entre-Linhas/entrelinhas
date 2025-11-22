import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  //API URL
  static String API_BASE_URL = '${AppConfig.baseUrl}/api';

  Uri _uri(String endpoint) => Uri.parse(
        endpoint.startsWith('/')
            ? '$API_BASE_URL$endpoint'
            : '$API_BASE_URL/$endpoint',
      );

  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'token');
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<http.Response> _safeRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request();
    } on SocketException {
      return http.Response(jsonEncode({'error': 'Sem conexão com o servidor'}), 503);
    } on TimeoutException {
      return http.Response(jsonEncode({'error': 'Tempo limite excedido'}), 504);
    } catch (e) {
      return http.Response(jsonEncode({'error': 'Erro inesperado: $e'}), 500);
    }
  }

  Future<http.Response> get(String endpoint,
      {Map<String, String>? query}) async {
    final headers = await _headers();
    final uri = _uri(endpoint);
    final finalUri = (query == null || query.isEmpty)
        ? uri
        : uri.replace(queryParameters: {...uri.queryParameters, ...query});

    return _safeRequest(() async {
      return http.get(finalUri, headers: headers)
          .timeout(const Duration(seconds: 20));
    });
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _headers();
    return _safeRequest(() async {
      return http.post(_uri(endpoint), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));
    });
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _headers();
    return _safeRequest(() async {
      return http.put(_uri(endpoint), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 20));
    });
  }

  Future<http.Response> delete(String endpoint) async {
    final headers = await _headers();
    return _safeRequest(() async {
      return http.delete(_uri(endpoint), headers: headers)
          .timeout(const Duration(seconds: 20));
    });
  }

  // Multipart BASE
  Future<http.StreamedResponse> putMultipart(
    String endpoint,
    Map<String, String> fields, {
    File? file,
    String fileField = 'avatar',
  }) async {
    final token = await _storage.read(key: 'token');
    final uri = _uri(endpoint);
    final req = http.MultipartRequest('PUT', uri);

    if (token != null) req.headers['Authorization'] = 'Bearer $token';

    fields.forEach((k, v) => req.fields[k] = v);

    if (file != null) {
      final mime = lookupMimeType(file.path) ?? 'application/octet-stream';
      final parts = mime.split('/');
      req.files.add(await http.MultipartFile.fromPath(
        fileField,
        file.path,
        contentType: MediaType(parts[0], parts[1]),
      ));
    }

    return req.send();
  }
}
