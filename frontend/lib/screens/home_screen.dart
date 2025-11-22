import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/dashboard_service.dart';
import '../config.dart';
import 'fichamento_detalhes_screen.dart';
import 'livro_lista_screen.dart';
import 'livro_cadastro_screen.dart';
import 'profile_screen.dart';
import 'solicitacoes_minhas_screen.dart';
import 'admin_solicitacoes_screen.dart';
import 'admin_usuarios_screen.dart';
import 'fichamentos_publicos_screen.dart';

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

    final avatarUrl = avatarPath.isNotEmpty
        ? '${AppConfig.baseUrl}$avatarPath'
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFE8DFF1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4F2A75),
        elevation: 4,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.auto_stories, color: Colors.white, size: 26),
            SizedBox(width: 8),
            Text(
              'Entre Linhas',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 18,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? const Icon(Icons.person, color: Color(0xFF4F2A75))
                    : null,
              ),
            ),
          )
        ],
      ),
      drawer: _buildDrawer(context, auth, perfil, avatarUrl),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4F2A75)))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionTitle('Fichamentos Favoritos'),
                  _FavoritosCarousel(items: data?['favoritos'] ?? []),
                  const SizedBox(height: 24),

                  _sectionTitle('Meus Fichamentos'),
                  _FichamentosUsuarioCarousel(
                      items: data?['meus_fichamentos'] ?? []),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text(
                          'Fichamentos Públicos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F2A75),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FichamentosPublicosScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Ver todos',
                          style: TextStyle(color: Color(0xFF4F2A75)),
                        ),
                      ),
                    ],
                  ),
                  _FichamentosPublicosCarousel(
                      items: data?['fichamentos_publicos'] ?? []),

                  const SizedBox(height: 24),
                  _sectionTitle('Suas Solicitações'),
                  _SolicitacoesList(items: data?['solicitacoes'] ?? []),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF8562A5),
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
    BuildContext context,
    AuthProvider auth,
    String perfil,
    String? avatarUrl,
  ) {
    final userDash = data?['user'];

    return Drawer(
      backgroundColor: const Color(0xFFF3EBFA),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF4F2A75)),
            accountName: Text(
              userDash?['nome'] ?? auth.user?['nome'] ?? 'Usuário',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            accountEmail: Text(
              userDash?['email'] ?? auth.user?['email'] ?? '',
              style: const TextStyle(color: Colors.white70),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, color: Color(0xFF4F2A75))
                  : null,
            ),
          ),

          _drawerItem(Icons.home, 'Início', () => Navigator.pop(context)),
          _drawerItem(Icons.add_box, 'Cadastrar Livro', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LivroCadastroScreen()),
            );
          }),
          _drawerItem(Icons.library_books, 'Livros', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LivroListaScreen()),
            );
          }),

          _drawerItem(Icons.public, 'Fichamentos Públicos', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FichamentosPublicosScreen(),
              ),
            );
          }),

          _drawerItem(Icons.request_page, 'Minhas Solicitações', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const MinhasSolicitacoesScreen()),
            );
          }),

          _drawerItem(Icons.person, 'Perfil', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          }),

          if (perfil == 'ADMIN') const Divider(),

          if (perfil == 'ADMIN')
            _drawerItem(Icons.admin_panel_settings, 'Admin • Usuários', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminUsuariosScreen()),
              );
            }),

          if (perfil == 'ADMIN')
            _drawerItem(Icons.fact_check, 'Admin • Solicitações', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminSolicitacoesScreen()),
              );
            }),

          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Sair',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () async {
              await auth.logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  ListTile _drawerItem(IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4F2A75)),
      title: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF3B1F52),
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4F2A75),
          ),
        ),
      );
}

// === FAVORITOS ===
class _FavoritosCarousel extends StatelessWidget {
  final List items;
  const _FavoritosCarousel({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
          child: Text('Nenhum favorito encontrado.',
              style: TextStyle(color: Color(0xFF4F2A75))));
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
                builder: (_) => FichamentoDetalhesScreen(
                    idFichamento: fav['id_fichamento']),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: fav['capa_url'] != null
                  ? Image.network(
                      fav['capa_url'],
                      width: 120,
                      height: 180,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 120,
                      height: 180,
                      color: const Color(0xFF8562A5),
                      child: const Icon(Icons.book, color: Colors.white),
                    ),
            ),
          );
        },
      ),
    );
  }
}

// === MEUS FICHAMENTOS ===
class _FichamentosUsuarioCarousel extends StatelessWidget {
  final List items;
  const _FichamentosUsuarioCarousel({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Você ainda não criou fichamentos.',
          style: TextStyle(color: Color(0xFF4F2A75)),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final f = items[i];

          return _FichamentoCard(
            capa: f['capa_url'] ?? '',
            titulo: f['titulo'] ?? '',
            subtitulo:
                'Nota: ${f['nota']?.toString() ?? '-'} • ${f['visibilidade']}',
            idFichamento: f['id_fichamento'],
          );
        },
      ),
    );
  }
}

// === FICHAMENTOS PÚBLICOS ===
class _FichamentosPublicosCarousel extends StatelessWidget {
  final List items;
  const _FichamentosPublicosCarousel({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum fichamento público encontrado.',
          style: TextStyle(color: Color(0xFF4F2A75)),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final f = items[i];

          return _FichamentoCard(
            capa: f['capa_url'] ?? '',
            titulo: f['titulo'] ?? '',
            subtitulo:
                'Por: ${f['usuario'] ?? 'Anônimo'} • Nota: ${f['nota'] ?? '-'}',
            idFichamento: f['id_fichamento'],
          );
        },
      ),
    );
  }
}

// === CARD ===
class _FichamentoCard extends StatelessWidget {
  final String capa;
  final String titulo;
  final String subtitulo;
  final int idFichamento;

  const _FichamentoCard({
    required this.capa,
    required this.titulo,
    required this.subtitulo,
    required this.idFichamento,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              FichamentoDetalhesScreen(idFichamento: idFichamento),
        ),
      ),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: const Color(0xFFE5D8F2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: capa.isNotEmpty
                  ? Image.network(
                      capa,
                      width: 150,
                      height: 140,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 150,
                      height: 140,
                      color: const Color(0xFF8562A5),
                      child:
                          const Icon(Icons.menu_book, color: Colors.white, size: 40),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4F2A75),
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    subtitulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF654A81),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      return const Text(
        'Nenhuma solicitação registrada.',
        style: TextStyle(color: Color(0xFF4F2A75)),
      );
    }

    return Column(
      children: items.map((s) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE5D8F2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.fact_check, color: Color(0xFF4F2A75)),
            title: Text(
              s['titulo'] ?? 'Solicitação',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Status: ${s['status']} • Por: ${s['usuario'] ?? 'Usuário'}',
              style: const TextStyle(color: Color(0xFF6B5288)),
            ),
          ),
        );
      }).toList(),
    );
  }
}
