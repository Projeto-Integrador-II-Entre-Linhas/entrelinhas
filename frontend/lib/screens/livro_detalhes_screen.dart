import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../services/livro_service.dart';
import 'fichamento_screen.dart';
import 'fichamentos_livro_screen.dart';

class LivroDetalhesScreen extends StatefulWidget {
  final Map livro;
  const LivroDetalhesScreen({super.key, required this.livro});

  @override
  State<LivroDetalhesScreen> createState() => _LivroDetalhesScreenState();
}

class _LivroDetalhesScreenState extends State<LivroDetalhesScreen> {
  final ApiService api = ApiService();
  final LivroService livroService = LivroService();

  Map? livro;
  List fichamentos = [];
  bool loading = true;
  String perfil = 'COMUM';
  bool _descricaoExpandida = false;

  @override
  void initState() {
    super.initState();
    _carregarDetalhes();
    _loadPerfil();
  }

  Future<void> _loadPerfil() async {
    try {
      const storage = FlutterSecureStorage();
      final userJson = await storage.read(key: 'user');
      if (userJson != null) {
        final u = jsonDecode(userJson) as Map<String, dynamic>;
        setState(() => perfil = (u['perfil'] ?? 'COMUM').toString());
      }
    } catch (_) {}
  }

  Future<void> _carregarDetalhes() async {
    final idLivro = widget.livro['id_livro'] ?? widget.livro['id'] ?? 0;
    if (idLivro == 0) return;

    setState(() => loading = true);
    try {
      final res = await api.get('livros/$idLivro');
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          livro = data['livro'];
          fichamentos = List.from(data['fichamentos'] ?? []);
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (_) {
      setState(() => loading = false);
    }
  }

  // Modal
  void _mostrarModalAcoes(int idLivro) {
    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (_) {
        return Dialog(
          backgroundColor: const Color(0xFFF6DDEB),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'O que deseja fazer?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F3466),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _modalButton(
                  label: 'Criar Novo Fichamento',
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FichamentoScreen(livroId: idLivro),
                      ),
                    ).then((_) => _carregarDetalhes());
                  },
                ),
                const SizedBox(height: 12),
                _modalButton(
                  label: 'Ver Fichamentos Relacionados',
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            FichamentosDoLivroScreen(idLivro: idLivro),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _modalButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F3466),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 4,
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  // Editar
  Future<void> _editarLivroDialog() async {
    if (livro == null) return;

    final t = TextEditingController(text: livro!['titulo'] ?? '');
    final a = TextEditingController(text: livro!['autor'] ?? '');
    final e = TextEditingController(text: (livro!['editora'] ?? '').toString());
    final ano =
        TextEditingController(text: (livro!['ano_publicacao'] ?? '').toString());
    final capa =
        TextEditingController(text: (livro!['capa_url'] ?? '').toString());
    final desc =
        TextEditingController(text: (livro!['descricao'] ?? '').toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar livro (ADMIN)'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: t,
                  decoration: const InputDecoration(labelText: 'Título')),
              TextField(
                  controller: a,
                  decoration: const InputDecoration(labelText: 'Autor')),
              TextField(
                  controller: e,
                  decoration: const InputDecoration(labelText: 'Editora')),
              TextField(
                  controller: ano,
                  decoration:
                      const InputDecoration(labelText: 'Ano Publicação')),
              TextField(
                  controller: capa,
                  decoration:
                      const InputDecoration(labelText: 'URL da Capa')),
              TextField(
                controller: desc,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar')),
        ],
      ),
    );

    if (ok != true) return;

    final idLivro = livro!['id_livro'];
    final body = {
      'titulo': t.text.trim(),
      'autor': a.text.trim(),
      'editora': e.text.trim(),
      'ano_publicacao': int.tryParse(ano.text.trim()),
      'capa_url': capa.text.trim(),
      'descricao': desc.text.trim(),
    };

    final okUpdate = await livroService.adminUpdateLivro(idLivro, body);
    if (okUpdate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Livro atualizado com sucesso.')),
      );
      _carregarDetalhes();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao atualizar livro.')),
      );
    }
  }

  // Excluir
  Future<void> _excluirLivro() async {
    if (livro == null) return;
    final idLivro = livro!['id_livro'];

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir livro'),
        content: const Text(
          'Tem certeza que deseja excluir este livro? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final okDelete = await livroService.adminDeleteLivro(idLivro);
    if (okDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Livro excluído com sucesso.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao excluir livro.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final idLivro =
        livro?['id_livro'] ?? widget.livro['id_livro'] ?? widget.livro['id'] ?? 0;
    final capa = (livro?['capa_url'] ?? '').toString();

    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFD2C9D4),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4F3466)),
        ),
      );
    }

    if (livro == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFD2C9D4),
        body: Center(child: Text('Livro não encontrado')),
      );
    }

    final descricao = (livro!['descricao'] ?? '').toString();
    final generos = (livro!['generos'] ?? []) as List;
    final generoTexto =
        generos.isNotEmpty ? generos.join(", ") : "Não informado";

    return Scaffold(
      backgroundColor: const Color(0xFFD2C9D4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4F3466),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Entre Linhas",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final largura = constraints.maxWidth;
          final capaLargura = largura * 0.50;
          final capaAltura = capaLargura * 1.55;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // CAPA
                    Align(
                      alignment: Alignment.topCenter,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(6),
                          child: Image.network(
                            capa,
                            width: capaLargura,
                            height: capaAltura,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.menu_book,
                              size: 80,
                              color: Color(0xFF4F3466),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // BOTÃO "+"
                    Positioned(
                      top: capaAltura * 0.40,
                      right: largura * 0.05,
                      child: GestureDetector(
                        onTap: () => _mostrarModalAcoes(idLivro),
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F3466),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 5,
                                offset: Offset(2, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  livro!['titulo'] ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF4F3466),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  livro!['autor'] ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF8B6C9B),
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 26),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6DDEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFB085B5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _info("ISBN", livro!['isbn']),
                      _info("Ano Publicação", livro!['ano_publicacao']),
                      _info("Editora", livro!['editora']),
                      _info("Idioma", livro!['idioma']),
                      _info("Gênero", generoTexto),
                      _info("Número de Páginas", livro!['num_paginas']),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _cardDescricao(descricao),

                if (perfil == "ADMIN") _adminSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cardInfo(List<Widget> itens) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6DDEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB085B5)),
      ),
      child: Column(children: itens),
    );
  }

  Widget _info(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(
            text: "$label: ",
            style: const TextStyle(
              color: Color(0xFF4F3466),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          TextSpan(
            text: value?.toString() ?? "-",
            style: const TextStyle(
              color: Color.fromARGB(255, 85, 43, 97),
              fontSize: 14,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _cardDescricao(String descricao) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6DDEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB085B5)),
      ),
      child: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: Text(
              descricao.isNotEmpty ? descricao : "Nenhuma descrição.",
              style: const TextStyle(
                color: Color(0xFF4F3466),
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: _descricaoExpandida ? null : 4,
              overflow: _descricaoExpandida
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () =>
                setState(() => _descricaoExpandida = !_descricaoExpandida),
            icon: Icon(
              _descricaoExpandida
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: const Color(0xFF4F3466),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminSection() {
    return Column(
      children: [
        const Divider(color: Color(0xFF4F3466)),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Administração do Livro",
            style: TextStyle(
              color: Color(0xFF4F3466),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF947CAC),
                ),
                onPressed: _editarLivroDialog,
                child: const Text("Editar"),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: _excluirLivro,
                child: const Text("Excluir"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

