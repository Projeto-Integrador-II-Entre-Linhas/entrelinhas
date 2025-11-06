class Fichamento {
  int? id;
  int idUsuario;
  int idLivro;
  String introducao;
  String? espaco;
  String? personagens;
  String? narrativa;
  String? conclusao;
  String visibilidade;
  DateTime dataInicio;
  DateTime? dataFim;
  String formato;
  String? fraseFavorita;
  int nota;

  Fichamento({
    this.id,
    required this.idUsuario,
    required this.idLivro,
    required this.introducao,
    this.espaco,
    this.personagens,
    this.narrativa,
    this.conclusao,
    this.visibilidade = 'PRIVADO',
    required this.dataInicio,
    this.dataFim,
    required this.formato,
    this.fraseFavorita,
    required this.nota
  });

  factory Fichamento.fromJson(Map json) => Fichamento(
    id: json['id_fichamento'],
    idUsuario: json['id_usuario'],
    idLivro: json['id_livro'],
    introducao: json['introducao'],
    espaco: json['espaco'],
    personagens: json['personagens'],
    narrativa: json['narrativa'],
    conclusao: json['conclusao'],
    visibilidade: json['visibilidade'],
    dataInicio: DateTime.parse(json['data_inicio']),
    dataFim: json['data_fim'] != null ? DateTime.parse(json['data_fim']) : null,
    formato: json['formato'],
    fraseFavorita: json['frase_favorita'],
    nota: json['nota'],
  );

  Map<String,dynamic> toJson() => {
    'id_usuario': idUsuario,
    'id_livro': idLivro,
    'introducao': introducao,
    'espaco': espaco,
    'personagens': personagens,
    'narrativa': narrativa,
    'conclusao': conclusao,
    'visibilidade': visibilidade,
    'data_inicio': dataInicio.toIso8601String(),
    'data_fim': dataFim?.toIso8601String(),
    'formato': formato,
    'frase_favorita': fraseFavorita,
    'nota': nota
  };
}
