import 'dart:convert';
import '../constants/nfc_constants.dart';
import 'keystore_service.dart';

/// Persists a small LRU-style nonce cache to prevent replay attacks.
/// Nonces are stored as JSON via secure storage.
class NonceCache {
  static const _storageKey = 'nonce_cache';
  final KeystoreService _keystore;

  NonceCache(this._keystore);

  Future<List<_NonceEntry>> _load() async {
    final raw = await _keystore.secureRead(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => _NonceEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<_NonceEntry> entries) async {
    await _keystore.secureWrite(
      _storageKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  /// Returns true if the nonce has already been seen (replay detected).
  Future<bool> contains(String nonce) async {
    final entries = await _load();
    final now = DateTime.now();
    final fresh = entries
        .where((e) => now.difference(e.seenAt).inHours < kNonceCacheTtlHours)
        .toList();
    return fresh.any((e) => e.nonce == nonce);
  }

  /// Records a nonce as seen. Evicts old entries beyond cache size.
  Future<void> record(String nonce) async {
    var entries = await _load();
    final now = DateTime.now();
    // Evict expired
    entries = entries
        .where((e) => now.difference(e.seenAt).inHours < kNonceCacheTtlHours)
        .toList();
    entries.add(_NonceEntry(nonce: nonce, seenAt: now));
    // Keep only last N
    if (entries.length > kNonceCacheSize) {
      entries = entries.sublist(entries.length - kNonceCacheSize);
    }
    await _save(entries);
  }
}

class _NonceEntry {
  final String nonce;
  final DateTime seenAt;

  _NonceEntry({required this.nonce, required this.seenAt});

  factory _NonceEntry.fromJson(Map<String, dynamic> json) {
    return _NonceEntry(
      nonce: json['nonce'] as String,
      seenAt: DateTime.parse(json['seenAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'nonce': nonce,
        'seenAt': seenAt.toIso8601String(),
      };
}
