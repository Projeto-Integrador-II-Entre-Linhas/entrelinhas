import 'dart:convert';
import 'package:hive/hive.dart';
import 'api_service.dart';

class FichamentoService {
  final ApiService api = ApiService();
  final Box _box = Hive.box('fichamentos_offline');

  Future<List> listarPublicos({String? autor, String? titulo, String? genero}) async {
    final query = <String, String>{};
    if (autor != null && autor.isNotEmpty) query['autor'] = autor;
    if (titulo != null && titulo.isNotEmpty) query['titulo'] = titulo;
    if (genero != null && genero.isNotEmpty) query['genero'] = genero;

    final res = await api.get('fichamentos/publicos', query: query);
    if (res.statusCode == 200) return List.from(jsonDecode(res.body));
    return [];
  }

  Future<List> listarMeus() async {
    final res = await api.get('fichamentos/me');
    if (res.statusCode == 200) return List.from(jsonDecode(res.body));
    return [];
  }

  // Corrigido: rota de backend implementada como /fichamentos/me/:idLivro
  Future<Map?> meuPorLivro(int idLivro) async {
    final res = await api.get('fichamentos/me/$idLivro');
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final data = jsonDecode(res.body);
      if (data is Map) return data;
    }
    return null;
  }

  Future<bool> upsert(Map<String, dynamic> body) async {
    try {
      final res = await api.post('fichamentos', body);
      if (res.statusCode == 200 || res.statusCode == 201) return true;

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
    if (list.isEmpty) return;

    final pending = List<String>.from(list);
    final sent = <String>[];

    for (final item in pending) {
      try {
        final body = jsonDecode(item) as Map<String, dynamic>;
        final res = await api.post('fichamentos', body);
        if (res.statusCode == 200 || res.statusCode == 201) {
          sent.add(item);
        }
      } catch (_) {}
    }

    pending.removeWhere((item) => sent.contains(item));
    await _box.put('pending', pending);
  }

  Future<Map?> getDetalhe(int id) async {
    final res = await api.get('fichamentos/$id');
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<bool> excluir(int idFichamento) async {
    final res = await api.delete('fichamentos/$idFichamento');
    return res.statusCode == 200;
  }
}
