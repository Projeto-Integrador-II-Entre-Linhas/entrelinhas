import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class SolicitacaoService {
  final ApiService api = ApiService();

  // ----------------------------------------------------------
  // Criar nova solicitação de livro (usuário comum)
  // ----------------------------------------------------------
  Future<Map?> criarSolicitacao(Map<String, dynamic> body) async {
    final r = await api.post('solicitacoes', body);
    if (r.statusCode == 201) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    } else {
      try {
        final msg = jsonDecode(r.body)['error'] ?? 'Erro desconhecido';
        throw Exception(msg);
      } catch (_) {
        throw Exception('Erro ao criar solicitação (${r.statusCode})');
      }
    }
  }

  // ----------------------------------------------------------
  // Minhas solicitações (usuário autenticado)
  // ----------------------------------------------------------
  Future<List<Map<String, dynamic>>> minhas() async {
    final r = await api.get('solicitacoes/me');
    if (r.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(r.body));
    } else {
      return [];
    }
  }

  // ----------------------------------------------------------
  // Admin — listar solicitações pendentes
  // ----------------------------------------------------------
  Future<List<Map<String, dynamic>>> pendentes() async {
    final r = await api.get('solicitacoes');
    if (r.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(r.body));
    } else {
      return [];
    }
  }

  // ----------------------------------------------------------
  // Admin — aprovar solicitação (gera cadastro do livro)
  // ----------------------------------------------------------
  Future<bool> aprovar(int id) async {
    final r = await api.put('solicitacoes/$id/approve', {});
    return r.statusCode == 200;
  }

  // ----------------------------------------------------------
  // Admin — rejeitar solicitação (com motivo opcional)
  // ----------------------------------------------------------
  Future<bool> rejeitar(int id, {String? motivo}) async {
    final r = await api.put('solicitacoes/$id/reject', {
      if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
    });
    return r.statusCode == 200;
  }
}
