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
  final _controller = TextEditingController();
  final String _capaPadrao =
      'https://i.pinimg.com/736x/da/8f/b2/da8fb239479856a78bdd048d038486be.jpg';

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

  void _buscarDebounced(String valor) {
    filtro = valor.trim().isEmpty ? null : valor.trim();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _controller.text.trim() == valor) {
        carregarLivros();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD2C9D4),
      appBar: AppBar(
        title: const Text(
          'Livros Cadastrados',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4F3466),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Campo de busca
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Buscar por título',
                labelStyle: const TextStyle(color: Color(0xFF4F3466)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4F3466)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF947CAC)),
                ),
              ),
              onChanged: _buscarDebounced,
            ),
          ),

          // Lista de livros
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4F3466)),
                  )
                : livros.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum livro encontrado.',
                          style: TextStyle(
                            color: Color(0xFF4F3466),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF4F3466),
                        onRefresh: carregarLivros,
                        child: ListView.builder(
                          itemCount: livros.length,
                          itemBuilder: (context, index) {
                            final livro = livros[index];
                            final titulo = livro['titulo'] ?? 'Sem título';
                            final autor = livro['autor'] ?? 'Autor desconhecido';
                            final capa = (livro['capa_url']?.toString().isNotEmpty ?? false)
                                ? livro['capa_url']
                                : _capaPadrao;

                            return Card(
                              color: const Color(0xFFCABCD7),
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: Color(0xFF947CAC),
                                  width: 0.8,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(8),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    capa,
                                    width: 50,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.book,
                                            size: 40, color: Color(0xFF4F3466)),
                                  ),
                                ),
                                title: Text(
                                  titulo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4F3466),
                                  ),
                                ),
                                subtitle: Text(
                                  autor,
                                  style: const TextStyle(
                                    color: Color(0xFF5B3765),
                                    fontSize: 13,
                                  ),
                                ),
                                onTap: () {
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
          ),
        ],
      ),
    );
  }
}
