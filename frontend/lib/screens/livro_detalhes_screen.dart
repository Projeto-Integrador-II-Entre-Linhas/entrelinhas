import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/livro_service.dart';
import 'fichamento_screen.dart';
import 'fichamentos_livro_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  @override
  void initState() {
    super.initState();
    _carregarDetalhes();
    _loadPerfil();
  }

  Future<void> _loadPerfil() async {
    try {
      final storage = const FlutterSecureStorage();
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
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> _editarLivroDialog() async {
    if (livro == null) return;

    final t = TextEditingController(text: livro!['titulo'] ?? '');
    final a = TextEditingController(text: livro!['autor'] ?? '');
    final e = TextEditingController(text: (livro!['editora'] ?? '').toString());
    final ano = TextEditingController(text: (livro!['ano_publicacao'] ?? '').toString());
    final capa = TextEditingController(text: (livro!['capa_url'] ?? '').toString());
    final desc = TextEditingController(text: (livro!['descricao'] ?? '').toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar livro (ADMIN)'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: t, decoration: const InputDecoration(labelText: 'Título')),
              TextField(controller: a, decoration: const InputDecoration(labelText: 'Autor')),
              TextField(controller: e, decoration: const InputDecoration(labelText: 'Editora')),
              TextField(controller: ano, decoration: const InputDecoration(labelText: 'Ano publicação')),
              TextField(controller: capa, decoration: const InputDecoration(labelText: 'URL da Capa')),
              TextField(controller: desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Descrição')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salvar')),
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Excluir')),
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
    final idLivro = widget.livro['id_livro'] ?? widget.livro['id'] ?? 0;

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF4F3466))),
      );
    }

    if (livro == null) {
      return const Scaffold(body: Center(child: Text('Livro não encontrado')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFD2C9D4),
      appBar: AppBar(
        title: Text(livro!['titulo'] ?? 'Detalhes do Livro'),
        backgroundColor: const Color(0xFF4F3466),
        actions: [
          if (perfil == 'ADMIN')
            IconButton(onPressed: _editarLivroDialog, icon: const Icon(Icons.edit, color: Colors.white)),
          if (perfil == 'ADMIN')
            IconButton(onPressed: _excluirLivro, icon: const Icon(Icons.delete, color: Colors.white)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if ((livro!['capa_url'] ?? '').toString().isNotEmpty)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(livro!['capa_url'], height: 220, fit: BoxFit.cover),
              ),
            ),
          const SizedBox(height: 16),
          Text(livro!['titulo'] ?? 'Sem título',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4F3466))),
          const SizedBox(height: 8),
          Text('Autor: ${livro!['autor'] ?? 'Desconhecido'}', style: const TextStyle(color: Color(0xFF5B3765))),
          Text('Editora: ${livro!['editora'] ?? 'N/A'}', style: const TextStyle(color: Color(0xFF5B3765))),
          Text('Ano: ${livro!['ano_publicacao'] ?? 'N/A'}', style: const TextStyle(color: Color(0xFF5B3765))),
          const SizedBox(height: 16),
          Text(
            livro!['descricao'] ?? 'Sem descrição disponível.',
            style: const TextStyle(fontSize: 16, color: Color(0xFF4F3466)),
          ),
          const SizedBox(height: 24),

          // --- Botões de ação ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF947CAC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: idLivro == 0
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => FichamentoScreen(livroId: idLivro)),
                      ).then((_) => _carregarDetalhes());
                    },
              icon: const Icon(Icons.edit),
              label: const Text('Criar/Editar meu fichamento'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF947CAC)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: idLivro == 0
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => FichamentosDoLivroScreen(idLivro: idLivro)),
                      );
                    },
              icon: const Icon(Icons.list_alt, color: Color(0xFF4F3466)),
              label: const Text('Ver fichamentos públicos',
                  style: TextStyle(color: Color(0xFF4F3466))),
            ),
          ),

          if (fichamentos.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Fichamentos públicos deste livro',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4F3466))),
            const SizedBox(height: 8),
            ...fichamentos.map((fi) => Card(
                  color: const Color(0xFFCABCD7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: (fi['capa_url'] ?? '').toString().isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(fi['capa_url'], width: 45, height: 65, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.menu_book, color: Color(0xFF4F3466)),
                    title: Text(fi['titulo'] ?? 'Fichamento',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF4F3466))),
                    subtitle: Text(
                      'Usuário: ${fi['usuario_nome'] ?? '-'} • Nota: ${fi['nota'] ?? '-'}'
                      '${(fi['frase_favorita'] ?? '').toString().isNotEmpty ? '\n“${fi['frase_favorita']}”' : ''}',
                      style: const TextStyle(color: Color(0xFF5B3765)),
                    ),
                  ),
                )),
          ],
        ]),
      ),
    );
  }
}
