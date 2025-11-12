import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_service.dart';

class OfflineSyncService {
  static const _keyQueue = 'offline_queue_fichamentos';
  static const _keyDraftPrefix = 'draft_fichamento_';
  final _storage = const FlutterSecureStorage();
  final ApiService _api = ApiService();

  Future<void> enqueueUpsert(Map<String, dynamic> body) async {
    final raw = await _storage.read(key: _keyQueue);
    final List queue = raw != null ? (jsonDecode(raw) as List) : [];
    queue.add(body);
    await _storage.write(key: _keyQueue, value: jsonEncode(queue));
  }

  Future<List<Map<String, dynamic>>> pending() async {
    final raw = await _storage.read(key: _keyQueue);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list;
  }

  Future<void> _saveQueue(List list) async {
    await _storage.write(key: _keyQueue, value: jsonEncode(list));
  }

  /// Tenta sincronizar a fila quando houver Internet
  Future<void> syncPending() async {
    try {
      final conn = await Connectivity().checkConnectivity();
      if (conn == ConnectivityResult.none) return;

      var list = await pending();
      if (list.isEmpty) return;

      // consome a fila, tentando enviar cada item
      final newQueue = <Map<String, dynamic>>[];
      for (final item in list) {
        try {
          final resp = await _api.post('fichamentos', item);
          if (resp.statusCode == 200 || resp.statusCode == 201) {
            // ok, removido da fila
          } else {
            // mantém na fila
            newQueue.add(item);
          }
        } catch (_) {
          newQueue.add(item);
        }
      }
      await _saveQueue(newQueue);
    } catch (e) {
      if (kDebugMode) print('syncPending error: $e');
    }
  }

  Future<void> saveDraft(int idLivro, Map<String, dynamic> data) async {
    await _storage.write(key: '$_keyDraftPrefix$idLivro', value: jsonEncode(data));
  }

  Future<Map<String, dynamic>?> loadDraft(int idLivro) async {
    final raw = await _storage.read(key: '$_keyDraftPrefix$idLivro');
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  Future<void> clearDraft(int idLivro) async {
    await _storage.delete(key: '$_keyDraftPrefix$idLivro');
  }
}
