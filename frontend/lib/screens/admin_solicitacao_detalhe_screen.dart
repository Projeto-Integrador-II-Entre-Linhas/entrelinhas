import 'package:flutter/material.dart';
import '../services/solicitacao_service.dart';

class AdminSolicitacaoDetalheScreen extends StatefulWidget {
  final int idSolicitacao;
  const AdminSolicitacaoDetalheScreen({super.key, required this.idSolicitacao});

  @override
  State<AdminSolicitacaoDetalheScreen> createState() => _AdminSolicitacaoDetalheScreenState();
}

class _AdminSolicitacaoDetalheScreenState extends State<AdminSolicitacaoDetalheScreen> {
  final s = SolicitacaoService();
  Map? data;
  bool loading = true;

  final _titulo = TextEditingController();
  final _autor = TextEditingController();
  final _isbn = TextEditingController();
  final _ano = TextEditingController();
  final _editora = TextEditingController();
  final _descricao = TextEditingController();
  final _idioma = TextEditingController();
  final _paginas = TextEditingController();
  final _capa = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(()=>loading=true);
    final d = await s.detalhe(widget.idSolicitacao);
    if (d != null) {
      setState(()=> data = d);
      _titulo.text = (d['titulo'] ?? '').toString();
      _autor.text = (d['autor'] ?? '').toString();
      _isbn.text = (d['isbn'] ?? '').toString();
      _ano.text = (d['ano_publicacao'] ?? '').toString();
      _editora.text = (d['editora'] ?? '').toString();
      _descricao.text = (d['descricao'] ?? '').toString();
      _idioma.text = (d['idioma'] ?? '').toString();
      _paginas.text = (d['num_paginas'] ?? '').toString();
      _capa.text = (d['capa_url'] ?? '').toString();
    }
    setState(()=>loading=false);
  }

  Future<void> _salvar() async {
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
    };
    final ok = await s.atualizar(widget.idSolicitacao, body);
    _msg(ok ? 'Atualizado' : 'Falha ao atualizar');
    if (ok) _load();
  }

  Future<void> _aprovar() async {
    final ok = await s.aprovar(widget.idSolicitacao);
    _msg(ok ? 'Aprovada' : 'Falha');
    if (ok) Navigator.pop(context);
  }

  Future<void> _rejeitar() async {
    final motivo = await showDialog<String>(context: context, builder: (_){
      final c = TextEditingController();
      return AlertDialog(
        title: const Text('Motivo da rejeição'),
        content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Opcional')),
        actions: [
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: ()=> Navigator.pop(context, c.text.trim()), child: const Text('Rejeitar')),
        ],
      );
    });
    if (motivo == null) return;
    final ok = await s.rejeitar(widget.idSolicitacao, motivo: motivo.isEmpty ? null : motivo);
    _msg(ok ? 'Rejeitada' : 'Falha');
    if (ok) Navigator.pop(context);
  }

  void _msg(String m)=> ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe da Solicitação')),
      body: loading ? const Center(child: CircularProgressIndicator()) :
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _titulo, decoration: const InputDecoration(labelText: 'Título *')),
            const SizedBox(height: 8),
            TextField(controller: _autor, decoration: const InputDecoration(labelText: 'Autor *')),
            const SizedBox(height: 8),
            TextField(controller: _isbn, decoration: const InputDecoration(labelText: 'ISBN *')),
            const SizedBox(height: 8),
            TextField(controller: _ano, decoration: const InputDecoration(labelText: 'Ano *')),
            const SizedBox(height: 8),
            TextField(controller: _editora, decoration: const InputDecoration(labelText: 'Editora *')),
            const SizedBox(height: 8),
            TextField(controller: _descricao, maxLines: 3, decoration: const InputDecoration(labelText: 'Descrição')),
            const SizedBox(height: 8),
            TextField(controller: _idioma, decoration: const InputDecoration(labelText: 'Idioma')),
            const SizedBox(height: 8),
            TextField(controller: _paginas, decoration: const InputDecoration(labelText: 'Nº páginas')),
            const SizedBox(height: 8),
            TextField(controller: _capa, decoration: const InputDecoration(labelText: 'URL da capa')),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: ElevatedButton.icon(onPressed: _salvar, icon: const Icon(Icons.save), label: const Text('Salvar'))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(onPressed: _aprovar, icon: const Icon(Icons.check), label: const Text('Aprovar'))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(onPressed: _rejeitar, icon: const Icon(Icons.cancel), label: const Text('Rejeitar'))),
              ],
            )
          ],
        ),
      ),
    );
  }
}
