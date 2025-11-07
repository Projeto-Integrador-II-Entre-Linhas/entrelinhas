import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import '../services/livro_service.dart';

class LivroCadastroScreen extends StatefulWidget {
  const LivroCadastroScreen({super.key});

  @override
  State<LivroCadastroScreen> createState() => _LivroCadastroScreenState();
}

class _LivroCadastroScreenState extends State<LivroCadastroScreen> {
  final _buscaController = TextEditingController();
  final LivroService service = LivroService();

  bool loading = false;
  List resultados = [];

  Future<void> buscar() async {
    final termo = _buscaController.text.trim();
    if (termo.isEmpty) return;

    setState(() {
      loading = true;
      resultados = [];
    });

    try {
      List livros;
      if (RegExp(r'^\d+$').hasMatch(termo)) {
        livros = await service.buscarLivrosGoogle(isbn: termo);
      } else {
        livros = await service.buscarLivrosGoogle(titulo: termo);
      }

      if (livros.isEmpty) {
        _mostrarSolicitacao(termo);
        return;
      }

      setState(() => resultados = livros);
    } catch (e) {
      _mostrarSolicitacao(termo);
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> scan() async {
    final result = await BarcodeScanner.scan();
    if (result.rawContent.isNotEmpty) {
      setState(() => _buscaController.text = result.rawContent);
      await buscar();
    }
  }

  void cadastrarLivro(Map livro) async {
    final isbn = (livro['isbn'] ?? '').toString();
    if (isbn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Livro sem ISBN válido.')),
      );
      return;
    }

    setState(() => loading = true);
    final cadastrado = await service.cadastrarPorISBN(isbn);
    setState(() => loading = false);

    if (cadastrado != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Livro cadastrado com sucesso!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao cadastrar livro.')),
      );
    }
  }

  void _mostrarSolicitacao(String termo) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Livro não encontrado'),
        content: Text('Deseja solicitar o cadastro do livro "$termo"?'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await service.solicitarLivro(termo);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Solicitação enviada. Um administrador analisará.')),
              );
            },
            child: const Text('Sim'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar ou Cadastrar Livro')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _buscaController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar por título ou ISBN',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => buscar(),
                ),
              ),
              IconButton(
                onPressed: scan,
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: 'Ler código de barras',
              ),
              IconButton(
                onPressed: buscar,
                icon: const Icon(Icons.search),
                tooltip: 'Buscar',
              ),
            ]),
            const SizedBox(height: 16),
            if (loading) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Expanded(
              child: resultados.isEmpty
                  ? const Center(child: Text('Nenhum livro encontrado.'))
                  : ListView.builder(
                      itemCount: resultados.length,
                      itemBuilder: (context, index) {
                        final livro = resultados[index];
                        final titulo = livro['titulo'] ?? 'Sem título';
                        final autores = (livro['autores'] is List)
                            ? (livro['autores'] as List).join(', ')
                            : livro['autores'] ?? 'Autor desconhecido';
                        final capa = livro['capaUrl'] ??
                            'https://via.placeholder.com/100x150?text=Sem+Capa';

                        return Card(
                          child: ListTile(
                            leading: Image.network(capa, width: 50, fit: BoxFit.cover),
                            title: Text(titulo),
                            subtitle: Text(autores),
                            onTap: () => cadastrarLivro(livro),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
