// lib/screens/fichamentos_livro_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'fichamento_screen.dart';

class FichamentosDoLivroScreen extends StatefulWidget {
  final int idLivro;
  const FichamentosDoLivroScreen({super.key, required this.idLivro});

  @override
  State<FichamentosDoLivroScreen> createState() => _FichamentosDoLivroScreenState();
}

class _FichamentosDoLivroScreenState extends State<FichamentosDoLivroScreen> {
  final ApiService api = ApiService();
  List fichamentos = [];
  bool loading = true;
  int? myUserId;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _carregar();
  }

  Future<void> _loadUser() async {
    try {
      final res = await api.get('users/me');
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final me = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() => myUserId = me['id_usuario']);
      }
    } catch (_) {}
  }

  Future<void> _carregar() async {
    setState(() => loading = true);
    try {
      final r = await api.get('livros/${widget.idLivro}');
      if (r.statusCode == 200 && r.body.isNotEmpty) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        setState(() {
          fichamentos = List.from(data['fichamentos'] ?? []);
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> _excluir(int idFichamento) async {
    final resp = await api.delete('fichamentos/$idFichamento');
    if (resp.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fichamento excluído com sucesso.')),
      );
      _carregar();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: ${resp.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD2C9D4),
      appBar: AppBar(
        title: const Text('Fichamentos do livro'),
        backgroundColor: const Color(0xFF4F3466),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F3466)))
          : RefreshIndicator(
              onRefresh: _carregar,
              color: const Color(0xFF4F3466),
              child: fichamentos.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Nenhum fichamento público disponível para este livro.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF4F3466)),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: fichamentos.length,
                      itemBuilder: (_, i) {
                        final f = fichamentos[i];
                        final meu = (myUserId != null && f['id_usuario'] == myUserId);
                        final capa = (f['capa_url'] ?? '').toString();
                        final titulo = (f['titulo'] ?? '').toString();
                        final user = (f['usuario_nome'] ?? '').toString();
                        final frase = (f['frase_favorita'] ?? '').toString();
                        final nota = f['nota']?.toString() ?? '-';

                        return Card(
                          color: const Color(0xFFCABCD7),
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFF947CAC), width: 0.8),
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
                                : const Icon(Icons.menu_book, size: 45, color: Color(0xFF4F3466)),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Usuário: ${user.isNotEmpty ? user : '-'} • Nota: $nota',
                                    style: const TextStyle(color: Color(0xFF5B3765)),
                                  ),
                                  if (frase.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '“$frase”',
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Color(0xFF5B3765),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            trailing: meu
                                ? Wrap(
                                    children: [
                                      IconButton(
                                        tooltip: 'Editar',
                                        icon: const Icon(Icons.edit,
                                            color: Color(0xFF947CAC)),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => FichamentoScreen(
                                                fichamentoExistente: {
                                                  ...f,
                                                  'id_fichamento': f['id_fichamento'],
                                                  'id_livro': f['id_livro'],
                                                },
                                              ),
                                            ),
                                          ).then((_) => _carregar());
                                        },
                                      ),
                                      IconButton(
                                        tooltip: 'Excluir',
                                        icon: const Icon(Icons.delete,
                                            color: Color(0xFF5B3765)),
                                        onPressed: () => _excluir(f['id_fichamento']),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
