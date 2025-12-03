import 'package:flutter/material.dart';
import '../services/fichamento_service.dart';
import 'fichamento_detalhes_screen.dart';

class MeusFichamentosScreen extends StatefulWidget {
  const MeusFichamentosScreen({super.key});

  @override
  State<MeusFichamentosScreen> createState() => _MeusFichamentosScreenState();
}

class _MeusFichamentosScreenState extends State<MeusFichamentosScreen> {
  final FichamentoService service = FichamentoService();

  List fichamentos = [];
  List fichamentosFiltrados = [];

  bool loading = true;

  final busca = TextEditingController();
  String? filtroBusca;
  int debounceTimer = 0;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    setState(() => loading = true);

    final lista = await service.listarMeus();

    setState(() {
      fichamentos = lista;
      fichamentosFiltrados = lista;
      loading = false;
    });
  }

  void filtrar(String txt) {
    filtroBusca = txt.trim();

    debounceTimer++;
    int timer = debounceTimer;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (timer != debounceTimer) return;

      if (filtroBusca == null || filtroBusca!.isEmpty) {
        setState(() => fichamentosFiltrados = fichamentos);
        return;
      }

      final termo = filtroBusca!.toLowerCase();

      setState(() {
        fichamentosFiltrados = fichamentos.where((f) {
          final titulo = (f["titulo"] ?? "").toString().toLowerCase();
          final autor = (f["autor"] ?? "").toString().toLowerCase();
          return titulo.contains(termo) || autor.contains(termo);
        }).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD2C9D4),

      appBar: AppBar(
        title: const Text("Meus Fichamentos"),
        backgroundColor: const Color(0xFF4F3466),
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F3466)),
            )
          : Column(
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
                      onChanged: filtrar,
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        busca.clear();
                        filtrar("");
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Text(
                          "Limpar Filtros",
                          style: TextStyle(
                            color: Color(0xFF4F3466),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 6),

                Expanded(
                  child: fichamentosFiltrados.isEmpty
                      ? const Center(
                          child: Text(
                            "Nenhum fichamento encontrado.",
                            style: TextStyle(color: Color(0xFF4F3466)),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: fichamentosFiltrados.length,
                          itemBuilder: (_, i) {
                            final f = fichamentosFiltrados[i];

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
                                  color: const Color(0xFFCABCD7),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Image.network(
                                          f["capa_url"] ?? "",
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Text(
                                          f["titulo"] ?? "Sem título",
                                          maxLines: 2,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF4F3466),
                                            fontWeight: FontWeight.bold,
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
              ],
            ),
    );
  }
}
