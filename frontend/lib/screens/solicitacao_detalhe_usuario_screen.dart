import 'package:flutter/material.dart';

class SolicitacaoDetalheUsuarioScreen extends StatelessWidget {
  final Map data;
  const SolicitacaoDetalheUsuarioScreen({super.key, required this.data});

  Widget item(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4F3466),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF5B3765),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD2C9D4),
      appBar: AppBar(
        title: const Text("Detalhes da Solicitação"),
        backgroundColor: const Color(0xFF4F3466),
      ),

      body: Padding(
        padding: const EdgeInsets.all(18),
        child: ListView(
          children: [
            item("Título", data["titulo"] ?? "-"),
            item("Autor", data["autor"] ?? "-"),
            item("ISBN", data["isbn"] ?? "-"),
            item("Ano de Publicação",
                "${data["ano_publicacao"] ?? "-"}"),
            item("Editora", data["editora"] ?? "-"),
            item("Status", data["status"] ?? "-"),

            if (data["motivo_rejeicao"] != null &&
                data["motivo_rejeicao"].toString().isNotEmpty)
              item("Motivo da Rejeição", data["motivo_rejeicao"]),

            item(
              "Data da Solicitação",
              data["data_solicitacao"] ?? "-",
            ),
          ],
        ),
      ),
    );
  }
}
