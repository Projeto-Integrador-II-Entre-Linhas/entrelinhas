import 'dart:convert';
import 'api_service.dart';
import 'package:http/http.dart' as http;
import 'offline_sync_service.dart';

class FavoritoService {
  final ApiService api = ApiService();

  Future<bool> favoritar(int idFichamento) async {
    final res = await api.post('favoritos', {'id_fichamento': idFichamento});
    return res.statusCode == 200 || res.statusCode == 201;
  }

  Future<bool> desfavoritar(int idFichamento) async {
    final res = await api.delete('favoritos/$idFichamento');
    return res.statusCode == 200;
  }

  Future<List> listarFavoritos() async {
    final http.Response res = await api.get('favoritos');
    if (res.statusCode == 200) return List.from(jsonDecode(res.body));
    return [];
  }
}

class FichamentoService {
  final ApiService api = ApiService();
  final OfflineSyncService offline = OfflineSyncService();

  Future<bool> upsert(Map<String, dynamic> body) async {
    try {
      final r = await api.post('fichamentos', body);
      if (r.statusCode == 200 || r.statusCode == 201) return true;

      // Se o servidor rejeitou por RN04 (duplicado), retorna falso
      if (r.statusCode == 400 && r.body.contains('Você já possui um fichamento')) {
        return false;
      }

      await offline.enqueueUpsert(body);
      return true;
    } catch (_) {
      // sem conexão -> fila offline
      await offline.enqueueUpsert(body);
      return true;
    }
  }

  Future<Map<String, dynamic>?> getDetalhe(int id) async {
    final r = await api.get('fichamentos/$id');
    if (r.statusCode == 200 && r.body.isNotEmpty) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>?> meuPorLivro(int idLivro) async {
    final r = await api.get('fichamentos/me/$idLivro');
    if (r.statusCode == 200 && r.body.isNotEmpty) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    return null;
  }
}
