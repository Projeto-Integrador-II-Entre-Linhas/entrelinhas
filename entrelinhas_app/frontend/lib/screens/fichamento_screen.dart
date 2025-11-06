import 'package:flutter/material.dart';
import '../models/fichamento.dart';
import '../services/fichamento_service.dart';

class FichamentoScreen extends StatefulWidget {
  final Fichamento? fichamento;
  FichamentoScreen({this.fichamento});

  @override
  _FichamentoScreenState createState() => _FichamentoScreenState();
}

class _FichamentoScreenState extends State<FichamentoScreen> {
  final _introController = TextEditingController();
  final _narrativaController = TextEditingController();
  final FichamentoService service = FichamentoService();
  bool loading = false;

  void salvar() async {
    setState(() => loading = true);

    final fichamento = Fichamento(
      id: widget.fichamento?.id,
      idUsuario: 1, // pegar do usuário logado
      idLivro: 1, // pegar do livro selecionado
      introducao: _introController.text,
      narrativa: _narrativaController.text,
      dataInicio: DateTime.now(),
      formato: 'físico',
      nota: 5
    );

    bool success = widget.fichamento == null
        ? await service.criarFichamento(fichamento)
        : await service.atualizarFichamento(fichamento);

    setState(() => loading = false);
    if(success) Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    if(widget.fichamento != null){
      _introController.text = widget.fichamento!.introducao;
      _narrativaController.text = widget.fichamento!.narrativa ?? '';
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('Fichamento')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _introController, decoration: InputDecoration(labelText:'Introdução')),
            TextField(controller: _narrativaController, decoration: InputDecoration(labelText:'Narrativa')),
            SizedBox(height:16),
            loading ? CircularProgressIndicator() : ElevatedButton(onPressed: salvar, child: Text('Salvar'))
          ],
        ),
      ),
    );
  }
}
