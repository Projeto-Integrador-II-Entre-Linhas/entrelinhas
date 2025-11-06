import 'package:flutter/material.dart';
import '../services/livro_service.dart';
import 'livro_detalhes_screen.dart';

class LivroListaScreen extends StatefulWidget {
  const LivroListaScreen({super.key});

  @override
  State<LivroListaScreen> createState() => _LivroListaScreenState();
}

class _LivroListaScreenState extends State<LivroListaScreen> {
  final LivroService service = LivroService();
  List livros = [];
  bool loading = true;
  String? filtro;

  @override
  void initState() {
    super.initState();
    carregarLivros();
  }

  Future<void> carregarLivros() async {
    setState(() => loading = true);
    final lista = await service.listarLivros(titulo: filtro);
    setState(() {
      livros = lista;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Livros Cadastrados')),
      body: Column(
        children: [
          // Campo de busca
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar por título',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (valor) {
                filtro = valor;
                carregarLivros();
              },
            ),
          ),

          // Lista de livros
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : livros.isEmpty
                    ? const Center(child: Text('Nenhum livro encontrado'))
                    : ListView.builder(
                        itemCount: livros.length,
                        itemBuilder: (context, index) {
                          final livro = livros[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: ListTile(
                              leading: livro['capa_url'] != null &&
                                      livro['capa_url'].toString().isNotEmpty
                                  ? Image.network(
                                      livro['capa_url'],
                                      width: 50,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.book, size: 40),
                              title: Text(livro['titulo'] ?? 'Sem título'),
                              subtitle: Text(
                                livro['autor'] ?? 'Autor desconhecido',
                                style: const TextStyle(fontSize: 13),
                              ),
                              onTap: () {
                                // Ao clicar, abre a tela de detalhes do livro
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        LivroDetalhesScreen(livro: livro),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
