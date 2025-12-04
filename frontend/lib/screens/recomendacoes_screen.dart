import 'package:flutter/material.dart';
import 'livro_detalhes_screen.dart';

class BrandColors {
  static const Color background = Color(0xFFDCCEE6);
  static const Color card = Color(0xFFEDE3F4);
  static const Color primary = Color(0xFF6E4A8E);
  static const Color secondary = Color(0xFF8A68B1);
  static const Color title = Color(0xFF4F2A75);
  static const Color icon = Color(0xFF6E4A8E);
  static const Color shadow = Color(0x14000000);
}

class RecomendacoesScreen extends StatelessWidget {
  final List recomendados;

  const RecomendacoesScreen({super.key, required this.recomendados});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.background,
      appBar: AppBar(
        backgroundColor: BrandColors.primary,
        centerTitle: true,
        title: const Text('Recomendações Para Você', style: TextStyle(color: Colors.white)),
      ),
      body: recomendados.isEmpty
          ? const Center(
              child: Text(
                "Nenhuma recomendação disponível.",
                style: TextStyle(color: BrandColors.title),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recomendados.length,
              itemBuilder: (context, i) {
                final item = recomendados[i] as Map<dynamic, dynamic>;
                final capa = (item['capa_url'] ?? '') as String;
                final titulo = (item['titulo'] ?? '') as String;
                final autor = (item['autor'] ?? '') as String;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: BrandColors.card,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: BrandColors.shadow,
                        blurRadius: 6,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: capa.isNotEmpty
                          ? Image.network(
                              capa,
                              width: 50,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 50,
                                height: 70,
                                color: BrandColors.secondary,
                                child: const Icon(Icons.menu_book, color: Colors.white),
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 70,
                              color: BrandColors.secondary,
                              child: const Icon(Icons.menu_book, color: Colors.white),
                            ),
                    ),
                    title: Text(
                      titulo,
                      style: const TextStyle(
                        color: BrandColors.title,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      autor,
                      style: const TextStyle(color: BrandColors.secondary),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LivroDetalhesScreen(livro: Map<String, dynamic>.from(item)),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
