import 'package:flutter/material.dart';
import '../services/favorito_service.dart';
import 'fichamento_detalhes_screen.dart';

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  final FavoritoService service = FavoritoService();

  List favoritos = [];
  List filtrados = [];

  final busca = TextEditingController();
  String? filtroBusca;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    setState(() => loading = true);
    final list = await service.listarFavoritos();
    favoritos = list;
    aplicarFiltro();
    setState(() => loading = false);
  }

  void aplicarFiltro() {
    if (filtroBusca == null || filtroBusca!.isEmpty) {
      filtrados = favoritos;
    } else {
      final txt = filtroBusca!.toLowerCase();
      filtrados = favoritos.where((f) {
        final titulo = (f["titulo"] ?? "").toLowerCase();
        final autor = (f["autor"] ?? "").toLowerCase();
        return titulo.contains(txt) || autor.contains(txt);
      }).toList();
    }
    setState(() {});
  }

  void buscarDebounced(String txt) {
    filtroBusca = txt.trim();
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted && busca.text == txt) aplicarFiltro();
    });
  }

  Future<void> desfavoritar(int id) async {
    final ok = await service.desfavoritar(id);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Removido dos favoritos"))
      );
      carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > size.height;

    final double maxCardWidth = isWide ? 200 : 150;
    final double aspect = isWide ? 0.72 : 0.60;

    return Scaffold(
      backgroundColor: const Color(0xFFD2C9D4),

      appBar: AppBar(
        title: const Text(
          "Meus Favoritos",
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF6E4A8E),
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
                  hintText: "Buscar por título ou autor",
                  prefixIcon: Icon(Icons.search, color: Color(0xFF4F3466)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          if (busca.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    busca.clear();
                    filtroBusca = "";
                    aplicarFiltro();
                  },
                  child: const Text(
                    "Limpar",
                    style: TextStyle(
                      color: Color(0xFF4F3466),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4F3466)),
                  )
                : filtrados.isEmpty
                    ? const Center(
                        child: Text(
                          "Nenhum favorito encontrado.",
                          style: TextStyle(
                            color: Color(0xFF4F3466),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: carregar,
                        color: const Color(0xFF4F3466),
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: filtrados.length,
                          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: maxCardWidth,
                            childAspectRatio: aspect,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          itemBuilder: (_, i) {
                            final f = filtrados[i];

                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FichamentoDetalhesScreen(
                                    idFichamento: f["id_fichamento"],
                                  ),
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCABCD7),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: .08),
                                      blurRadius: 4,
                                      offset: const Offset(2, 2),
                                    )
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [

                                      // CAPA
                                      Expanded(
                                        child: Container(
                                          color: const Color(0xFFBFAECC),
                                          child: Image.network(
                                            f["capa_url"] ?? "",
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                              const Center(
                                                child: Icon(
                                                  Icons.menu_book,
                                                  size: 50,
                                                  color: Color(0xFF4F3466),
                                                ),
                                              ),
                                          ),
                                        ),
                                      ),

                                      // TÍTULO
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
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

                                      // AUTOR
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
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
