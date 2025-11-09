import 'dart:convert';
import 'api_service.dart';
import 'package:http/http.dart' as http;

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
