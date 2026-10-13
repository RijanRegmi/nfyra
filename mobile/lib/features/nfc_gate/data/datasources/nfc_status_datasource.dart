import 'package:flutter/services.dart';

/// Calls Kotlin via MethodChannel to check NFC hardware, enabled state, and HCE support.
abstract class NfcStatusDatasource {
  Future<NfcStatus> checkStatus();
  Future<void> openNfcSettings();
}

class NfcStatus {
  final bool hasHardware;
  final bool isEnabled;
  final bool hasHce;

  const NfcStatus({
    required this.hasHardware,
    required this.isEnabled,
    required this.hasHce,
  });
}

class NfcStatusDatasourceImpl implements NfcStatusDatasource {
  static const _channel = MethodChannel('com.tramessage/nfc_gate');

  @override
  Future<NfcStatus> checkStatus() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('checkStatus');
    return NfcStatus(
      hasHardware: (result?['hasHardware'] as bool?) ?? false,
      isEnabled: (result?['isEnabled'] as bool?) ?? false,
      hasHce: (result?['hasHce'] as bool?) ?? false,
    );
  }

  @override
  Future<void> openNfcSettings() async {
    await _channel.invokeMethod<void>('openNfcSettings');
  }
}
