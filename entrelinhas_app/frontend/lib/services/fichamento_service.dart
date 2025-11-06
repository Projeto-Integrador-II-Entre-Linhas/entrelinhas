import 'dart:convert';
import 'api_service.dart';
import '../models/fichamento.dart';

class FichamentoService {
  final ApiService api = ApiService();

  Future<List<Fichamento>> listarFichamentos({bool apenasPublicos = false}) async {
    final res = await api.get('fichamentos${apenasPublicos ? '/publicos' : ''}');
    if(res.statusCode == 200){
      final list = jsonDecode(res.body) as List;
      return list.map((e) => Fichamento.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> criarFichamento(Fichamento f) async {
    final res = await api.post('fichamentos', f.toJson());
    return res.statusCode == 200;
  }

  Future<bool> atualizarFichamento(Fichamento f) async {
    final res = await api.post('fichamentos/${f.id}', f.toJson());
    return res.statusCode == 200;
  }
}
