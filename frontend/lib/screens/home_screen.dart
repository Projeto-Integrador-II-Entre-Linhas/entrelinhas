import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'livro_cadastro_screen.dart';
import 'livro_lista_screen.dart';
import 'fichamento_screen.dart';
import 'profile_screen.dart';
import '../services/fichamento_service.dart';
import '../services/livro_service.dart';
import '../services/favorito_service.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FichamentoService fichService = FichamentoService();
  final LivroService livroService = LivroService();
  final FavoritoService favService = FavoritoService();

  List fichamentosPublicos = [];
  List meusFichamentos = [];
  List favoritos = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final pub = await fichService.listarPublicos();
    List meus = [];
    List favs = [];
    try {
      meus = await fichService.listarMeus();
      favs = await favService.listarFavoritos();
    } catch (_) {
      // usuário não logado ainda ou token inválido
    }
    setState(() {
      fichamentosPublicos = pub;
      meusFichamentos = meus;
      favoritos = favs;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('EntreLinhas')),
      drawer: Drawer(
        child: Column(children: [
          UserAccountsDrawerHeader(
            accountName: Text(auth.user?['nome'] ?? 'Usuário'),
            accountEmail: Text(auth.user?['email'] ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundImage: auth.user?['avatar'] != null
                  ? NetworkImage(
                          '${ApiService.API_BASE_URL.replaceFirst('/api', '')}${auth.user!['avatar']}')
                      as ImageProvider
                  : null,
              child: auth.user?['avatar'] == null ? const Icon(Icons.person) : null,
            ),
            decoration: const BoxDecoration(color: AppColors.purple),
          ),
          ListTile(
            title: const Text('Cadastrar Livro'),
            leading: const Icon(Icons.book),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LivroCadastroScreen()),
            ).then((_) => _loadAll()),
          ),
          ListTile(
            title: const Text('Livros Cadastrados'),
            leading: const Icon(Icons.library_books),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LivroListaScreen()),
            ),
          ),
          ListTile(
            title: const Text('Perfil'),
            leading: const Icon(Icons.person),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          ListTile(
            title: const Text('Sair'),
            leading: const Icon(Icons.logout),
            onTap: () => auth.logout(),
          ),
        ]),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Meus Fichamentos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (meusFichamentos.isEmpty)
              const Text('Você ainda não possui fichamentos.')
            else
              ...meusFichamentos.map((f) => Card(
                    child: ListTile(
                      leading: _capa(f['capa_url']),
                      title: Text(f['titulo'] ?? 'Fichamento'),
                      subtitle: Text('Nota: ${f['nota'] ?? '-'}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FichamentoScreen(
                              livroId: f['id_livro'],
                              fichamentoExistente: f,
                            ),
                          ),
                        ).then((_) => _loadAll());
                      },
                    ),
                  )),

            const SizedBox(height: 24),
            const Text('Fichamentos Favoritos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (favoritos.isEmpty)
              const Text('Você ainda não favoritou nenhum fichamento.')
            else
              ...favoritos.map((f) => Card(
                    child: ListTile(
                      leading: _capa(f['capa_url']),
                      title: Text(f['titulo'] ?? 'Fichamento'),
                      subtitle: Text('Por usuário ${f['id_usuario']} • Nota: ${f['nota'] ?? '-'}'),
                      onTap: () {}, // abrir detalhe futuramente
                    ),
                  )),

            const SizedBox(height: 24),
            const Text('Fichamentos Públicos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...fichamentosPublicos.map((f) => Card(
                  child: ListTile(
                    leading: _capa(f['capa_url']),
                    title: Text(f['titulo'] ?? f['introducao'] ?? 'Fichamento'),
                    subtitle: Text('Por ${f['id_usuario']} • Nota: ${f['nota'] ?? '-'}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.star_border),
                      onPressed: () {
                        //chamar FavoritoService.favoritar(f['id_fichamento'])
                      },
                    ),
                    onTap: () {},
                  ),
                )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FichamentoScreen()),
        ).then((_) => _loadAll()),
      ),
    );
  }

  Widget _capa(dynamic url) {
    if (url is String && url.isNotEmpty) {
      return Image.network(url, width: 40, fit: BoxFit.cover);
    }
    return const Icon(Icons.book, size: 40);
  }
}
