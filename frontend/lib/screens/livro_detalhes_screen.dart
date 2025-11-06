import 'package:flutter/material.dart';

class LivroDetalhesScreen extends StatelessWidget {
  final Map livro; // recebe o livro selecionado

  const LivroDetalhesScreen({super.key, required this.livro});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(livro['titulo'] ?? 'Detalhes do Livro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (livro['capa_url'] != null)
              Center(
                child: Image.network(
                  livro['capa_url'],
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              livro['titulo'] ?? 'Sem título',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Autor: ${livro['autor'] ?? 'Desconhecido'}'),
            const SizedBox(height: 8),
            Text('Editora: ${livro['editora'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Ano: ${livro['ano_publicacao'] ?? 'N/A'}'),
            const SizedBox(height: 16),
            Text(
              livro['descricao'] ?? 'Sem descrição disponível.',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
