import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'fichamento_detalhes_screen.dart';

class FichamentosPublicosScreen extends StatefulWidget {
  const FichamentosPublicosScreen({super.key});

  @override
  State<FichamentosPublicosScreen> createState() =>
      _FichamentosPublicosScreenState();
}

class _FichamentosPublicosScreenState
    extends State<FichamentosPublicosScreen> {
  final ApiService api = ApiService();
  final _busca = TextEditingController();

  bool loading = false;
  List itens = [];

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  Future<void> _buscar() async {
    setState(() => loading = true);
    try {
      final termo = _busca.text.trim();

      String path;
      if (termo.isEmpty) {
        path = 'fichamentos/publicos';
      } else {
        final q = Uri.encodeQueryComponent(termo);
        path = 'fichamentos/publicos?q=$q';
      }

      final r = await api.get(path);
      if (r.statusCode == 200 && r.body.isNotEmpty) {
        itens = jsonDecode(r.body) as List;
      }
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD2C9D4),
      appBar: AppBar(
        title: const Text('Fichamentos Públicos'),
        backgroundColor: const Color(0xFF4F3466),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _busca,
                    decoration: const InputDecoration(
                      labelText: 'Buscar por título, autor ou gênero',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _buscar(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _buscar,
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF947CAC),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 0, color: Color(0xFF947CAC)),

          // Lista de fichamentos
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4F3466),
                    ),
                  )
                : itens.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum fichamento público encontrado.',
                          style: TextStyle(color: Color(0xFF4F3466)),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _buscar,
                        color: const Color(0xFF4F3466),
                        child: ListView.builder(
                          itemCount: itens.length,
                          itemBuilder: (_, i) {
                            final f = itens[i] as Map;
                            final capa = (f['capa_url'] ?? '').toString();
                            final titulo = (f['titulo'] ?? '').toString();
                            final user = (f['usuario_nome'] ?? '').toString();
                            final frase =
                                (f['frase_favorita'] ?? '').toString();
                            final nota = f['nota']?.toString() ?? '-';
                            final List generos =
                                (f['generos'] ?? []) as List;

                            return Card(
                              color: const Color(0xFFCABCD7),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: Color(0xFF947CAC),
                                  width: 0.8,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(10),
                                leading: capa.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          capa,
                                          width: 50,
                                          height: 70,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.menu_book,
                                        size: 45,
                                        color: Color(0xFF4F3466),
                                      ),
                                title: Text(
                                  titulo.isNotEmpty ? titulo : 'Fichamento',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4F3466),
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Usuário: ${user.isNotEmpty ? user : '-'} • Nota: $nota',
                                        style: const TextStyle(
                                          color: Color(0xFF5B3765),
                                        ),
                                      ),
                                      if (frase.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            '“$frase”',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontStyle: FontStyle.italic,
                                              color: Color(0xFF5B3765),
                                            ),
                                          ),
                                        ),
                                      if (generos.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 6),
                                          child: Wrap(
                                            spacing: 6,
                                            runSpacing: -8,
                                            children: generos
                                                .map(
                                                  (g) => Chip(
                                                    label: Text('$g'),
                                                    backgroundColor:
                                                        const Color(
                                                            0xFFE9E0EF),
                                                    labelStyle:
                                                        const TextStyle(
                                                      color:
                                                          Color(0xFF4F3466),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FichamentoDetalhesScreen(
                                      idFichamento: f['id_fichamento'],
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
