import 'package:flutter/material.dart';
import '../services/fichamento_service.dart';

class FichamentoScreen extends StatefulWidget {
  const FichamentoScreen({super.key});
  @override
  State<FichamentoScreen> createState() => _FichamentoScreenState();
}

class _FichamentoScreenState extends State<FichamentoScreen> {
  final _intro = TextEditingController();
  final _cenario = TextEditingController();
  final _personagens = TextEditingController();
  final _narrativa = TextEditingController();
  final _critica = TextEditingController();
  final FichamentoService service = FichamentoService();
  String formato = 'fisico';
  DateTime dataInicio = DateTime.now();
  DateTime? dataFim;
  int nota = 5;
  bool loading = false;

  void salvar() async {
    setState(()=>loading=true);
    final body = {
      'id_livro': 1, // adaptar para seleção de livro
      'introducao': _intro.text,
      'espaco': _cenario.text,
      'personagens': _personagens.text,
      'narrativa': _narrativa.text,
      'conclusao': _critica.text,
      'visibilidade': 'PRIVADO',
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim?.toIso8601String(),
      'formato': formato,
      'frase_favorita': null,
      'nota': nota
    };
    final ok = await service.criarFichamento(body);
    setState(()=>loading=false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fichamento')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        TextField(controller: _intro, decoration: const InputDecoration(labelText: 'Introdução')),
        const SizedBox(height: 8),
        TextField(controller: _cenario, decoration: const InputDecoration(labelText: 'Cenário')),
        const SizedBox(height: 8),
        TextField(controller: _personagens, decoration: const InputDecoration(labelText: 'Personagens')),
        const SizedBox(height: 8),
        TextField(controller: _narrativa, decoration: const InputDecoration(labelText: 'Narrativa')),
        const SizedBox(height: 8),
        TextField(controller: _critica, decoration: const InputDecoration(labelText: 'Críticas')),
        const SizedBox(height: 12),
        loading ? const CircularProgressIndicator() : ElevatedButton(onPressed: salvar, child: const Text('Salvar')),
      ])),
    );
  }
}
