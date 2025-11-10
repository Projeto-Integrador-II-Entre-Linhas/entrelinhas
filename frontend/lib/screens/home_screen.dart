import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/dashboard_service.dart';
import '../services/api_service.dart';
import 'fichamento_detalhes_screen.dart';
import 'livro_lista_screen.dart';
import 'livro_cadastro_screen.dart';
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
  Map<String, dynamic>? data;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final d = await ds.get();
    setState(() {
      data = d;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final perfil = auth.user?['perfil'] ?? 'COMUM';
    final userDash = data?['user'];
    final avatarPath = (userDash?['avatar'] ?? '') as String;
    final avatarUrl =
        avatarPath.isNotEmpty ? 'http://192.168.100.12:3000$avatarPath' : null;

    return Scaffold(
      backgroundColor: const Color(0xFFD2C9D4),
      appBar: AppBar(
        title: const Text('Entre Linhas', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF4F3466),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(context, auth, perfil, avatarUrl),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionTitle('Fichamentos Favoritos'),
                  _FavoritosCarousel(items: data?['favoritos'] ?? []),
                  const SizedBox(height: 24),
                  _sectionTitle('Meus Fichamentos'),
                  _FichamentosUsuarioList(items: data?['meus_fichamentos'] ?? []),
                  const SizedBox(height: 24),
                  _sectionTitle('Fichamentos Públicos'),
                  _FichamentosPublicosList(items: data?['fichamentos_publicos'] ?? []),
                  const SizedBox(height: 24),
                  _sectionTitle('Suas Solicitações'),
                  _SolicitacoesList(items: data?['solicitacoes'] ?? []),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF947CAC),
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LivroListaScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Novo Fichamento'),
      ),
    );
  }

  Drawer _buildDrawer(
      BuildContext context, AuthProvider auth, String perfil, String? avatarUrl) {
    final userDash = data?['user'];
    return Drawer(
      backgroundColor: const Color(0xFFF5F2F7),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF4F3466)),
            accountName: Text(
              userDash?['nome'] ?? auth.user?['nome'] ?? 'Usuário',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            accountEmail: Text(
              userDash?['email'] ?? auth.user?['email'] ?? '',
              style: const TextStyle(color: Colors.white70),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, color: Color(0xFF4F3466))
                  : null,
            ),
          ),
          _drawerItem(Icons.home, 'Início', () => Navigator.pop(context)),
          _drawerItem(Icons.book, 'Cadastrar Livro', () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LivroCadastroScreen()));
          }),
          _drawerItem(Icons.library_books, 'Livros', () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LivroListaScreen()));
          }),
          _drawerItem(Icons.question_answer, 'Minhas Solicitações', () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MinhasSolicitacoesScreen()));
          }),
          _drawerItem(Icons.person, 'Perfil', () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }),
          if (perfil == 'ADMIN') const Divider(),
          if (perfil == 'ADMIN')
            _drawerItem(Icons.admin_panel_settings, 'Admin • Usuários', () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminUsuariosScreen()));
            }),
          if (perfil == 'ADMIN')
            _drawerItem(Icons.fact_check, 'Admin • Solicitações', () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminSolicitacoesScreen()));
            }),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sair',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () => auth.logout(),
          ),
        ],
      ),
    );
  }

  ListTile _drawerItem(IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4F3466)),
      title: Text(text,
          style:
              const TextStyle(color: Color(0xFF2E1A3A), fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4F3466),
          ),
        ),
      );
}

// === FAVORITOS CAROUSEL ===
class _FavoritosCarousel extends StatelessWidget {
  final List items;
  const _FavoritosCarousel({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Nenhum favorito encontrado.'));
    }
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final fav = items[i];
          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      FichamentoDetalhesScreen(idFichamento: fav['id_fichamento'])),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: fav['capa_url'] != null
                  ? Image.network(fav['capa_url'],
                      width: 120, height: 180, fit: BoxFit.cover)
                  : Container(
                      width: 120,
                      height: 180,
                      color: const Color(0xFF947CAC),
                      child: const Icon(Icons.book, color: Colors.white),
                    ),
            ),
          );
        },
      ),
    );
  }
}

// === SEUS FICHAMENTOS ===
class _FichamentosUsuarioList extends StatelessWidget {
  final List items;
  const _FichamentosUsuarioList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Você ainda não criou nenhum fichamento.'));
    }

    return Column(
      children: items.map((f) {
        return Card(
          color: const Color(0xFFCABCD7),
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: f['capa_url'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(f['capa_url'],
                        width: 50, height: 70, fit: BoxFit.cover),
                  )
                : const Icon(Icons.menu_book, color: Color(0xFF4F3466)),
            title: Text(f['titulo'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F3466))),
            subtitle: Text('Nota: ${f['nota'] ?? '-'} • Visibilidade: ${f['visibilidade'] ?? ''}',
                style: const TextStyle(color: Color(0xFF5B3765))),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => FichamentoDetalhesScreen(idFichamento: f['id_fichamento'])),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// === FICHAMENTOS PÚBLICOS ===
class _FichamentosPublicosList extends StatelessWidget {
  final List items;
  const _FichamentosPublicosList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Nenhum fichamento público disponível.'));
    }
    return Column(
      children: items.map((f) {
        return Card(
          color: const Color(0xFFCABCD7),
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: f['capa_url'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(f['capa_url'],
                        width: 50, height: 70, fit: BoxFit.cover),
                  )
                : const Icon(Icons.book, color: Color(0xFF4F3466)),
            title: Text(f['titulo'] ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF4F3466))),
            subtitle: Text('Por: ${f['usuario'] ?? 'Anônimo'} • Nota: ${f['nota'] ?? '-'}',
                style: const TextStyle(color: Color(0xFF5B3765))),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      FichamentoDetalhesScreen(idFichamento: f['id_fichamento'])),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// === SOLICITAÇÕES ===
class _SolicitacoesList extends StatelessWidget {
  final List items;
  const _SolicitacoesList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text('Nenhuma solicitação registrada.');
    }
    return Column(
      children: items.map((s) {
        return ListTile(
          leading: const Icon(Icons.fact_check, color: Color(0xFF4F3466)),
          title: Text(s['titulo'] ?? 'Solicitação'),
          subtitle: Text(
              'Status: ${s['status']} • Por: ${s['usuario'] ?? 'Usuário desconhecido'}'),
        );
      }).toList(),
    );
  }
}
