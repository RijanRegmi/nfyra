import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nfyra/core/error/failures.dart';
import 'package:nfyra/core/security/keystore_service.dart';
import 'package:nfyra/core/security/nonce_cache.dart';
import 'package:nfyra/features/receive/data/repositories/receive_repository_impl.dart';

class MockKeystoreService extends Mock implements KeystoreService {}
class MockNonceCache extends Mock implements NonceCache {}

void main() {
  late MockKeystoreService mockKeystore;
  late MockNonceCache mockNonceCache;
  late ReceiveRepositoryImpl repository;

  setUp(() {
    mockKeystore = MockKeystoreService();
    mockNonceCache = MockNonceCache();
    repository = ReceiveRepositoryImpl(mockKeystore, mockNonceCache);
  });

  group('Payload Validation & Security', () {
    test('Rejects oversized payloads (>1 KB)', () async {
      final hugeString = 'A' * 1200;
      final payload = {
        'v': 1,
        'type': 'text',
        'content': hugeString,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'expiresAt': DateTime.now().toUtc().add(const Duration(seconds: 30)).toIso8601String(),
        'nonce': 'nonce-123',
        'senderKeyId': 'key-123',
        'signature': 'sig-123',
      };

      final result = await repository.validateAndParse(payload);
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<PayloadValidationFailure>()),
        (_) => fail('Expected failure'),
      );
    });

    test('Rejects unknown fields or missing fields', () async {
      final payload = {
        'v': 1,
        'type': 'text',
        'content': 'Hello',
        'untrustedExtraField': 'malicious',
      };

      final result = await repository.validateAndParse(payload);
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<PayloadValidationFailure>()),
        (_) => fail('Expected failure'),
      );
    });

    test('Rejects expired payload (>60s)', () async {
      final past = DateTime.now().toUtc().subtract(const Duration(seconds: 70));
      final payload = {
        'v': 1,
        'type': 'text',
        'content': 'Hello',
        'createdAt': past.toIso8601String(),
        'expiresAt': past.add(const Duration(seconds: 30)).toIso8601String(),
        'nonce': 'nonce-past',
        'senderKeyId': 'key-123',
        'signature': 'sig-123',
      };

      final result = await repository.validateAndParse(payload);
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<PayloadExpiredFailure>()),
        (_) => fail('Expected failure'),
      );
    });

    test('Rejects dangerous link protocols (javascript:, file:, data:, intent:)', () async {
      final dangerousUrls = [
        'javascript:alert(1)',
        'file:///etc/passwd',
        'data:text/html,<script>alert(1)</script>',
        'intent://scan/#Intent;scheme=zxing;package=com.google.zxing.client.android;end',
        'http://insecure.example.com', // Must be https
      ];

      for (final url in dangerousUrls) {
        final payload = {
          'v': 1,
          'type': 'link',
          'content': url,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
          'expiresAt': DateTime.now().toUtc().add(const Duration(seconds: 30)).toIso8601String(),
          'nonce': 'nonce-$url',
          'senderKeyId': 'key-123',
          'signature': 'sig-123',
        };

        final result = await repository.validateAndParse(payload);
        expect(result.isLeft(), isTrue, reason: 'URL $url should be rejected');
      }
    });

    test('Rejects replayed nonces', () async {
      when(() => mockNonceCache.contains('replayed-nonce')).thenAnswer((_) async => true);

      final payload = {
        'v': 1,
        'type': 'text',
        'content': 'Hello',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'expiresAt': DateTime.now().toUtc().add(const Duration(seconds: 30)).toIso8601String(),
        'nonce': 'replayed-nonce',
        'senderKeyId': 'key-123',
        'signature': 'sig-123',
      };

      final result = await repository.validateAndParse(payload);
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<PayloadReplayFailure>()),
        (_) => fail('Expected replay failure'),
      );
    });

    test('Accepts valid https link and verifies signature', () async {
      const nonce = 'unique-nonce-1';
      when(() => mockNonceCache.contains(nonce)).thenAnswer((_) async => false);
      when(() => mockNonceCache.record(nonce)).thenAnswer((_) async {});
      when(() => mockKeystore.verify(
            senderPublicKey: any(named: 'senderPublicKey'),
            data: any(named: 'data'),
            signature: any(named: 'signature'),
          )).thenAnswer((_) async => true);

      final payload = {
        'v': 1,
        'type': 'link',
        'content': 'https://github.com/project',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'expiresAt': DateTime.now().toUtc().add(const Duration(seconds: 30)).toIso8601String(),
        'nonce': nonce,
        'senderKeyId': 'validKey123',
        'signature': 'validSig123',
      };

      final result = await repository.validateAndParse(payload);
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Expected success: ${failure.message}'),
        (message) {
          expect(message.content, 'https://github.com/project');
          expect(message.type, 'link');
          expect(message.signatureVerified, isTrue);
        },
      );
    });
  });
}

