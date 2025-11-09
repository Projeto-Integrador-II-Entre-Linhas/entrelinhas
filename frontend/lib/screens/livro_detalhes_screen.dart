import 'dart:convert'; // ✅ necessário para usar jsonDecode
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'fichamento_screen.dart';
import 'fichamento_detalhes_screen.dart';

class LivroDetalhesScreen extends StatefulWidget {
  final Map livro;
  const LivroDetalhesScreen({super.key, required this.livro});

  @override
  State<LivroDetalhesScreen> createState() => _LivroDetalhesScreenState();
}

class _LivroDetalhesScreenState extends State<LivroDetalhesScreen> {
  final ApiService api = ApiService();
  Map? livro;
  List fichamentos = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _carregarDetalhes();
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
      debugPrint('Erro ao carregar detalhes do livro: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final idLivro = widget.livro['id_livro'] ?? widget.livro['id'] ?? 0;

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (livro == null) {
      return const Scaffold(body: Center(child: Text('Livro não encontrado')));
    }

    return Scaffold(
      appBar: AppBar(title: Text(livro!['titulo'] ?? 'Detalhes do Livro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (livro!['capa_url'] != null &&
                (livro!['capa_url'] as String).isNotEmpty)
              Center(
                child: Image.network(
                  livro!['capa_url'],
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              livro!['titulo'] ?? 'Sem título',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Autor: ${livro!['autor'] ?? 'Desconhecido'}'),
            const SizedBox(height: 8),
            Text('Editora: ${livro!['editora'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Ano: ${livro!['ano_publicacao'] ?? 'N/A'}'),
            const SizedBox(height: 16),
            Text(
              livro!['descricao'] ?? 'Sem descrição disponível.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // RF07: Criar ou editar fichamento deste livro
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: idLivro == 0
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FichamentoScreen(livroId: idLivro),
                          ),
                        );
                      },
                icon: const Icon(Icons.edit),
                label: const Text('Criar/Editar meu fichamento'),
              ),
            ),

            // RF12: Fichamentos públicos associados a este livro
            if (fichamentos.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Fichamentos públicos deste livro',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...fichamentos.map((fi) => Card(
                    child: ListTile(
                      title: Text(fi['introducao'] ?? 'Fichamento'),
                      subtitle: Text('Nota: ${fi['nota'] ?? '-'}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FichamentoDetalhesScreen(
                              idFichamento: fi['id_fichamento'],
                            ),
                          ),
                        );
                      },
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
