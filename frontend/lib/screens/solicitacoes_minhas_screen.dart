import 'package:flutter/material.dart';
import '../services/solicitacao_service.dart';

class MinhasSolicitacoesScreen extends StatefulWidget {
  const MinhasSolicitacoesScreen({super.key});
  @override
  State<MinhasSolicitacoesScreen> createState() => _MinhasSolicitacoesScreenState();
}

class _MinhasSolicitacoesScreenState extends State<MinhasSolicitacoesScreen> {
  final s = SolicitacaoService();
  bool loading = true;
  List itens = [];

  @override
  void initState() {
    super.initState();
    _load();
  }
  Future<void> _load() async {
    setState(()=>loading=true);
    final list = await s.minhas();
    setState(()=> { itens = list, loading=false });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Solicitações')),
      body: loading ? const Center(child: CircularProgressIndicator()) :
      RefreshIndicator(
        onRefresh: _load,
        child: itens.isEmpty
          ? const Center(child: Text('Você ainda não possui solicitações.'))
          : ListView.builder(
              itemCount: itens.length,
              itemBuilder: (_, i){
                final it = itens[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.fact_check),
                    title: Text(it['titulo'] ?? 'Solicitação'),
                    subtitle: Text('Autor: ${it['autor'] ?? '-'} • Status: ${it['status']}'),
                  ),
                );
              },
            ),
      ),
    );
  }
}
