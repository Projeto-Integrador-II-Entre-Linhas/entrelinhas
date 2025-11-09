import 'dart:convert';
import 'package:hive/hive.dart';
import 'api_service.dart';

class FichamentoService {
  final ApiService api = ApiService();
  final Box _box = Hive.box('fichamentos_offline');

  // ==========================================================
  // RF08 / RF09 - Listar fichamentos públicos (com filtros)
  // ==========================================================
  Future<List> listarPublicos({String? autor, String? titulo, String? genero}) async {
    final query = <String, String>{};
    if (autor != null && autor.isNotEmpty) query['autor'] = autor;
    if (titulo != null && titulo.isNotEmpty) query['titulo'] = titulo;
    if (genero != null && genero.isNotEmpty) query['genero'] = genero;

    final res = await api.get('fichamentos/publicos', query: query);
    if (res.statusCode == 200) return List.from(jsonDecode(res.body));
    return [];
  }

  // ==========================================================
  // RF04 - Listar meus fichamentos
  // ==========================================================
  Future<List> listarMeus() async {
    final res = await api.get('fichamentos/me');
    if (res.statusCode == 200) return List.from(jsonDecode(res.body));
    return [];
  }

  // ==========================================================
  // RF07 - Obter meu fichamento por livro (para edição)
  // ==========================================================
  Future<Map?> meuPorLivro(int idLivro) async {
    final res = await api.get('fichamentos/me/$idLivro');
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final data = jsonDecode(res.body);
      if (data is Map) return data;
    }
    return null;
  }

  // ==========================================================
  // RF07 - Criar ou editar (Upsert)
  // ==========================================================
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

  // ==========================================================
  // RNF06 - Armazenar fichamentos offline (fila pendente)
  // ==========================================================
  Future<void> _saveOffline(Map<String, dynamic> body) async {
    final list = _box.get('pending', defaultValue: <String>[]) as List;
    list.add(jsonEncode(body));
    await _box.put('pending', list);
  }

  // ==========================================================
  // RNF06 - Sincronizar fichamentos pendentes
  // ==========================================================
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

    // remove enviados
    pending.removeWhere((item) => sent.contains(item));
    await _box.put('pending', pending);
  }

  // ==========================================================
  // RF12 / RF08 - Obter detalhes de um fichamento
  // ==========================================================
  Future<Map?> getDetalhe(int id) async {
    final res = await api.get('fichamentos/$id');
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }
}
