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
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(()=>loading=true);
    final r = await api.get('users');
    if (r.statusCode == 200) {
      users = List.from(jsonDecode(r.body));
    }
    setState(()=>loading=false);
  }

  Future<void> _status(int id, String status) async {
    final r = await api.put('users/$id/status', {'status': status});
    _msg(r.statusCode==200 ? 'Status atualizado' : 'Falha ao atualizar');
    _load();
  }

  Future<void> _perfil(int id, String perfil) async {
    final r = await api.put('users/$id/perfil', {'perfil': perfil});
    _msg(r.statusCode==200 ? 'Perfil atualizado' : 'Falha ao atualizar');
    _load();
  }

  void _msg(String m)=> ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin • Usuários')),
      body: loading ? const Center(child: CircularProgressIndicator()) :
      RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          itemCount: users.length,
          itemBuilder: (_, i){
            final u = users[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(u['nome'] ?? ''),
                subtitle: Text('${u['email'] ?? ''} • ${u['perfil']} • ${u['status']}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (v){
                    if (v=='ATIVAR') _status(u['id_usuario'],'ATIVO');
                    if (v=='INATIVAR') _status(u['id_usuario'],'INATIVO');
                    if (v=='ADMIN') _perfil(u['id_usuario'],'ADMIN');
                    if (v=='COMUM') _perfil(u['id_usuario'],'COMUM');
                  },
                  itemBuilder: (_)=> const [
                    PopupMenuItem(value:'ATIVAR', child: Text('Ativar')),
                    PopupMenuItem(value:'INATIVAR', child: Text('Inativar')),
                    PopupMenuItem(value:'ADMIN', child: Text('Tornar ADMIN')),
                    PopupMenuItem(value:'COMUM', child: Text('Tornar COMUM')),
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
