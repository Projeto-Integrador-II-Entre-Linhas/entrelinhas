import 'dart:convert';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  // Para emulador Android: use http://10.0.2.2:3000/api
  //static const String API_BASE_URL =
      //String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000/api'); 
    static const String API_BASE_URL = 'http://172.16.42.181:3000/api';

  Uri _uri(String endpoint) => Uri.parse(endpoint.startsWith('/') ? '$API_BASE_URL$endpoint' : '$API_BASE_URL/$endpoint');

  Future<Map<String,String>> _headers() async {
    final token = await _storage.read(key: 'token');
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _headers();
    return http.post(_uri(endpoint), headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 20));
  }

  Future<http.Response> get(String endpoint, {Map<String,String>? query}) async {
    final headers = await _headers();
    final uri = _uri(endpoint);
    final finalUri = (query == null || query.isEmpty) ? uri : uri.replace(queryParameters: {...uri.queryParameters, ...query});
    return http.get(finalUri, headers: headers).timeout(const Duration(seconds: 20));
  }

  Future<http.Response> put(String endpoint, Map<String,dynamic> body) async {
    final headers = await _headers();
    return http.put(_uri(endpoint), headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 20));
  }

  Future<http.Response> delete(String endpoint) async {
    final headers = await _headers();
    return http.delete(_uri(endpoint), headers: headers).timeout(const Duration(seconds: 20));
  }

  // upload multipart (avatar)
  Future<http.StreamedResponse> uploadAvatar(String endpoint, File file) async {
    final token = await _storage.read(key: 'token');
    final uri = _uri(endpoint);

    // Detecta o tipo MIME com base na extensão do arquivo
    final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
    final mimeParts = mimeType.split('/'); // ['image', 'jpeg']

    final req = http.MultipartRequest('PUT', uri);

    if (token != null) {
      req.headers['Authorization'] = 'Bearer $token';
    }

    // Adiciona o arquivo com tipo MIME correto
    req.files.add(await http.MultipartFile.fromPath(
      'avatar',
      file.path,
      contentType: MediaType(mimeParts[0], mimeParts[1]),
    ));

    return req.send();
  }

}
