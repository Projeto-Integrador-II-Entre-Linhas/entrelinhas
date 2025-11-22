import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminUsuariosScreen extends StatefulWidget {
  const AdminUsuariosScreen({super.key});

  @override
  State<AdminUsuariosScreen> createState() => _AdminUsuariosScreenState();
}

class _AdminUsuariosScreenState extends State<AdminUsuariosScreen> {
  bool loading = true;
  List users = [];
  final api = ApiService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final r = await api.get('users');
    if (r.statusCode == 200 && r.body.isNotEmpty) {
      users = List.from(jsonDecode(r.body));
    }
    setState(() => loading = false);
  }

  Future<void> _status(int id, String status) async {
    String? motivo;
    if (status == 'INATIVO') {
      motivo = await showDialog<String>(
        context: context,
        builder: (_) {
          final c = TextEditingController();
          return AlertDialog(
            title: const Text('Motivo da inativação'),
            content: TextField(
              controller: c,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF947CAC),
                ),
                onPressed: () => Navigator.pop(context, c.text.trim()),
                child: const Text('Confirmar'),
              ),
            ],
          );
        },
      );
    }

    final body = {
      'status': status,
      if (motivo != null && motivo.isNotEmpty) 'motivo_inativacao': motivo
    };

    final r = await api.put('users/$id/status', body);
    _msg(r.statusCode == 200 ? 'Status atualizado com sucesso' : 'Falha ao atualizar status');
    _load();
  }

  Future<void> _perfil(int id, String perfil) async {
    final r = await api.put('users/$id/perfil', {'perfil': perfil});
    _msg(r.statusCode == 200 ? 'Perfil atualizado com sucesso' : 'Falha ao atualizar perfil');
    _load();
  }

  // Excluir usuário
  Future<void> _excluir(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Excluir usuário'),
          content: const Text(
            'Tem certeza que deseja excluir este usuário? Esta ação não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    final r = await api.delete('users/$id');

    _msg(r.statusCode == 200
        ? 'Usuário excluído com sucesso'
        : 'Falha ao excluir usuário');

    _load();
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD2C9D4),
      appBar: AppBar(
        title: const Text('Admin • Usuários'),
        backgroundColor: const Color(0xFF4F3466),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F3466)))
          : RefreshIndicator(
              color: const Color(0xFF4F3466),
              onRefresh: _load,
              child: users.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Nenhum usuário encontrado.',
                          style: TextStyle(color: Color(0xFF4F3466)),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: users.length,
                      itemBuilder: (_, i) {
                        final u = users[i];
                        final ativo = (u['status'] == 'ATIVO');
                        final admin = (u['perfil'] == 'ADMIN');

                        return Card(
                          color: const Color(0xFFCABCD7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFF947CAC), width: 0.8),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: ativo
                                  ? const Color(0xFF947CAC)
                                  : const Color(0xFFA580A6),
                              child: const Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(
                              u['nome'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4F3466),
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${u['email'] ?? ''}\nPerfil: ${u['perfil']} • Status: ${u['status']}',
                                style: const TextStyle(
                                  color: Color(0xFF5B3765),
                                  height: 1.3,
                                ),
                              ),
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Color(0xFF4F3466)),
                              onSelected: (v) {
                                if (v == 'ATIVAR') _status(u['id_usuario'], 'ATIVO');
                                if (v == 'INATIVAR') _status(u['id_usuario'], 'INATIVO');
                                if (v == 'ADMIN') _perfil(u['id_usuario'], 'ADMIN');
                                if (v == 'COMUM') _perfil(u['id_usuario'], 'COMUM');
                                if (v == 'EXCLUIR') _excluir(u['id_usuario']);
                              },
                              itemBuilder: (_) => [
                                if (!ativo)
                                  const PopupMenuItem(value: 'ATIVAR', child: Text('Ativar')),
                                if (ativo)
                                  const PopupMenuItem(value: 'INATIVAR', child: Text('Inativar')),
                                if (!admin)
                                  const PopupMenuItem(value: 'ADMIN', child: Text('Tornar ADMIN')),
                                if (admin)
                                  const PopupMenuItem(value: 'COMUM', child: Text('Tornar COMUM')),
                                
                                const PopupMenuItem(
                                  value: 'EXCLUIR',
                                  child: Text(
                                    'Excluir',
                                    style: TextStyle(color: Colors.red),
                                  ),
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
