import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import '../../../../core/constants/nfc_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/security/keystore_service.dart';
import '../../../../core/security/nonce_cache.dart';
import '../../domain/entities/received_message.dart';
import '../../domain/repositories/receive_repository.dart';

class ReceiveRepositoryImpl implements ReceiveRepository {
  final KeystoreService _keystore;
  final NonceCache _nonceCache;

  ReceiveRepositoryImpl(this._keystore, this._nonceCache);

  @override
  Future<Either<Failure, ReceivedMessage>> validateAndParse(
    Map<String, dynamic> rawPayload,
  ) async {
    try {
      // 1. Check max size (1 KB)
      final rawBytes = utf8.encode(jsonEncode(rawPayload));
      if (rawBytes.length > kPayloadMaxBytes) {
        return const Left(
          PayloadValidationFailure('Payload exceeds maximum allowed size (1 KB)'),
        );
      }

      // 2. Strict schema check: reject unexpected keys & check required keys
      const requiredKeys = {
        'v',
        'type',
        'content',
        'createdAt',
        'expiresAt',
        'nonce',
        'senderKeyId',
        'signature',
      };
      final keys = rawPayload.keys.toSet();
      if (!keys.containsAll(requiredKeys) || keys.length != requiredKeys.length) {
        return const Left(
          PayloadValidationFailure('Invalid payload schema or unexpected fields'),
        );
      }

      // 3. Version check
      if (rawPayload['v'] != 1) {
        return const Left(
          PayloadValidationFailure('Unsupported payload version (expected v=1)'),
        );
      }

      // 4. Type check
      final type = rawPayload['type'] as String;
      if (type != 'text' && type != 'link') {
        return const Left(
          PayloadValidationFailure('Invalid payload type (must be text or link)'),
        );
      }

      final content = rawPayload['content'] as String;

      // 5. Link sanitization check
      if (type == 'link') {
        final sanitized = _validateAndSanitizeLink(content);
        if (sanitized == null) {
          return const Left(
            PayloadValidationFailure(
              'Invalid or insecure link. Only valid https:// links are permitted.',
            ),
          );
        }
      }

      // 6. Expiry check
      final createdAtStr = rawPayload['createdAt'] as String;
      final expiresAtStr = rawPayload['expiresAt'] as String;
      final createdAt = DateTime.tryParse(createdAtStr)?.toUtc();
      final expiresAt = DateTime.tryParse(expiresAtStr)?.toUtc();

      if (createdAt == null || expiresAt == null) {
        return const Left(
          PayloadValidationFailure('Invalid timestamp format in payload'),
        );
      }

      final now = DateTime.now().toUtc();
      if (now.isAfter(expiresAt) ||
          now.difference(createdAt).inSeconds > kPayloadExpirySeconds) {
        return const Left(
          PayloadExpiredFailure('Message has expired (validity window exceeded)'),
        );
      }

      // 7. Replay / Nonce check
      final nonce = rawPayload['nonce'] as String;
      if (nonce.isEmpty) {
        return const Left(PayloadValidationFailure('Empty nonce'));
      }
      final isReplay = await _nonceCache.contains(nonce);
      if (isReplay) {
        return const Left(
          PayloadReplayFailure('Replay attack detected: message nonce already processed'),
        );
      }

      // 8. Signature verification
      final senderKeyId = rawPayload['senderKeyId'] as String;
      final signature = rawPayload['signature'] as String;

      final dataToSign = jsonEncode({
        'v': 1,
        'type': type,
        'content': content,
        'createdAt': createdAtStr,
        'expiresAt': expiresAtStr,
        'nonce': nonce,
        'senderKeyId': senderKeyId,
      });

      final verified = await _keystore.verify(
        senderPublicKey: senderKeyId,
        data: dataToSign,
        signature: signature,
      );

      if (!verified) {
        return const Left(
          PayloadSignatureFailure('Invalid message signature (verification failed)'),
        );
      }

      // 9. Record nonce in cache
      await _nonceCache.record(nonce);

      final message = ReceivedMessage(
        id: nonce,
        type: type,
        content: content,
        receivedAt: DateTime.now().toUtc(),
        createdAt: createdAt,
        senderKeyId: senderKeyId,
        signatureVerified: verified,
      );

      return Right(message);
    } catch (e) {
      return Left(PayloadValidationFailure('Failed to validate payload: $e'));
    }
  }

  String? _validateAndSanitizeLink(String url) {
    final trimmed = url.trim();
    // Reject control characters
    if (RegExp(r'[\x00-\x1F\x7F]').hasMatch(trimmed)) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasScheme ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.host.isEmpty) {
      return null;
    }
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('javascript:') ||
        lower.startsWith('data:') ||
        lower.startsWith('file:') ||
        lower.startsWith('intent:')) {
      return null;
    }
    return uri.toString();
  }
}
