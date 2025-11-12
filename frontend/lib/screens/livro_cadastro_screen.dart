import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import '../services/livro_service.dart';
import 'solicitacao_form_screen.dart';
import 'livro_lista_screen.dart';

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

  // URL padrão para livros sem capa
  final String capaPadrao =
      'https://i.pinimg.com/736x/da/8f/b2/da8fb239479856a78bdd048d038486be.jpg';

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

    try {
      final response = await service.api.post('livros/isbn', {'isbn': isbn});
      setState(() => loading = false);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Livro cadastrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        // Redireciona para a lista de livros
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LivroListaScreen()),
          );
        });
      } else if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este livro já está cadastrado.'),
            backgroundColor: Colors.amber,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cadastrar livro (${response.statusCode}).'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro inesperado: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _mostrarSolicitacao(String termo) {
    final isISBN = RegExp(r'^\d{9,13}$').hasMatch(termo);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SolicitacaoFormScreen(
          termo: termo,
          isISBN: isISBN,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD2C9D4),
      appBar: AppBar(
        title: const Text(
          'Buscar ou Cadastrar Livro',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4F3466),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _buscaController,
                  decoration: InputDecoration(
                    labelText: 'Buscar por título ou ISBN',
                    labelStyle: const TextStyle(color: Color(0xFF4F3466)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF4F3466)),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF947CAC)),
                    ),
                  ),
                  onSubmitted: (_) => buscar(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: scan,
                icon:
                    const Icon(Icons.qr_code_scanner, color: Color(0xFF4F3466)),
                tooltip: 'Ler código de barras',
              ),
              IconButton(
                onPressed: buscar,
                icon: const Icon(Icons.search, color: Color(0xFF4F3466)),
                tooltip: 'Buscar',
              ),
            ]),
            const SizedBox(height: 16),
            if (loading)
              const LinearProgressIndicator(color: Color(0xFF4F3466)),
            const SizedBox(height: 8),

            // Resultado
            Expanded(
              child: resultados.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum livro encontrado.',
                        style: TextStyle(color: Color(0xFF4F3466)),
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFF4F3466),
                      onRefresh: buscar,
                      child: ListView.builder(
                        itemCount: resultados.length,
                        itemBuilder: (context, index) {
                          final livro = resultados[index];
                          final titulo = livro['titulo'] ?? 'Sem título';
                          final autores = (livro['autores'] is List)
                              ? (livro['autores'] as List).join(', ')
                              : livro['autores'] ?? 'Autor desconhecido';

                          final capa =
                              (livro['capa_url']?.toString().isNotEmpty ??
                                      false)
                                  ? livro['capa_url']
                                  : (livro['capaUrl']?.toString().isNotEmpty ??
                                          false)
                                      ? livro['capaUrl']
                                      : capaPadrao;

                          return Card(
                            color: const Color(0xFFCABCD7),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                color: Color(0xFF947CAC),
                                width: 0.8,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(8),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  capa,
                                  width: 50,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                    Icons.book,
                                    size: 40,
                                    color: Color(0xFF4F3466),
                                  ),
                                ),
                              ),
                              title: Text(
                                titulo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4F3466),
                                ),
                              ),
                              subtitle: Text(
                                autores,
                                style: const TextStyle(
                                  color: Color(0xFF5B3765),
                                ),
                              ),
                              onTap: () => cadastrarLivro(livro),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
