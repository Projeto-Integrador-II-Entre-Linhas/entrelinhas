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
import 'meus_fichamentos_screen.dart';
import 'favoritos_screen.dart';
import 'recomendacoes_screen.dart';


class BrandColors {
  static const Color background = Color(0xFFDCCEE6);
  static const Color card = Color(0xFFEDE3F4);
  static const Color primary = Color(0xFF6E4A8E);
  static const Color secondary = Color(0xFF8A68B1);
  static const Color title = Color(0xFF4F2A75);
  static const Color icon = Color(0xFF6E4A8E);
  static const Color shadow = Color(0x14000000);
}

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
        avatarPath.isNotEmpty ? '${AppConfig.baseUrl}$avatarPath' : null;

    return Scaffold(
      backgroundColor: BrandColors.background,
      appBar: AppBar(
        backgroundColor: BrandColors.primary,
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
                    ? const Icon(Icons.person, color: BrandColors.primary)
                    : null,
              ),
            ),
          )
        ],
      ),

      drawer: _buildDrawer(context, auth, perfil, avatarUrl),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: BrandColors.primary),
            )
          : RefreshIndicator(
              color: BrandColors.primary,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // FAVORITOS
                  _sectionHeader(
                    title: 'Fichamentos Favoritos',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FavoritosScreen()),
                    ),
                  ),
                  _FavoritosCarousel(items: data?['favoritos'] ?? []),

                  const SizedBox(height: 24),

                  // MEUS FICHAMENTOS
                  _sectionHeader(
                    title: 'Meus Fichamentos',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MeusFichamentosScreen()),
                    ),
                  ),
                  _FichamentosUsuarioCarousel(
                      items: data?['meus_fichamentos'] ?? []),

                  const SizedBox(height: 24),

                  // PÚBLICOS
                  _sectionHeader(
                    title: 'Fichamentos Públicos',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FichamentosPublicosScreen()),
                    ),
                  ),
                  _FichamentosPublicosCarousel(
                      items: data?['fichamentos_publicos'] ?? []),

                  const SizedBox(height: 24),

                  // RECOMENDAÇÕES
                  _sectionHeader(
                    title: 'Recomendações Para Você',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecomendacoesScreen(
                            recomendados: data?['recomendados'] ?? [],
                          ),
                        ),
                      );
                    },
                  ),

                  _RecomendadosCarousel(
                    items: data?['recomendados'] ?? [],
                  ),

                ],
              ),
            ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: BrandColors.secondary,
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
      backgroundColor: BrandColors.card,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: BrandColors.primary),
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
                  ? const Icon(Icons.person, color: BrandColors.primary)
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

          _drawerItem(Icons.book, "Meus Fichamentos", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MeusFichamentosScreen()),
            );
          }),

          _drawerItem(Icons.favorite, "Favoritos", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritosScreen()),
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
              if (!mounted) return;

              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  ListTile _drawerItem(IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: BrandColors.icon),
      title: Text(
        text,
        style: const TextStyle(
          color: BrandColors.title,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _sectionHeader({required String title, required VoidCallback onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: BrandColors.title,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: const Text(
            'Ver todos',
            style: TextStyle(color: BrandColors.title),
          ),
        ),
      ],
    );
  }
}

class _FavoritosCarousel extends StatelessWidget {
  final List items;
  const _FavoritosCarousel({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Nenhum favorito encontrado.',
            style: TextStyle(color: BrandColors.title)),
      );
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
                      color: BrandColors.secondary,
                      child: const Icon(Icons.book, color: Colors.white),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _FichamentosUsuarioCarousel extends StatelessWidget {
  final List items;
  const _FichamentosUsuarioCarousel({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Você ainda não criou fichamentos.',
            style: TextStyle(color: BrandColors.title)),
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

class _FichamentosPublicosCarousel extends StatelessWidget {
  final List items;
  const _FichamentosPublicosCarousel({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Nenhum fichamento público encontrado.',
            style: TextStyle(color: BrandColors.title)),
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
          color: BrandColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: BrandColors.shadow,
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
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
                      color: BrandColors.secondary,
                      child: const Icon(Icons.menu_book,
                          color: Colors.white, size: 40),
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
                      color: BrandColors.title,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6B5288),
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

// RECOMENDAÇÕES
class _RecomendadosCarousel extends StatelessWidget {
  final List items;
  const _RecomendadosCarousel({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Nenhuma recomendação disponível.',
            style: TextStyle(color: BrandColors.title)),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final l = items[i];
          return _LivroRecomendadoCard(
            capa: l['capa_url'] ?? '',
            titulo: l['titulo'] ?? '',
            autor: l['autor'] ?? '',
            idLivro: l['id_livro'],
          );
        },
      ),
    );
  }
}

class _LivroRecomendadoCard extends StatelessWidget {
  final String capa;
  final String titulo;
  final String autor;
  final int idLivro;

  const _LivroRecomendadoCard({
    required this.capa,
    required this.titulo,
    required this.autor,
    required this.idLivro,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/livro-detalhes',
          arguments: {'id_livro': idLivro},
        );
      },
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: BrandColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: BrandColors.shadow,
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
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
                      color: BrandColors.secondary,
                      child: const Icon(Icons.menu_book,
                          color: Colors.white, size: 40),
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
                        color: BrandColors.title),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    autor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: BrandColors.secondary, fontSize: 12),
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
