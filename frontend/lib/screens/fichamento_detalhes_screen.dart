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
      if (userJson != null && mounted) {
        final u = jsonDecode(userJson);
        setState(() => meuId = u['id_usuario']);
      }
    } catch (_) {}
  }

  Future<void> _carregar() async {
    setState(() => loading = true);
    final data = await service.getDetalhe(widget.idFichamento);

    if (!mounted) return;

    setState(() {
      f = data;
      loading = false;
    });

    if (meuId != null) _checkFavorito();
  }

  Future<void> _checkFavorito() async {
    try {
      final r = await api.get('favoritos/${widget.idFichamento}');
      if (!mounted) return;

      if (r.statusCode == 200) {
        setState(() => favoritado = jsonDecode(r.body)['favoritado']);
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorito() async {
    try {
      final r = await api.post('favoritos/${widget.idFichamento}', {});
      if (!mounted) return;

      if (r.statusCode == 200) {
        final json = jsonDecode(r.body);
        setState(() => favoritado = json['favoritado']);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  favoritado ? Icons.favorite : Icons.favorite_border,
                  color: favoritado ? Colors.pinkAccent : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  favoritado
                      ? 'Adicionado aos favoritos'
                      : 'Removido dos favoritos',
                ),
              ],
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
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
        content: const Text('Tem certeza de que deseja excluir este fichamento?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
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

    if (!mounted) return;

    if (resp.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fichamento excluído com sucesso.')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: ${resp.body}')),
      );
    }
  }

  String formatarFormato(String raw) {
    switch (raw.toLowerCase()) {
      case 'fisico':
      case 'físico':
        return "Físico";
      case 'e-reader':
        return "E-reader";
      case 'audiobook':
        return "Audiobook";
      default:
        return raw;
    }
  }

  String formatarVisibilidade(String raw) {
    switch (raw.toLowerCase()) {
      case 'publico':
      case 'público':
        return "Público";
      case 'privado':
        return "Privado";
      default:
        return raw;
    }
  }

  IconData formatoIcone(String f) {
    switch (f.toLowerCase()) {
      case 'físico':
      case 'fisico':
        return Icons.menu_book;
      case 'e-reader':
        return Icons.tablet_mac;
      case 'audiobook':
        return Icons.headset;
      default:
        return Icons.book;
    }
  }

  IconData visibilidadeIcone(String v) {
    return v.toLowerCase().contains('públic')
        ? Icons.lock_open
        : Icons.lock;
  }

  Widget _badge(Widget content) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF6E4A8E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [content]),
      ),
    );
  }

  Widget _cardBase({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE3F4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 7,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _cardCampo(String titulo, String? valor) {
    if (valor == null || valor.trim().isEmpty) return const SizedBox.shrink();

    return _cardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF4F2A75),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF2E1A3A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botao({
    required String texto,
    required Color cor,
    required IconData icone,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: cor,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      onPressed: onPressed,
      icon: Icon(icone, color: Colors.white),
      label: Text(
        texto,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFDCCEE6),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6E4A8E))),
      );
    }

    if (f == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFDCCEE6),
        body: Center(child: Text('Fichamento não encontrado')),
      );
    }

    final bool meu = f!['id_usuario'] == meuId;

    final capa = (f!['capa_url'] ?? '').toString();
    final titulo = f!['titulo'] ?? 'Sem título';
    final autor = f!['autor'] ?? 'Autor desconhecido';
    final criador = f!['usuario_nome'] ?? 'Criador do fichamento';

    final formatoCorrigido = formatarFormato(f!['formato']);
    final visCorrigida = formatarVisibilidade(f!['visibilidade']);

    return Scaffold(
      backgroundColor: const Color(0xFFDCCEE6),

      appBar: AppBar(
        backgroundColor: const Color(0xFF6E4A8E),
        centerTitle: true,
        elevation: 4,
        title: const Text(
          'Detalhes do Fichamento',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (!meu)
            IconButton(
              icon: Icon(
                favoritado ? Icons.favorite : Icons.favorite_border,
                size: 28,
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
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    capa,
                    height: 240,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            const SizedBox(height: 18),

            _cardBase(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F2A75),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Autor: $autor',
                      style: const TextStyle(color: Color(0xFF6B4F82), fontSize: 16)),
                  Text('Criado por: $criador',
                      style: const TextStyle(
                          color: Color(0xFF6B4F82),
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            _cardBase(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [

                  _badge(
                    Row(children: [
                      Icon(formatoIcone(f!['formato']), size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text("Formato: $formatoCorrigido"),
                    ]),
                  ),

                  _badge(
                    Row(children: [
                      Icon(visibilidadeIcone(f!['visibilidade']),
                          size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text("Visibilidade: $visCorrigida"),
                    ]),
                  ),

                  _badge(
                    Row(children: [
                      Icon(Icons.star, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text("${f!['nota'] ?? '—'}/10"),
                    ]),
                  ),

                  if (f!['generos'] != null &&
                      (f!['generos'] as List).isNotEmpty)
                    ...((f!['generos'] as List).map((g) => _badge(Text(g)))),
                ],
              ),
            ),

            _cardCampo('Introdução', f!['introducao']),
            _cardCampo('Cenário', f!['espaco']),
            _cardCampo('Personagens', f!['personagens']),
            _cardCampo('Narrativa', f!['narrativa']),
            _cardCampo('Críticas', f!['conclusao']),
            _cardCampo('Frase favorita', f!['frase_favorita']),

            const SizedBox(height: 12),

            if (meu) ...[
              _botao(
                texto: 'Editar Fichamento',
                cor: const Color(0xFF8A68B1),
                icone: Icons.edit,
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
              ),

              const SizedBox(height: 12),

              _botao(
                texto: 'Excluir Fichamento',
                cor: Colors.red.shade400,
                icone: Icons.delete,
                onPressed: _excluir,
              ),
            ],

            const SizedBox(height: 12),

            _botao(
              texto: 'Ver detalhes do livro',
              cor: const Color(0xFF6E4A8E),
              icone: Icons.auto_stories,
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
            ),
          ],
        ),
      ),
    );
  }
}
