import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class LivroService {
  final ApiService api = ApiService();

  // Listar livros com filtros
  Future<List<Map<String, dynamic>>> listarLivros({
    String? autor,
    String? titulo,
    String? genero,
  }) async {
    final query = <String, String>{};
    if (autor != null && autor.isNotEmpty) query['autor'] = autor;
    if (titulo != null && titulo.isNotEmpty) query['titulo'] = titulo;
    if (genero != null && genero.isNotEmpty) query['genero'] = genero;

    final http.Response res = await api.get('livros', query: query);
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    return [];
  }

  // Cadastrar livro automaticamente via ISBN (Google/OpenLibrary)
  Future<Map<String, dynamic>?> cadastrarPorISBN(String isbn) async {
    final http.Response res = await api.post('livros/isbn', {'isbn': isbn});
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      try {
        final msg = jsonDecode(res.body)['error'] ?? 'Erro ao cadastrar ISBN';
        throw Exception(msg);
      } catch (_) {
        throw Exception('Erro ao cadastrar livro (${res.statusCode})');
      }
    }
  }

  // Detalhes de um livro + fichamentos públicos associados
  Future<Map<String, dynamic>?> getDetalhes(int id) async {
    final http.Response res = await api.get('livros/$id');
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return null;
  }

  // Busca de livros via API pública (GoogleBooks / OpenLibrary)
  Future<List<Map<String, dynamic>>> buscarLivrosGoogle({
    String? titulo,
    String? isbn,
  }) async {
    final query = <String, String>{};
    if (titulo != null && titulo.isNotEmpty) query['titulo'] = titulo;
    if (isbn != null && isbn.isNotEmpty) query['isbn'] = isbn;

    final http.Response res = await api.get('livros/search', query: query);
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    return [];
  }

  // ADMIN — atualizar um livro existente
  Future<bool> adminUpdateLivro(int id, Map<String, dynamic> body) async {
    final http.Response res = await api.put('livros/$id', body);
    return res.statusCode == 200;
  }

  // ADMIN — excluir livro definitivamente
  Future<bool> adminDeleteLivro(int id) async {
    final http.Response res = await api.delete('livros/$id');
    return res.statusCode == 200;
  }

  // Usuário comum — solicitar cadastro manual de livro
  Future<void> solicitarLivro(String termo) async {
    await api.post('solicitacoes', {
      'titulo': termo,
      'autor': 'Desconhecido',
    });
  }

  Future<List> buscarGeneros() async {
    final res = await api.get('livros/generos');
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

}
