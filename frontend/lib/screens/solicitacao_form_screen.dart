import 'package:flutter/material.dart';
import '../services/solicitacao_service.dart';

class SolicitacaoFormScreen extends StatefulWidget {
  final String termo;
  final bool isISBN;

  const SolicitacaoFormScreen({
    super.key,
    required this.termo,
    this.isISBN = false,
  });

  @override
  State<SolicitacaoFormScreen> createState() => _SolicitacaoFormScreenState();
}

class _SolicitacaoFormScreenState extends State<SolicitacaoFormScreen> {
  final _titulo = TextEditingController();
  final _autor = TextEditingController();
  final _isbn = TextEditingController();
  final _ano = TextEditingController();
  final _editora = TextEditingController();
  final _descricao = TextEditingController();
  final _idioma = TextEditingController();
  final _paginas = TextEditingController();
  final _capa = TextEditingController();
  final _generos = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isISBN) {
      _isbn.text = widget.termo;
    } else {
      _titulo.text = widget.termo;
    }
  }

  Future<void> _enviar() async {
    if (_titulo.text.isEmpty ||
        _autor.text.isEmpty ||
        _isbn.text.isEmpty ||
        _ano.text.isEmpty ||
        _editora.text.isEmpty) {
      _msg('Preencha os campos obrigatórios');
      return;
    }
    setState(() => loading = true);
    try {
      final body = {
        'titulo': _titulo.text.trim(),
        'autor': _autor.text.trim(),
        'isbn': _isbn.text.trim(),
        'ano_publicacao': int.tryParse(_ano.text.trim()),
        'editora': _editora.text.trim(),
        'descricao': _descricao.text.trim(),
        'idioma': _idioma.text.trim(),
        'num_paginas': int.tryParse(_paginas.text.trim()),
        'capa_url': _capa.text.trim(),
        'generos': _generos.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      };
      final ok = await SolicitacaoService().criarSolicitacao(body);
      if (ok != null) {
        _msg('Solicitação enviada com sucesso!');
        Navigator.pop(context);
      } else {
        _msg('Falha ao enviar solicitação');
      }
    } catch (e) {
      _msg('Erro: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Widget _req(String label, TextEditingController c) =>
      TextField(controller: c, decoration: InputDecoration(labelText: '$label *'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar cadastro de livro'),
        backgroundColor: const Color(0xFF4F3466),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _req('Título', _titulo),
          const SizedBox(height: 8),
          _req('Autor', _autor),
          const SizedBox(height: 8),
          _req('ISBN', _isbn),
          const SizedBox(height: 8),
          _req('Ano de publicação', _ano),
          const SizedBox(height: 8),
          _req('Editora', _editora),
          const SizedBox(height: 8),
          TextField(
              controller: _descricao,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Descrição')),
          const SizedBox(height: 8),
          TextField(
              controller: _idioma,
              decoration: const InputDecoration(labelText: 'Idioma')),
          const SizedBox(height: 8),
          TextField(
              controller: _paginas,
              decoration: const InputDecoration(labelText: 'Nº de páginas')),
          const SizedBox(height: 8),
          TextField(
              controller: _capa,
              decoration:
                  const InputDecoration(labelText: 'URL da Capa (opcional)')),
          const SizedBox(height: 8),
          TextField(
              controller: _generos,
              decoration: const InputDecoration(
                  labelText: 'Gêneros (separados por vírgula)')),
          const SizedBox(height: 16),
          loading
              ? const CircularProgressIndicator(color: Color(0xFF4F3466))
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF947CAC),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: _enviar,
                  child: const SizedBox(
                      width: double.infinity,
                      child: Center(child: Text('Enviar solicitação'))),
                ),
        ]),
      ),
    );
  }
}
