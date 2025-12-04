import 'package:flutter/material.dart';
import '../services/solicitacao_service.dart';
import 'solicitacao_detalhe_usuario_screen.dart';

class MinhasSolicitacoesScreen extends StatefulWidget {
  const MinhasSolicitacoesScreen({super.key});

  @override
  State<MinhasSolicitacoesScreen> createState() =>
      _MinhasSolicitacoesScreenState();
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
    setState(() => loading = true);
    final list = await s.minhas();
    setState(() {
      itens = list;
      loading = false;
    });
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case "APROVADO":
        return Colors.green.shade700;
      case "REJEITADO":
        return Colors.red.shade700;
      default:
        return Colors.orange.shade700; // PENDENTE
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD2C9D4),
      appBar: AppBar(
        title: const Text("Minhas Solicitações"),
        backgroundColor: const Color(0xFF6E4A8E),
        foregroundColor: const Color(0xFF4F3466),
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F3466)),
            )
          : RefreshIndicator(
              color: const Color(0xFF4F3466),
              onRefresh: _load,
              child: itens.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Você ainda não possui solicitações.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF4F3466),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: itens.length,
                      itemBuilder: (_, i) {
                        final it = itens[i];
                        final status = it["status"] ?? "-";

                        return Card(
                          color: const Color(0xFFCABCD7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Color(0xFF947CAC),
                              width: 0.8,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Icon(
                              Icons.fact_check,
                              color: _statusColor(status),
                              size: 34,
                            ),
                            title: Text(
                              it["titulo"] ?? "Solicitação",
                              style: const TextStyle(
                                color: Color(0xFF4F3466),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "Autor: ${it['autor'] ?? '-'}\nStatus: $status",
                                style: const TextStyle(
                                  color: Color(0xFF5B3765),
                                  height: 1.3,
                                ),
                              ),
                            ),

                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SolicitacaoDetalheUsuarioScreen(data: it),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
