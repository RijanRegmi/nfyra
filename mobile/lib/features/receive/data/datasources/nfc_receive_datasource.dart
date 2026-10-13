import 'package:flutter/services.dart';

/// Receives the NFC payload from the Android intent via EventChannel.
abstract class NfcReceiveDatasource {
  Stream<Map<String, dynamic>> get payloadStream;
}

class NfcReceiveDatasourceImpl implements NfcReceiveDatasource {
  static const _channel = EventChannel('com.nfyra/nfc_receive');

  @override
  Stream<Map<String, dynamic>> get payloadStream {
    return _channel.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return Map<String, dynamic>.from(event);
      }
      throw const FormatException('Invalid NFC payload format');
    });
  }
}

