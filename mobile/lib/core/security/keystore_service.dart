import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Bridges to the Kotlin KeystoreManager via MethodChannel.
/// On first call, generates an Ed25519 keypair stored in Android Keystore
/// (StrongBox preferred). The public key is returned as base64.
class KeystoreService {
  static const _channel = MethodChannel('com.tramessage/keystore');
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Keypair ──────────────────────────────────────────────────────────────

  Future<String> getOrCreatePublicKey() async {
    final result = await _channel.invokeMethod<String>('getOrCreatePublicKey');
    return result!;
  }

  Future<String> getKeyId() async {
    final result = await _channel.invokeMethod<String>('getKeyId');
    return result!;
  }

  /// Signs [data] (UTF-8 bytes of JSON payload without the signature field)
  /// using the Android Keystore Ed25519 private key.
  /// Returns base64-encoded signature.
  Future<String> sign(String data) async {
    final result = await _channel.invokeMethod<String>('sign', {'data': data});
    return result!;
  }

  /// Verifies a signature from a KNOWN senderKeyId.
  /// senderPublicKey: base64 Ed25519 public key
  /// data: the original signed content (without signature field)
  /// signature: base64 signature
  Future<bool> verify({
    required String senderPublicKey,
    required String data,
    required String signature,
  }) async {
    final result = await _channel.invokeMethod<bool>('verify', {
      'publicKey': senderPublicKey,
      'data': data,
      'signature': signature,
    });
    return result ?? false;
  }

  // ── Local encrypted storage (AES-GCM via Keystore) ───────────────────────

  Future<void> secureWrite(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> secureRead(String key) async {
    return _storage.read(key: key);
  }

  Future<void> secureDelete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> secureDeleteAll() async {
    await _storage.deleteAll();
  }

  Future<Map<String, String>> secureReadAll() async {
    return _storage.readAll();
  }
}
