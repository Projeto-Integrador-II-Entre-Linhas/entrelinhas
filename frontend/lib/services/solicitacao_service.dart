import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class SolicitacaoService {
  final ApiService api = ApiService();

  // ----------------------------------------------------------
  // Usuário comum — criar nova solicitação de livro
  // ----------------------------------------------------------
  Future<Map<String, dynamic>?> criarSolicitacao(Map<String, dynamic> body) async {
    final http.Response r = await api.post('solicitacoes', body);
    if (r.statusCode == 201) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    } else {
      try {
        final err = jsonDecode(r.body);
        throw Exception(err['error'] ?? 'Erro ao criar solicitação (${r.statusCode})');
      } catch (_) {
        throw Exception('Erro ao criar solicitação (${r.statusCode})');
      }
    }
  }

  // ----------------------------------------------------------
  // Usuário comum — listar suas próprias solicitações
  // ----------------------------------------------------------
  Future<List<Map<String, dynamic>>> minhas() async {
    final http.Response r = await api.get('solicitacoes/me');
    if (r.statusCode == 200 && r.body.isNotEmpty) {
      return List<Map<String, dynamic>>.from(jsonDecode(r.body));
    }
    return [];
  }

  // ----------------------------------------------------------
  // Admin — listar todas as solicitações pendentes
  // ----------------------------------------------------------
  Future<List<Map<String, dynamic>>> pendentes() async {
    final http.Response r = await api.get('solicitacoes');
    if (r.statusCode == 200 && r.body.isNotEmpty) {
      return List<Map<String, dynamic>>.from(jsonDecode(r.body));
    }
    return [];
  }

  // ----------------------------------------------------------
  // Admin — visualizar detalhes de uma solicitação específica
  // ----------------------------------------------------------
  Future<Map<String, dynamic>?> detalhe(int id) async {
    final http.Response r = await api.get('solicitacoes/$id');
    if (r.statusCode == 200 && r.body.isNotEmpty) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    return null;
  }

  // ----------------------------------------------------------
  // Admin — atualizar informações de uma solicitação
  // ----------------------------------------------------------
  Future<bool> atualizar(int id, Map<String, dynamic> body) async {
    final http.Response r = await api.put('solicitacoes/$id', body);
    return r.statusCode == 200;
  }

  // ----------------------------------------------------------
  // Admin — aprovar solicitação (gera o livro)
  // ----------------------------------------------------------
  Future<bool> aprovar(int id) async {
    final http.Response r = await api.put('solicitacoes/$id/approve', {});
    return r.statusCode == 200;
  }

  // ----------------------------------------------------------
  // Admin — rejeitar solicitação (com motivo opcional)
  // ----------------------------------------------------------
  Future<bool> rejeitar(int id, {String? motivo}) async {
    final http.Response r = await api.put('solicitacoes/$id/reject', {
      if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
    });
    return r.statusCode == 200;
  }
}
