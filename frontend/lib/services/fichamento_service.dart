import 'dart:convert';
import 'package:hive/hive.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;

class FichamentoService {
  final ApiService api = ApiService();
  final Box _box = Hive.box('fichamentos_offline');

  Future<List> listarPublicos() async {
    final res = await api.get('fichamentos/publicos');
    if (res.statusCode == 200) return List.from(jsonDecode(res.body));
    return [];
  }

  Future<bool> criarFichamento(Map<String,dynamic> body) async {
    try {
      final res = await api.post('fichamentos', body);
      if (res.statusCode == 200 || res.statusCode == 201) return true;
      // se falhar por falta de conexão, salva offline
      if (res.statusCode == 0) {
        await _saveOffline(body);
        return true;
      }
      return false;
    } catch (e) {
      // salva offline
      await _saveOffline(body);
      return true;
    }
  }

  Future<void> _saveOffline(Map<String,dynamic> body) async {
    final list = _box.get('pending', defaultValue: <String>[]) as List;
    list.add(jsonEncode(body));
    await _box.put('pending', list);
  }

  Future<void> syncPending() async {
    final list = _box.get('pending', defaultValue: <String>[]) as List;
    final pending = List<String>.from(list);
    for (final item in pending) {
      try {
        final body = jsonDecode(item) as Map<String,dynamic>;
        final res = await api.post('fichamentos', body);
        if (res.statusCode == 200 || res.statusCode == 201) {
          pending.remove(item);
        }
      } catch (_) {}
    }
    await _box.put('pending', pending);
  }
}
