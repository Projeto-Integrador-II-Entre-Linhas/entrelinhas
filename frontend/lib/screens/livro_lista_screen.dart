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

  List<String> generos = ["Todos"];
  List<String> generosSelecionados = [];

  @override
  void initState() {
    super.initState();
    carregarGeneros();
  }

  Future<void> carregarGeneros() async {
    try {
      final lista = await service.buscarGeneros();
      setState(() {
        generos = ["Todos", ...lista.map((g) => g["nome_pt"] ?? g["nome"])];
      });
      carregarLivros();
    } catch (_) {
      carregarLivros();
    }
  }

  Future<void> carregarLivros() async {
    setState(() => loading = true);

    final lista = await service.listarLivros(
      titulo: filtroBusca,
      genero: (generosSelecionados.isEmpty || generosSelecionados.contains("Todos"))
          ? null
          : generosSelecionados.join(","),
    );

    setState(() {
      livros = lista;
      loading = false;
    });
  }

  void _buscarDebounced(String valor) {
    filtroBusca = valor.trim().isEmpty ? null : valor.trim();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _controller.text.trim() == valor) carregarLivros();
    });
  }

  void _mostrarTodosGeneros(BuildContext context) {
    List<String> ordenados = [...generos]..remove("Todos");
    ordenados.sort((a, b) => a.compareTo(b));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF0E6F5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(builder: (context, setModal) {
          return SizedBox(
            height: 450,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text("Selecionar Gêneros",
                      style: TextStyle(color: Color(0xFF4F3466),fontSize: 18,fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ordenados.map((g) {
                          final ativo = generosSelecionados.contains(g);

                          return FilterChip(
                            label: Text(g),
                            selected: ativo,
                            selectedColor: const Color(0xFF4F3466),
                            backgroundColor: const Color(0xFFCABCD7),
                            labelStyle: TextStyle(
                              color: ativo ? Colors.white : const Color(0xFF4F3466),
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) {
                              setModal(() {
                                ativo ? generosSelecionados.remove(g)
                                      : generosSelecionados.add(g);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F3466),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      setState(() {});
                      carregarLivros();
                      Navigator.pop(context);
                    },
                    child: const Text("Aplicar Filtro", style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final double maxCardWidth = isLandscape ? 200 : 150;
    final double aspectRatio = isLandscape ? 0.65 : 0.55;

    return Scaffold(
      backgroundColor: const Color(0xFFD2C9D4),

      appBar: AppBar(
        backgroundColor: const Color(0xFF4F3466),
        title: const Text('Livros', style: TextStyle(color: Colors.white, fontSize: 22)),
        centerTitle: true,
      ),

      body: Column(
        children: [

          //Barra de pesquisa
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFFCABCD7), borderRadius: BorderRadius.circular(25)),
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

          // BOTÃO LIMPAR FILTROS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                if (_controller.text.isNotEmpty || generosSelecionados.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _controller.clear();
                        filtroBusca = null;
                        generosSelecionados.clear();
                      });
                      carregarLivros();
                    },
                    child: const Text("Limpar Filtros",
                        style: TextStyle(color: Color(0xFF4F3466), fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),

          //Filtro gênero
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: generos.length > 8 ? 9 : generos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),

              itemBuilder: (context, i) {
                if (i == 8 && generos.length > 8) {
                  return ChoiceChip(
                    label: const Text("Mostrar +",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F3466))),
                    backgroundColor: const Color(0xFFCABCD7),
                    selected: false,
                    onSelected: (_) => _mostrarTodosGeneros(context),
                  );
                }

                final g = generos[i];
                final ativo = generosSelecionados.contains(g);

                return ChoiceChip(
                  label: Text(g, style: TextStyle(
                    color: ativo ? Colors.white : const Color(0xFF4F3466),
                    fontWeight: FontWeight.bold,
                  )),
                  selected: ativo,
                  selectedColor: const Color(0xFF4F3466),
                  backgroundColor: const Color(0xFFCABCD7),
                  onSelected: (_) {
                    setState(() {
                      ativo ? generosSelecionados.remove(g)
                            : generosSelecionados.add(g);
                    });
                    carregarLivros();
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F3466)))
                : livros.isEmpty
                    ? const Center(child: Text("Nenhum livro encontrado.",
                        style: TextStyle(color: Color(0xFF4F3466), fontSize: 16)))
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
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => LivroDetalhesScreen(livro: livro))),

                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),

                                /// 🔥 Zoom suave aplicado aqui
                                child: MouseRegion(
                                  onEnter: (_) => setState(() => livro["hover"] = true),
                                  onExit: (_) => setState(() => livro["hover"] = false),
                                  child: AnimatedScale(
                                    scale: livro["hover"] == true ? 1.08 : 1.0,
                                    duration: const Duration(milliseconds: 220),

                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFCABCD7),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        children: [

                                          Expanded(
                                            child: Image.network(
                                              capa.isNotEmpty ? capa
                                              : "https://i.pinimg.com/736x/da/8f/b2/da8fb239479856a78bdd048d038486be.jpg",
                                              fit: BoxFit.cover,
                                            ),
                                          ),

                                          Padding(
                                            padding: const EdgeInsets.only(top: 6, left: 6, right: 6),
                                            child: Text(
                                              livro["titulo"] ?? "Sem título",
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Color(0xFF4F3466),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),

                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 6, left: 6, right: 6),
                                            child: Text(
                                              livro["autor"] ?? "Autor desconhecido",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontSize: 12, color: Colors.black87),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
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
