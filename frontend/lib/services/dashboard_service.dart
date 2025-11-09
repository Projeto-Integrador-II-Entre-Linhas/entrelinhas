import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class DashboardService {
  final ApiService api = ApiService();
  Future<Map<String,dynamic>?> get() async {
    final http.Response r = await api.get('dashboard');
    if (r.statusCode == 200) return jsonDecode(r.body) as Map<String,dynamic>;
    return null;
  }
}
