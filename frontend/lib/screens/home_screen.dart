import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/dashboard_service.dart';
import '../utils/app_colors.dart';
import 'favoritos_screen.dart';
import 'fichamento_detalhes_screen.dart';
import 'livro_detalhes_screen.dart';
import 'livro_cadastro_screen.dart';
import 'livro_lista_screen.dart';
import 'profile_screen.dart';
import 'solicitacoes_minhas_screen.dart';
import 'admin_solicitacoes_screen.dart';
import 'admin_usuarios_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ds = DashboardService();
  Map<String,dynamic>? data;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(()=>loading=true);
    final d = await ds.get();
    setState((){ data = d; loading=false; });
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(16,16,16,8),
    child: Row(
      children: [
        const Icon(Icons.auto_awesome, size: 20),
        const SizedBox(width: 8),
        Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final perfil = auth.user?['perfil'] ?? 'COMUM';

    return Scaffold(
      appBar: AppBar(title: const Text('EntreLinhas')),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(auth.user?['nome'] ?? 'Usuário'),
              accountEmail: Text(auth.user?['email'] ?? ''),
              currentAccountPicture: const CircleAvatar(child: Icon(Icons.person)),
              decoration: const BoxDecoration(color: AppColors.purple),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Início'),
              onTap: ()=> Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Cadastrar Livro'),
              onTap: ()=> Navigator.push(context, MaterialPageRoute(builder:(_)=> const LivroCadastroScreen())).then((_){ _load(); }),
            ),
            ListTile(
              leading: const Icon(Icons.library_books),
              title: const Text('Livros'),
              onTap: ()=> Navigator.push(context, MaterialPageRoute(builder:(_)=> const LivroListaScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.question_answer),
              title: const Text('Minhas Solicitações'),
              onTap: ()=> Navigator.push(context, MaterialPageRoute(builder:(_)=> const MinhasSolicitacoesScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: ()=> Navigator.push(context, MaterialPageRoute(builder:(_)=> const ProfileScreen())).then((_){ _load(); }),
            ),
            if (perfil == 'ADMIN') const Divider(),
            if (perfil == 'ADMIN')
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Admin • Usuários'),
                onTap: ()=> Navigator.push(context, MaterialPageRoute(builder:(_)=> const AdminUsuariosScreen())),
              ),
            if (perfil == 'ADMIN')
              ListTile(
                leading: const Icon(Icons.fact_check),
                title: const Text('Admin • Solicitações'),
                onTap: ()=> Navigator.push(context, MaterialPageRoute(builder:(_)=> const AdminSolicitacoesScreen())),
              ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: ()=> auth.logout(),
            ),
          ],
        ),
      ),
      body: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              children: [
                _sectionTitle('Suas solicitações'),
                _SolicitacoesStrip(items: data?['solicitacoes'] ?? []),
                _sectionTitle('Favoritos'),
                _FichamentosStrip(items: data?['favoritos'] ?? []),
                _sectionTitle('Seus fichamentos'),
                _FichamentosStrip(items: data?['meus_fichamentos'] ?? []),
                _sectionTitle('Recomendações mágicas'),
                _LivrosStrip(items: data?['recomendados'] ?? []),
                const SizedBox(height: 24),
              ],
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder:(_)=> const LivroCadastroScreen())),
        icon: const Icon(Icons.auto_stories),
        label: const Text('Adicionar'),
      ),
    );
  }
}

class _FichamentosStrip extends StatelessWidget {
  final List items;
  const _FichamentosStrip({required this.items});
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text('Nada por aqui ainda…'),
    );

    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __)=> const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final f = items[i];
          return InkWell(
            onTap: ()=> Navigator.push(context, MaterialPageRoute(builder:(_)=> FichamentoDetalhesScreen(idFichamento: f['id_fichamento']))),
            child: Container(
              width: 260,
              decoration: BoxDecoration(
                color: const Color(0xFF23113F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC8A2C8).withOpacity(.25)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f['titulo'] ?? f['introducao'] ?? 'Fichamento', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('Nota: ${f['nota'] ?? '-'} • ${f['autor'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  const Spacer(),
                  Row(
                    children: const [
                      Icon(Icons.stars, size: 18),
                      SizedBox(width: 6),
                      Text('Abrir detalhes'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LivrosStrip extends StatelessWidget {
  final List items;
  const _LivrosStrip({required this.items});
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text('Sem recomendações no momento.'),
    );

    return SizedBox(
      height: 210,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __)=> const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final l = items[i];
          return InkWell(
            onTap: ()=> Navigator.push(context, MaterialPageRoute(builder:(_)=> LivroDetalhesScreen(livro: l))),
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                color: const Color(0xFF23113F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC8A2C8).withOpacity(.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((l['capa_url'] ?? '').toString().isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(l['capa_url'], height: 120, width: 160, fit: BoxFit.cover),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l['titulo'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(l['autor'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SolicitacoesStrip extends StatelessWidget {
  final List items;
  const _SolicitacoesStrip({required this.items});
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text('Você ainda não fez solicitações.'),
    );

    return Column(
      children: items.take(4).map<Widget>((s){
        return ListTile(
          leading: const Icon(Icons.fact_check),
          title: Text(s['titulo'] ?? 'Solicitação'),
          subtitle: Text('Status: ${s['status']}'),
        );
      }).toList(),
    );
  }
}
