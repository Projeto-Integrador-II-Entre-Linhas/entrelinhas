import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/fichamento_service.dart';
import 'fichamento_detalhes_screen.dart';

class FichamentosPublicosScreen extends StatefulWidget {
  const FichamentosPublicosScreen({super.key});

  @override
  State<FichamentosPublicosScreen> createState() => _FichamentosPublicosScreenState();
}

class _FichamentosPublicosScreenState extends State<FichamentosPublicosScreen> {
  final ApiService api = ApiService();
  final FichamentoService service = FichamentoService(); // ✅ usa o serviço certo

  final busca = TextEditingController();
  String? filtroBusca;

  List fichamentos = [];
  List<String> generos = ["Todos"];
  List<String> generosSelecionados = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    carregarGeneros();
  }

  Future<void> carregarGeneros() async {
    try {
      final lista = await service.buscarGeneros();
      setState(() {
        generos = [
          "Todos",
          ...lista.map<String>((g) => g["nome_pt"] ?? g["nome"]).toList(),
        ];
      });
    } catch (_) {
      generos = ["Todos"];
    }
    carregarFichamentos();
  }

  Future<void> carregarFichamentos() async {
    setState(() => loading = true);

    final query = <String, String>{};

    bool usarGenero = generosSelecionados.isNotEmpty && !generosSelecionados.contains("Todos");
    if (usarGenero) {
      query["genero"] = generosSelecionados.join(",");
    }

    if (filtroBusca != null && filtroBusca!.isNotEmpty) {
      query["titulo"] = filtroBusca!;
      query["autor"] = filtroBusca!;
    }

    final r = await api.get("fichamentos/publicos", query: query);
    if (r.statusCode == 200) {
      setState(() => fichamentos = jsonDecode(r.body));
    }

    setState(() => loading = false);
  }

  void buscarDebounced(String txt) {
    filtroBusca = txt.trim();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && busca.text == txt) carregarFichamentos();
    });
  }

  void abrirTodosGeneros() {
    List ordenados = [...generos]..remove("Todos");
    ordenados.sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF0E6F5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setStateModal) {
          return SizedBox(
            height: 450,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    "Selecionar Gêneros",
                    style: TextStyle(
                      color: Color(0xFF4F3466),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ordenados.map<Widget>((g) {
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
                              setStateModal(() {
                                ativo
                                    ? generosSelecionados.remove(g)
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      setState(() {});
                      carregarFichamentos();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Aplicar Filtro",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > size.height;

    final double maxCardWidth = isWide ? 200 : 150;
    final double aspect = isWide ? 0.76 : 0.62;

    return Scaffold(
      backgroundColor: const Color(0xFFD2C9D4),

      appBar: AppBar(
        title: const Text(
          "Fichamentos Públicos",
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF4F3466),
      ),

      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFCABCD7),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: busca,
                onChanged: buscarDebounced,
                decoration: const InputDecoration(
                  hintText: "Buscar fichamento",
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
                if (busca.text.isNotEmpty || generosSelecionados.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        busca.clear();          
                        filtroBusca = null;
                        generosSelecionados.clear(); 
                      });
                      carregarFichamentos();
                    },
                    child: const Text(
                      "Limpar Filtros",
                      style: TextStyle(
                        color: Color(0xFF4F3466),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          //Filtro gêneros
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: generos.length > 8 ? 9 : generos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i == 8 && generos.length > 8) {
                  return ChoiceChip(
                    label: const Text(
                      "Mais +",
                      style: TextStyle(
                        color: Color(0xFF4F3466),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: const Color(0xFFCABCD7),
                    selected: false,
                    onSelected: (_) => abrirTodosGeneros(),
                  );
                }

                final g = generos[i];
                final ativo = generosSelecionados.contains(g);

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
                    setState(() {
                      if (g == "Todos") {
                        generosSelecionados.clear();
                      } else {
                        ativo
                            ? generosSelecionados.remove(g)
                            : generosSelecionados.add(g);
                        generosSelecionados.remove("Todos");
                      }
                    });
                    carregarFichamentos();
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4F3466)),
                  )
                : fichamentos.isEmpty
                    ? const Center(
                        child: Text(
                          "Nenhum fichamento encontrado.",
                          style: TextStyle(color: Color(0xFF4F3466)),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: carregarFichamentos,
                        color: const Color(0xFF4F3466),
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          itemCount: fichamentos.length,
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: maxCardWidth,
                            childAspectRatio: aspect,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          itemBuilder: (_, i) {
                            final f = fichamentos[i];

                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FichamentoDetalhesScreen(
                                    idFichamento: f["id_fichamento"],
                                  ),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCABCD7),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Image.network(
                                          f["capa_url"] ?? "",
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.menu_book,
                                                  size: 50,
                                                  color: Color(0xFF4F3466)),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
                                        child: Text(
                                          f["titulo"] ?? "Sem título",
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF4F3466),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                                        child: Text(
                                          f["autor"] ?? "Autor desconhecido",
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
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
