import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Offline Security Checks', () {
    test('AndroidManifest.xml must NOT declare INTERNET permission', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue, reason: 'Manifest file must exist');

      final content = manifestFile.readAsStringSync();

      // Ensure no INTERNET permission exists
      expect(
        content.contains('android.permission.INTERNET'),
        isFalse,
        reason: 'Violation of Step 4: Tramessage is strictly offline and must never declare INTERNET permission',
      );

      // Verify required permissions
      expect(content.contains('android.permission.NFC'), isTrue);
      expect(content.contains('android.permission.USE_BIOMETRIC'), isTrue);
      expect(content.contains('android:allowBackup="false"'), isTrue);
    });
  });
}
