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

  final _controller = TextEditingController();
  String? filtroBusca;

  final List<String> generos = [
    'Todos',
    'Romance',
    'Fantasia',
    'Aventura',
    'Mistério',
    'Terror',
    'Drama',
  ];

  String generoSelecionado = 'Todos';

  @override
  void initState() {
    super.initState();
    carregarLivros();
  }

  Future<void> carregarLivros() async {
    setState(() => loading = true);
    final lista = await service.listarLivros(
      titulo: filtroBusca,
      genero: generoSelecionado == 'Todos' ? null : generoSelecionado,
    );
    setState(() {
      livros = lista;
      loading = false;
    });
  }

  void _buscarDebounced(String valor) {
    filtroBusca = valor.trim().isEmpty ? null : valor.trim();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _controller.text.trim() == valor) {
        carregarLivros();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;

    // Configurações responsivas
    final double maxCardWidth = isLandscape ? 200 : 150;
    final double aspectRatio = isLandscape ? 0.65 : 0.55;

    return Scaffold(
      backgroundColor: const Color(0xFFD2C9D4),

      appBar: AppBar(
        backgroundColor: const Color(0xFF4F3466),
        title: const Text(
          'Livros',
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
        centerTitle: true,
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          //Barra de Pesquisa
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFCABCD7),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _controller,
                onChanged: _buscarDebounced,
                decoration: const InputDecoration(
                  hintText: "Pesquisar",
                  prefixIcon: Icon(Icons.search, color: Color(0xFF4F3466)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          //Gêneros
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: generos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final g = generos[i];
                final ativo = generoSelecionado == g;
                return ChoiceChip(
                  label: Text(
                    g,
                    style: TextStyle(
                      color: ativo ? Colors.white : const Color(0xFF4F3466),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  selected: ativo,
                  selectedColor: const Color(0xFF4F3466),
                  backgroundColor: const Color(0xFFCABCD7),
                  onSelected: (_) {
                    setState(() => generoSelecionado = g);
                    carregarLivros();
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          //Grid de Livros
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4F3466)),
                  )
                : livros.isEmpty
                    ? const Center(
                        child: Text(
                          "Nenhum livro encontrado.",
                          style: TextStyle(color: Color(0xFF4F3466), fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: carregarLivros,
                        color: const Color(0xFF4F3466),
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: livros.length,
                          
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: maxCardWidth,
                            childAspectRatio: aspectRatio,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),

                          itemBuilder: (context, index) {
                            final livro = livros[index];
                            final capa = livro['capa_url'] ?? '';

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LivroDetalhesScreen(livro: livro),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCABCD7),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Image.network(
                                    capa.isNotEmpty
                                        ? capa
                                        : "https://i.pinimg.com/736x/da/8f/b2/da8fb239479856a78bdd048d038486be.jpg",
                                    fit: BoxFit.cover,
                                  ),
                                ),
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
