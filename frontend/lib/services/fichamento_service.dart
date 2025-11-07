import 'dart:convert';
import 'package:hive/hive.dart';
import 'api_service.dart';

class FichamentoService {
  final ApiService api = ApiService();
  final Box _box = Hive.box('fichamentos_offline');

  Future<List> listarPublicos() async {
    final res = await api.get('fichamentos/publicos');
    if (res.statusCode == 200) return List.from(jsonDecode(res.body));
    return [];
  }

  // RF04: meus fichamentos
  Future<List> listarMeus() async {
    final res = await api.get('fichamentos');
    if (res.statusCode == 200) return List.from(jsonDecode(res.body));
    return [];
  }

  // RF07: obter meu fichamento por livro (para editar)
  Future<Map?> meuPorLivro(int idLivro) async {
    final res = await api.get('fichamentos/me/$idLivro');
    if (res.statusCode == 200) {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : null;
      if (body == null) return null;
      if (body is Map) return body;
    }
    return null;
  }

  // RF07: criar/editar (upsert)
  Future<bool> upsert(Map<String, dynamic> body) async {
    try {
      final res = await api.post('fichamentos', body);
      if (res.statusCode == 200 || res.statusCode == 201) return true;
      // fallback offline
      if (res.statusCode == 0) {
        await _saveOffline(body);
        return true;
      }
      return false;
    } catch (_) {
      await _saveOffline(body);
      return true;
    }
  }

  Future<void> _saveOffline(Map<String, dynamic> body) async {
    final list = _box.get('pending', defaultValue: <String>[]) as List;
    list.add(jsonEncode(body));
    await _box.put('pending', list);
  }

  Future<void> syncPending() async {
    final list = _box.get('pending', defaultValue: <String>[]) as List;
    final pending = List<String>.from(list);
    for (final item in pending) {
      try {
        final body = jsonDecode(item) as Map<String, dynamic>;
        final res = await api.post('fichamentos', body);
        if (res.statusCode == 200 || res.statusCode == 201) {
          pending.remove(item);
        }
      } catch (_) {}
    }
    await _box.put('pending', pending);
  }
}
