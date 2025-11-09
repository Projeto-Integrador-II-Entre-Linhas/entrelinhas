import 'package:flutter/material.dart';
import '../services/favorito_service.dart';
import 'fichamento_detalhes_screen.dart';

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});
  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  final FavoritoService service = FavoritoService();
  List itens = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => loading = true);
    final list = await service.listarFavoritos();
    setState(() {
      itens = list;
      loading = false;
    });
  }

  Future<void> _desf(int idFichamento) async {
    final ok = await service.desfavoritar(idFichamento);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removido dos favoritos')));
      _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Favoritos')),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: itens.isEmpty
            ? const Center(child: Text('Nenhum fichamento favoritado'))
            : ListView.builder(
                itemCount: itens.length,
                itemBuilder: (_, i) {
                  final f = itens[i];
                  return Card(
                    child: ListTile(
                      title: Text(f['titulo'] ?? 'Fichamento'),
                      subtitle: Text('Autor: ${f['autor'] ?? '-'} • Nota: ${f['nota'] ?? '-'}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.star, color: Colors.amber),
                        onPressed: () => _desf(f['id_fichamento']),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FichamentoDetalhesScreen(idFichamento: f['id_fichamento']),
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
