import 'package:flutter/services.dart';

abstract class NfcDatasource {
  Future<void> armHce(Map<String, dynamic> payloadJson);
  Future<void> disarmHce();
}

class NfcDatasourceImpl implements NfcDatasource {
  static const _channel = MethodChannel('com.nfyra/hce');

  NfcDatasourceImpl();

  @override
  Future<void> armHce(Map<String, dynamic> payloadJson) async {
    await _channel.invokeMethod<void>('armHce', {'payload': payloadJson});
  }

  @override
  Future<void> disarmHce() async {
    await _channel.invokeMethod<void>('disarmHce');
  }
}

