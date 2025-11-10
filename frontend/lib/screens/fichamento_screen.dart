import 'package:flutter/material.dart';
import '../services/fichamento_service.dart';
import '../services/api_service.dart';

class FichamentoScreen extends StatefulWidget {
  final int? livroId; // quando vier de detalhes do livro
  final Map? fichamentoExistente; // quando for editar

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

  final FichamentoService service = FichamentoService();

  String formato = 'fisico';
  String visibilidade = 'PRIVADO';
  DateTime dataInicio = DateTime.now();
  DateTime? dataFim;
  int nota = 5;

  int? _livroId;
  int? _idFichamento; // para editar

  bool loading = false;

  @override
  void initState() {
    super.initState();
    _livroId = widget.livroId;
    if (widget.fichamentoExistente != null) {
      _carregarExistente(widget.fichamentoExistente!);
    } else if (_livroId != null) {
      _preloadMeuFichamento(_livroId!);
    }
  }

  void _carregarExistente(Map f) {
    _idFichamento = f['id_fichamento'];
    _livroId = f['id_livro'];
    _intro.text = f['introducao'] ?? '';
    _cenario.text = f['espaco'] ?? '';
    _personagens.text = f['personagens'] ?? '';
    _narrativa.text = f['narrativa'] ?? '';
    _critica.text = f['conclusao'] ?? '';
    _frase.text = f['frase_favorita'] ?? '';
    visibilidade = f['visibilidade'] ?? 'PRIVADO';
    formato = f['formato'] ?? 'fisico';
    nota = (f['nota'] ?? 5) is int ? f['nota'] : int.tryParse('${f['nota']}') ?? 5;
    dataInicio = DateTime.tryParse(f['data_inicio'] ?? '') ?? DateTime.now();
    dataFim = (f['data_fim'] != null) ? DateTime.tryParse(f['data_fim']) : null;
    setState(() {});
  }

  Future<void> _preloadMeuFichamento(int idLivro) async {
    try {
      final f = await service.meuPorLivro(idLivro);
      if (f != null) {
        _carregarExistente(f);
      }
    } catch (_) {}
  }

  Future<void> _pickDataInicio() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      initialDate: dataInicio,
    );
    if (d != null) setState(() => dataInicio = d);
  }

  Future<void> _pickDataFim() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      initialDate: dataFim ?? DateTime.now(),
    );
    if (d != null) setState(() => dataFim = d);
  }

  Future<void> _excluir() async {
    if (_idFichamento == null) return;
    final api = ApiService();
    final r = await api.delete('fichamentos/$_idFichamento');
    if (r.statusCode == 200) {
      _show('Fichamento excluído.');
      Navigator.pop(context);
    } else {
      _show('Erro ao excluir: ${r.body}');
    }
  }

  Future<void> _salvar() async {
    if (_livroId == null) {
      _show('Selecione um livro para o fichamento.');
      return;
    }
    if (_intro.text.trim().isEmpty) {
      _show('Introdução é obrigatória.');
      return;
    }

    setState(() => loading = true);

    final body = {
      if (_idFichamento != null) 'id_fichamento': _idFichamento,
      'id_livro': _livroId,
      'introducao': _intro.text.trim(),
      'espaco': _cenario.text.trim(),
      'personagens': _personagens.text.trim(),
      'narrativa': _narrativa.text.trim(),
      'conclusao': _critica.text.trim(),
      'visibilidade': visibilidade,
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim?.toIso8601String(),
      'formato': formato,
      'frase_favorita': _frase.text.trim(),
      'nota': nota,
    };

    final ok = await service.upsert(body);
    setState(() => loading = false);

    if (ok) {
      _show('Fichamento salvo com sucesso!');
      Navigator.pop(context);
    } else {
      _show('Erro ao salvar fichamento.');
    }
  }

  void _show(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final deletarVisivel = _idFichamento != null;

    return Scaffold(
      backgroundColor: const Color(0xFFD2C9D4),
      appBar: AppBar(
        title: const Text('Fichamento'),
        backgroundColor: const Color(0xFF4F3466),
        actions: [
          if (deletarVisivel)
            IconButton(
              tooltip: 'Excluir fichamento',
              onPressed: _excluir,
              icon: const Icon(Icons.delete, color: Colors.white),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _livroId != null
                      ? 'Livro ID: $_livroId'
                      : 'Nenhum livro selecionado',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4F3466),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _show(
                    'Dica: abra a tela de detalhes do livro e use "Criar/Editar meu fichamento".'),
                child: const Text('Selecionar livro'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildField(_intro, 'Introdução'),
          _buildField(_cenario, 'Cenário'),
          _buildField(_personagens, 'Personagens'),
          _buildField(_narrativa, 'Narrativa'),
          _buildField(_critica, 'Críticas'),
          _buildField(_frase, 'Frase favorita'),

          const SizedBox(height: 16),
          _buildDropdown<String>(
            label: 'Tipo de livro',
            value: formato,
            items: const [
              DropdownMenuItem(value: 'fisico', child: Text('Físico')),
              DropdownMenuItem(value: 'e-reader', child: Text('Digital')),
              DropdownMenuItem(value: 'audiobook', child: Text('Audiobook')),
            ],
            onChanged: (v) => setState(() => formato = v!),
          ),
          const SizedBox(height: 16),

          _buildDropdown<String>(
            label: 'Visibilidade',
            value: visibilidade,
            items: const [
              DropdownMenuItem(value: 'PRIVADO', child: Text('Privado')),
              DropdownMenuItem(value: 'PUBLICO', child: Text('Público')),
            ],
            onChanged: (v) => setState(() => visibilidade = v!),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: _pickDataInicio,
                  icon: const Icon(Icons.date_range, color: Color(0xFF4F3466)),
                  label: Text('Início: ${_fmtDate(dataInicio)}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton.icon(
                  onPressed: _pickDataFim,
                  icon:
                      const Icon(Icons.event_available, color: Color(0xFF4F3466)),
                  label: Text('Término: ${dataFim != null ? _fmtDate(dataFim!) : '-'}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              const Text('Nota:', style: TextStyle(color: Color(0xFF4F3466))),
              Expanded(
                child: Slider(
                  value: nota.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  activeColor: const Color(0xFF947CAC),
                  label: '$nota',
                  onChanged: (v) => setState(() => nota = v.toInt()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          loading
              ? const CircularProgressIndicator(color: Color(0xFF4F3466))
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF947CAC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _salvar,
                  child: const SizedBox(
                    width: double.infinity,
                    child: Center(child: Text('Salvar')),
                  ),
                ),
        ]),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF4F3466)),
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF947CAC)),
          ),
        ),
        maxLines: null,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF947CAC)),
        ),
      ),
      value: value,
      items: items,
      onChanged: onChanged,
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
