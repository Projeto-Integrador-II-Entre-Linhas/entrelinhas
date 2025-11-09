import 'package:flutter/material.dart';
import '../services/solicitacao_service.dart';

class AdminSolicitacoesScreen extends StatefulWidget {
  const AdminSolicitacoesScreen({super.key});
  @override
  State<AdminSolicitacoesScreen> createState() => _AdminSolicitacoesScreenState();
}

class _AdminSolicitacoesScreenState extends State<AdminSolicitacoesScreen> {
  final s = SolicitacaoService();
  bool loading = true;
  List itens = [];

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(()=>loading=true);
    itens = await s.pendentes();
    setState(()=>loading=false);
  }

  Future<void> _aprovar(int id) async {
    final ok = await s.aprovar(id);
    _toast(ok ? 'Aprovada!' : 'Falha na aprovação');
    _load();
  }

  Future<void> _rejeitar(int id) async {
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
    final ok = await s.rejeitar(id, motivo: motivo.isEmpty ? null : motivo);
    _toast(ok ? 'Rejeitada.' : 'Falha na rejeição');
    _load();
  }

  void _toast(String m)=> ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin • Solicitações')),
      body: loading ? const Center(child: CircularProgressIndicator()) :
      RefreshIndicator(
        onRefresh: _load,
        child: itens.isEmpty ? const Center(child: Text('Nenhuma pendente.')) :
        ListView.builder(
          itemCount: itens.length,
          itemBuilder: (_, i){
            final it = itens[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.menu_book),
                title: Text(it['titulo'] ?? ''),
                subtitle: Text('Por: ${it['usuario_nome'] ?? '-'} • ISBN: ${it['isbn'] ?? ''}'),
                trailing: Wrap(spacing: 6, children: [
                  IconButton(onPressed: ()=> _aprovar(it['id_solicitacao']), icon: const Icon(Icons.check_circle, color: Colors.greenAccent)),
                  IconButton(onPressed: ()=> _rejeitar(it['id_solicitacao']), icon: const Icon(Icons.cancel, color: Colors.redAccent)),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}
