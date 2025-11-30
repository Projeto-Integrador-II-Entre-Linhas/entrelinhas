import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/fichamento_service.dart';
import '../services/api_service.dart';
import '../services/offline_sync_service.dart';

final OfflineSyncService _offline = OfflineSyncService();

class FichamentoScreen extends StatefulWidget {
  final int? livroId;
  final Map? fichamentoExistente;

  const FichamentoScreen({super.key, this.livroId, this.fichamentoExistente});

  @override
  State<FichamentoScreen> createState() => _FichamentoScreenState();
}

class _FichamentoScreenState extends State<FichamentoScreen> {
  final _intro = TextEditingController();
  final _cenario = TextEditingController();
  final _personagens = TextEditingController();
  final _narrativa = TextEditingController();
  final _critica = TextEditingController();
  final _frase = TextEditingController();

  String formato = "fisico";
  String visibilidade = "PRIVADO";
  int nota = 5;

  DateTime? dataInicio = DateTime.now();
  DateTime? dataFim;

  int? _idFichamento;
  int? _livroId;

  List<String> generosSelecionados = [];

  String? tituloLivro;
  List<dynamic>? generosLivro = [];
  String capaLivro = "https://via.placeholder.com/350x500";

  @override
  void initState() {
    super.initState();
    _livroId = widget.livroId;

    if (widget.fichamentoExistente != null) {
      _carregarExistente(widget.fichamentoExistente!);
    } else {
      _carregarLivro();
    }
  }

  Future<void> _carregarLivro() async {
    if (_livroId == null) return;

    final api = ApiService();
    final r = await api.get("livros/$_livroId");

    if (r.statusCode == 200 && r.body.isNotEmpty) {
      final data = jsonDecode(r.body);
      final livroData = data['livro'] ?? data;

      tituloLivro = livroData['titulo'] ?? "Título indisponível";
      capaLivro = livroData['capa_url'] ?? capaLivro;

      if (livroData['generos'] is List) {
        generosLivro = List<String>.from(livroData['generos']);
      }

      generosSelecionados = List<String>.from(generosLivro ?? []);
      setState(() {});
    }
  }

  void _carregarExistente(Map f) {
    _idFichamento = f["id_fichamento"];
    _livroId = f["id_livro"];

    tituloLivro = f["titulo"];
    capaLivro = f["capa_url"] ?? capaLivro;
    generosLivro = (f["generos"] as List?)?.map((e) => e.toString()).toList() ?? [];
    generosSelecionados = List<String>.from(generosLivro ?? []);

    _intro.text = f["introducao"] ?? "";
    _cenario.text = f["espaco"] ?? "";
    _personagens.text = f["personagens"] ?? "";
    _narrativa.text = f["narrativa"] ?? "";
    _critica.text = f["conclusao"] ?? "";
    _frase.text = f["frase_favorita"] ?? "";

    formato = f["formato"] ?? formato;
    visibilidade = f["visibilidade"] ?? visibilidade;
    nota = f["nota"] ?? nota;

    dataInicio = DateTime.tryParse(f["data_inicio"] ?? "");
    dataFim = f["data_fim"] != null ? DateTime.tryParse(f["data_fim"]) : null;

    setState(() {});
  }

  Future<void> _salvar() async {
    if (_intro.text.trim().isEmpty) return _erro("Introdução obrigatória");

    final body = {
      "id_fichamento": _idFichamento,
      "id_livro": _livroId,
      "introducao": _intro.text.trim(),
      "espaco": _cenario.text.trim(),
      "personagens": _personagens.text.trim(),
      "narrativa": _narrativa.text.trim(),
      "conclusao": _critica.text.trim(),
      "visibilidade": visibilidade,
      "data_inicio": dataInicio!.toIso8601String(),
      "data_fim": dataFim?.toIso8601String(),
      "formato": formato,
      "frase_favorita": _frase.text.trim(),
      "nota": nota,
      "generos": generosSelecionados,
    };

    if (!await FichamentoService().upsert(body)) return _erro("Erro ao salvar");
    Navigator.pop(context, true);
  }

  void _erro(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCCEE4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6E4A8E),
        title: Text(_idFichamento != null ? "Editar Fichamento" : "Criar Fichamento",
        style: const TextStyle(fontWeight: FontWeight.w600)),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            /// CAPA
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                capaLivro,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 250,
                  alignment: Alignment.center,
                  color: Colors.black26,
                  child: const Icon(Icons.image_not_supported,
                      color: Colors.white, size: 65),
                ),
              ),
            ),

            const SizedBox(height: 14),

            if (tituloLivro != null) ...[
              Text(tituloLivro!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4C2D63),
                ),
              ),
            ],

            if (generosLivro?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: generosLivro!.map((g) =>
                  Chip(
                    label: Text(g, style: const TextStyle(color: Color(0xFF4C2D63),fontWeight: FontWeight.w600)),
                    backgroundColor: const Color(0xFFECDFFA),
                    elevation: 2,
                  )
                ).toList(),
              ),
            ],

            const SizedBox(height: 30),

            /// INPUTS
            _field(_intro, "Introdução", Icons.menu_book),
            _field(_cenario, "Cenário", Icons.landscape),
            _field(_personagens, "Personagens", Icons.people),
            _field(_narrativa, "Narrativa", Icons.description),
            _field(_critica, "Críticas", Icons.comment),
            _field(_frase, "Frase favorita", Icons.format_quote),

            const SizedBox(height: 22),
            _data("Início", dataInicio, (x) => setState(() => dataInicio = x)),
            _data("Fim", dataFim, (x) => setState(() => dataFim = x)),

            const SizedBox(height: 25),

            _titulo("Formato"),
            rowSel([
              _sel("E-reader", Icons.phone_android, "e-reader"),
              _sel("Físico", Icons.menu_book, "fisico"),
              _sel("Audiobook", Icons.headset, "audiobook"),
            ]),

            const SizedBox(height: 24),

            _titulo("Visibilidade"),
            rowSel([
              _sel("Privado", Icons.lock, "PRIVADO", g: "vis"),
              _sel("Público", Icons.lock_open, "PUBLICO", g: "vis"),
            ]),

            const SizedBox(height: 24),

            _titulo("Classificação"),
            Slider(
              value: nota.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: nota.toString(),
              activeColor: const Color(0xFF6E4A8E),
              inactiveColor: Colors.grey.shade400,
              onChanged: (v) => setState(() => nota = v.toInt()),
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              icon: const Icon(Icons.check, size: 22),
              label: const Text("Salvar", style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E4A8E),
                elevation: 4,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: _salvar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(c, l, i) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: c,
      minLines: 3,
      maxLines: null,
      style: const TextStyle(color: Color(0xFF382246),fontSize:16,fontWeight: FontWeight.w500),

      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFEFE0F6),

        prefixIcon: Icon(i, color: Color(0xFF6E4A8E)),
        labelText: l,
        labelStyle: const TextStyle(
          color: Color(0xFF6E4A8E),
          fontWeight: FontWeight.w600,
        ),

        hintText: _ph(l),
        hintStyle: const TextStyle(color: Color(0xFF8C75A4)),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF6E4A8E), width: 2),
        ),
      ),
    ),
  );

  String _ph(String l) => {
    "Introdução": "Primeiras impressões, resumo inicial...",
    "Cenário": "Onde a história se passa?",
    "Personagens": "Principais figuras da narrativa",
    "Narrativa": "Resumo da trama e desenvolvimentos",
    "Críticas": "O que achou? Pontos fortes e fracos",
    "Frase favorita": "Trecho marcante e especial",
  }[l] ?? "";

  Widget _data(t, d, f) => TextButton.icon(
    icon: const Icon(Icons.date_range, color: Color(0xFF6E4A8E)),
    onPressed: () async {
      final x = await showDatePicker(
        context: context,
        initialDate: d ?? DateTime.now(),
        firstDate: DateTime(1800),
        lastDate: DateTime(2100),
      );
      if (x != null) f(x);
    },
    label: Text(
      "$t: ${d != null ? "${d.day}/${d.month}/${d.year}" : "-"}",
      style: const TextStyle(color: Color(0xFF4C2D63), fontSize: 16,fontWeight: FontWeight.w600),
    ),
  );

  Widget _sel(String txt, icon, v,{String g = "formato"}) {
    bool ativo = g=="formato" ? formato==v : visibilidade==v;

    return InkWell(
      onTap:()=>setState(()=>g=="formato"?formato=v:visibilidade=v),
      child:AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration:BoxDecoration(
          borderRadius:BorderRadius.circular(16),
          color:ativo ? const Color(0xFF8A6EB0) : const Color(0xFFEADCF3),

          border:Border.all(
            color:ativo ? const Color(0xFF563575) : Colors.grey.shade400,width:2),
          
          boxShadow:ativo?[
            BoxShadow(color: Colors.black26,blurRadius:5,offset:Offset(0,3))
          ]:[],
        ),
        child:Column(children:[
          Icon(icon,color:ativo?Colors.white:Color(0xFF563575)),
          const SizedBox(height:6),
          Text(txt,
            style:TextStyle(
              color:ativo?Colors.white:Color(0xFF563575),
              fontWeight:FontWeight.w600))
        ]),
      ),
    );
  }

  Row rowSel(w)=>Row(
    mainAxisAlignment:MainAxisAlignment.spaceEvenly,children:w);

  Widget _titulo(t)=>Padding(
    padding:const EdgeInsets.only(bottom:6),
    child:Text(t,style:const TextStyle(
      color:Color(0xFF4C2D63),
      fontSize:19,
      fontWeight:FontWeight.bold
    )),
  );
}
