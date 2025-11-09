import 'package:flutter/material.dart';
import '../services/fichamento_service.dart';

class FichamentoDetalhesScreen extends StatefulWidget {
  final int idFichamento;
  const FichamentoDetalhesScreen({super.key, required this.idFichamento});

  @override
  State<FichamentoDetalhesScreen> createState() => _FichamentoDetalhesScreenState();
}

class _FichamentoDetalhesScreenState extends State<FichamentoDetalhesScreen> {
  final FichamentoService service = FichamentoService();
  Map? f;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => loading = true);
    final data = await service.getDetalhe(widget.idFichamento);
    setState(() {
      f = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (f == null) return const Scaffold(body: Center(child: Text('Fichamento não encontrado')));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Fichamento')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Introdução', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(f!['introducao'] ?? ''),
            const SizedBox(height: 12),
            Text('Cenário', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(f!['espaco'] ?? ''),
            const SizedBox(height: 12),
            Text('Personagens', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(f!['personagens'] ?? ''),
            const SizedBox(height: 12),
            Text('Narrativa', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(f!['narrativa'] ?? ''),
            const SizedBox(height: 12),
            Text('Críticas', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(f!['conclusao'] ?? ''),
            const SizedBox(height: 12),
            Text('Frase Favorita: ${f!['frase_favorita'] ?? '-'}'),
            const SizedBox(height: 12),
            Text('Formato: ${f!['formato'] ?? '-'}'),
            const SizedBox(height: 12),
            Text('Nota: ${f!['nota'] ?? '-'}'),
            const SizedBox(height: 12),
            Text('Visibilidade: ${f!['visibilidade'] ?? '-'}'),
          ],
        ),
      ),
    );
  }
}
