import 'dart:convert';
import '../../../../core/security/keystore_service.dart';
import '../../domain/entities/history_message.dart';

abstract class HistoryLocalDatasource {
  Future<List<HistoryMessage>> getMessages();
  Future<void> saveMessage(HistoryMessage message);
  Future<void> deleteMessage(String id);
  Future<void> clearAll();
}

class HistoryLocalDatasourceImpl implements HistoryLocalDatasource {
  static const _storageKey = 'nfyra_local_history';
  final KeystoreService _keystoreService;

  HistoryLocalDatasourceImpl(this._keystoreService);

  @override
  Future<List<HistoryMessage>> getMessages() async {
    final raw = await _keystoreService.secureRead(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final messages = list
          .map((item) => HistoryMessage.fromJson(item as Map<String, dynamic>))
          .toList();
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return messages;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveMessage(HistoryMessage message) async {
    final messages = await getMessages();
    messages.removeWhere((m) => m.id == message.id);
    messages.insert(0, message);
    await _keystoreService.secureWrite(
      _storageKey,
      jsonEncode(messages.map((m) => m.toJson()).toList()),
    );
  }

  @override
  Future<void> deleteMessage(String id) async {
    final messages = await getMessages();
    messages.removeWhere((m) => m.id == id);
    await _keystoreService.secureWrite(
      _storageKey,
      jsonEncode(messages.map((m) => m.toJson()).toList()),
    );
  }

  @override
  Future<void> clearAll() async {
    await _keystoreService.secureDelete(_storageKey);
  }
}

