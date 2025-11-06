import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import '../services/livro_service.dart';

class LivroCadastroScreen extends StatefulWidget {
  @override
  _LivroCadastroScreenState createState() => _LivroCadastroScreenState();
}

class _LivroCadastroScreenState extends State<LivroCadastroScreen> {
  final _isbnController = TextEditingController();
  final _tituloController = TextEditingController();
  final _autorController = TextEditingController();
  final _editoraController = TextEditingController();
  final _anoController = TextEditingController();
  final LivroService livroService = LivroService();
  bool loading = false;

  void buscarLivro() async {
    setState(() => loading = true);
    final info = await livroService.buscarLivroPorISBN(_isbnController.text);
    setState(() => loading = false);

    if(info != null){
      _tituloController.text = info['title'] ?? '';
      _autorController.text = (info['authors'] ?? []).join(', ');
      _editoraController.text = info['publisher'] ?? '';
      _anoController.text = info['publishedDate']?.split('-')[0] ?? '';
    } else {
      showDialog(context: context, builder: (_) => AlertDialog(title: Text('Não encontrado'), content: Text('Livro não encontrado na API Google Books'), actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: Text('Ok'))]));
    }
  }

  void escanearISBN() async {
    final result = await BarcodeScanner.scan();
    _isbnController.text = result.rawContent;
    buscarLivro();
  }

  void salvarLivro() async {
    final livro = {
      'isbn': _isbnController.text,
      'titulo': _tituloController.text,
      'autor': _autorController.text,
      'editora': _editoraController.text,
      'ano_publicacao': int.tryParse(_anoController.text) ?? 0
    };
    bool success = await livroService.cadastrarLivro(livro);
    if(success) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('Cadastro de Livro')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: TextField(controller: _isbnController, decoration: InputDecoration(labelText:'ISBN'))),
                IconButton(onPressed: escanearISBN, icon: Icon(Icons.qr_code_scanner)),
                IconButton(onPressed: buscarLivro, icon: Icon(Icons.search))
              ],
            ),
            TextField(controller: _tituloController, decoration: InputDecoration(labelText:'Título')),
            TextField(controller: _autorController, decoration: InputDecoration(labelText:'Autor')),
            TextField(controller: _editoraController, decoration: InputDecoration(labelText:'Editora')),
            TextField(controller: _anoController, decoration: InputDecoration(labelText:'Ano')),
            SizedBox(height:16),
            ElevatedButton(onPressed: salvarLivro, child: Text('Salvar')),
          ],
        ),
      ),
    );
  }
}
