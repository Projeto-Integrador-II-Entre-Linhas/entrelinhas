import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class LivroService {
  final ApiService api = ApiService();

  Future<List> listarLivros({String? autor, String? titulo, String? genero}) async {
    final query = <String, String>{};
    if (autor != null && autor.isNotEmpty) query['autor'] = autor;
    if (titulo != null && titulo.isNotEmpty) query['titulo'] = titulo;
    if (genero != null && genero.isNotEmpty) query['genero'] = genero;

    final res = await api.get('livros', query: query);
    if (res.statusCode == 200) return List.from(jsonDecode(res.body));
    return [];
  }

  Future<Map?> cadastrarPorISBN(String isbn) async {
    final res = await api.post('livros/isbn', {'isbn': isbn});
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map?> getDetalhes(int id) async {
    final res = await api.get('livros/$id');
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    return null;
  }

  Future<List> buscarLivrosGoogle({String? titulo, String? isbn}) async {
    final query = <String, String>{};
    if (titulo != null && titulo.isNotEmpty) query['titulo'] = titulo;
    if (isbn != null && isbn.isNotEmpty) query['isbn'] = isbn;

    final res = await api.get('livros/search', query: query);
    if (res.statusCode == 200) {
      return List.from(jsonDecode(res.body));
    }
    return [];
  }

  // RF06 / RN07: solicitar cadastro manual
  Future<void> solicitarLivro(String termo) async {
    // backend espera autenticação para solicitar (pelo usuário logado)
    await api.post('solicitacoes', {
      'titulo': termo,
      'autor': 'Desconhecido'
    });
  }
}
