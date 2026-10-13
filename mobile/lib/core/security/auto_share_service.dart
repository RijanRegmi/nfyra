import 'package:flutter/services.dart';

class AutoShareService {
  static const _channel = MethodChannel('com.nfyra/hce');

  Future<void> saveAutoShare({
    required String type,
    required String content,
    required bool enabled,
  }) async {
    await _channel.invokeMethod<void>('setAutoShare', {
      'type': type,
      'content': content,
      'enabled': enabled,
    });
  }

  Future<Map<String, dynamic>> getAutoShare() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getAutoShare');
    if (result == null) {
      return {'enabled': false, 'type': 'text', 'content': ''};
    }
    return {
      'enabled': (result['enabled'] as bool?) ?? false,
      'type': (result['type'] as String?) ?? 'text',
      'content': (result['content'] as String?) ?? '',
    };
  }

  Future<bool> requestIgnoreBatteryOptimizations() async {
    final result = await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimizations');
    return result ?? false;
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    final result = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
    return result ?? false;
  }
}

