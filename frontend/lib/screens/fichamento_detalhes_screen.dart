import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/fichamento_service.dart';
import '../services/api_service.dart';
import 'fichamento_screen.dart';
import 'livro_detalhes_screen.dart';

class FichamentoDetalhesScreen extends StatefulWidget {
  final int idFichamento;

  const FichamentoDetalhesScreen({
    super.key,
    required this.idFichamento,
  });

  @override
  State<FichamentoDetalhesScreen> createState() =>
      _FichamentoDetalhesScreenState();
}

class _FichamentoDetalhesScreenState extends State<FichamentoDetalhesScreen> {
  final FichamentoService service = FichamentoService();
  final ApiService api = ApiService();
  final storage = const FlutterSecureStorage();

  Map? f;
  int? meuId;
  bool loading = true;
  bool favoritado = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _carregar();
  }

  Future<void> _loadUser() async {
    try {
      final userJson = await storage.read(key: 'user');
      if (userJson != null) {
        final u = jsonDecode(userJson);
        setState(() => meuId = u['id_usuario']);
      }
    } catch (_) {}
  }

  Future<void> _carregar() async {
    setState(() => loading = true);
    final data = await service.getDetalhe(widget.idFichamento);
    setState(() {
      f = data;
      loading = false;
    });
    if (meuId != null) _checkFavorito();
  }

  Future<void> _checkFavorito() async {
    try {
      final r = await api.get('favoritos/${widget.idFichamento}');
      if (r.statusCode == 200) {
        final json = jsonDecode(r.body);
        setState(() => favoritado = json['favoritado']);
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorito() async {
    try {
      final r = await api.post('favoritos/${widget.idFichamento}', {});
      if (r.statusCode == 200) {
        final json = jsonDecode(r.body);
        setState(() => favoritado = json['favoritado']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              favoritado
                  ? 'Adicionado aos favoritos 💜'
                  : 'Removido dos favoritos 💔',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao alternar favorito')),
      );
    }
  }

  Future<void> _excluir() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Fichamento'),
        content:
            const Text('Tem certeza que deseja excluir este fichamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final resp = await api.delete('fichamentos/${f!['id_fichamento']}');
    if (resp.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fichamento excluído com sucesso.')),
        );
        Navigator.pop(context, true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: ${resp.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFD2C9D4),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (f == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFD2C9D4),
        body: Center(child: Text('Fichamento não encontrado')),
      );
    }

    final bool meu = f!['id_usuario'] == meuId;
    final capa = (f!['capa_url'] ?? '').toString();
    final titulo = f!['titulo'] ?? 'Sem título';
    final autor = f!['autor'] ?? 'Autor desconhecido';

    return Scaffold(
      backgroundColor: const Color(0xFFD2C9D4),
      appBar: AppBar(
        title: const Text('Detalhes do Fichamento'),
        backgroundColor: const Color(0xFF4F3466),
        actions: [
          if (!meu)
            IconButton(
              icon: Icon(
                favoritado ? Icons.favorite : Icons.favorite_border,
                color: favoritado ? Colors.pinkAccent : Colors.white,
              ),
              onPressed: _toggleFavorito,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (capa.isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(capa, height: 220, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 12),

            Text(
              titulo,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F3466),
              ),
            ),
            Text(
              'Autor: $autor',
              style: const TextStyle(color: Color(0xFF5B3765)),
            ),
            const Divider(height: 24, color: Color(0xFF947CAC)),

            _campo('Introdução', f!['introducao']),
            _campo('Cenário', f!['espaco']),
            _campo('Personagens', f!['personagens']),
            _campo('Narrativa', f!['narrativa']),
            _campo('Críticas', f!['conclusao']),
            _campo('Frase favorita', f!['frase_favorita']),
            _campo('Formato', f!['formato']),
            _campo('Nota', f!['nota']?.toString()),
            _campo('Visibilidade', f!['visibilidade']),

            // Gêneros relacionados do livro
            if (f!['generos'] != null && (f!['generos'] as List).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gêneros relacionados',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F3466),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: -8,
                      children: (f!['generos'] as List)
                          .map<Widget>(
                            (g) => Chip(
                              label: Text('$g'),
                              backgroundColor: const Color(0xFFE9E0EF),
                              labelStyle:
                                  const TextStyle(color: Color(0xFF4F3466)),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
            const Divider(color: Color(0xFF4F3466)),

            if (meu) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF947CAC),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FichamentoScreen(
                        fichamentoExistente: f,
                      ),
                    ),
                  ).then((_) => _carregar());
                },
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text(
                  'Editar Fichamento',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _excluir,
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text(
                  'Excluir Fichamento',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
            ],

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F3466),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LivroDetalhesScreen(
                      livro: {
                        'id_livro': f!['id_livro'],
                        'titulo': f!['titulo'],
                        'autor': f!['autor'],
                        'capa_url': f!['capa_url'],
                        'descricao': f!['descricao'] ?? '',
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.auto_stories, color: Colors.white),
              label: const Text(
                'Ver detalhes do livro',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(String label, String? valor) {
    if (valor == null || valor.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4F3466),
            ),
          ),
          Text(
            valor,
            style: const TextStyle(color: Color(0xFF2E1A3A)),
          ),
        ],
      ),
    );
  }
}
