import 'dart:convert';
import 'api_service.dart';
import 'package:http/http.dart' as http;

class LivroService {
  final ApiService api = ApiService();
  final String googleBooksApi = 'https://www.googleapis.com/books/v1/volumes';

  Future<Map?> buscarLivroPorISBN(String isbn) async {
    final res = await http.get(Uri.parse('$googleBooksApi?q=isbn:$isbn'));
    if(res.statusCode == 200){
      final data = jsonDecode(res.body);
      if(data['totalItems'] > 0) return data['items'][0]['volumeInfo'];
    }
    return null;
  }

  Future<List> listarLivros() async {
    final res = await api.get('livros');
    if(res.statusCode == 200) return List.from(jsonDecode(res.body));
    return [];
  }

  Future<bool> cadastrarLivro(Map<String,dynamic> livro) async {
    final res = await api.post('livros', livro);
    return res.statusCode == 200;
  }
}
