import 'package:flutter/material.dart';
import '../services/solicitacao_service.dart';
import 'admin_solicitacao_detalhe_screen.dart';

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
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    itens = await s.pendentes();
    setState(() => loading = false);
  }

  Future<void> _aprovar(int id) async {
    final ok = await s.aprovar(id);
    _toast(ok ? 'Solicitação aprovada com sucesso!' : 'Falha ao aprovar.');
    _load();
  }

  Future<void> _rejeitar(int id) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Motivo da rejeição'),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(
              labelText: 'Motivo (opcional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF947CAC)),
              onPressed: () => Navigator.pop(context, c.text.trim()),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
    if (motivo == null) return;
    final ok = await s.rejeitar(id, motivo: motivo.isEmpty ? null : motivo);
    _toast(ok ? 'Solicitação rejeitada.' : 'Falha ao rejeitar.');
    _load();
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD2C9D4),
      appBar: AppBar(
        title: const Text('Admin • Solicitações'),
        backgroundColor: const Color(0xFF4F3466),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F3466)))
          : RefreshIndicator(
              color: const Color(0xFF4F3466),
              onRefresh: _load,
              child: itens.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Nenhuma solicitação pendente.',
                          style: TextStyle(color: Color(0xFF4F3466)),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: itens.length,
                      itemBuilder: (_, i) {
                        final it = itens[i];
                        return Card(
                          color: const Color(0xFFCABCD7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFF947CAC), width: 0.8),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.menu_book, color: Color(0xFF4F3466)),
                            title: Text(
                              it['titulo'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4F3466),
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Por: ${it['usuario_nome'] ?? '-'}\nISBN: ${it['isbn'] ?? '-'}',
                                style: const TextStyle(
                                  color: Color(0xFF5B3765),
                                  height: 1.3,
                                ),
                              ),
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminSolicitacaoDetalheScreen(
                                    idSolicitacao: it['id_solicitacao'],
                                  ),
                                ),
                              );
                              _load();
                            },
                            trailing: Wrap(
                              spacing: 6,
                              children: [
                                IconButton(
                                  tooltip: 'Aprovar',
                                  onPressed: () => _aprovar(it['id_solicitacao']),
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                ),
                                IconButton(
                                  tooltip: 'Rejeitar',
                                  onPressed: () => _rejeitar(it['id_solicitacao']),
                                  icon: const Icon(Icons.cancel, color: Colors.redAccent),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
