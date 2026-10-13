import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/security/keystore_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/constants/nfc_constants.dart';
import '../entities/nfc_payload.dart';
import '../repositories/nfc_repository.dart';

class ArmHceParams {
  final String content;
  final String type; // 'text' | 'link'

  const ArmHceParams({required this.content, required this.type});
}

class ArmHceUsecase implements UseCase<void, ArmHceParams> {
  final NfcRepository _repository;
  final KeystoreService _keystore;
  static const _uuid = Uuid();

  ArmHceUsecase(this._repository, this._keystore);

  @override
  Future<Either<Failure, void>> call(ArmHceParams params) async {
    try {
      final now = DateTime.now().toUtc();
      final expiresAt = now.add(const Duration(seconds: kShareWindowSeconds));
      final nonce = _uuid.v4();
      final keyId = await _keystore.getKeyId();

      // Build the payload map without signature for signing
      final payloadForSigning = {
        'v': 1,
        'type': params.type,
        'content': params.content,
        'createdAt': now.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'nonce': nonce,
        'senderKeyId': keyId,
      };

      final dataToSign = jsonEncode(payloadForSigning);
      final signature = await _keystore.sign(dataToSign);

      final payload = NfcPayload(
        v: 1,
        type: params.type,
        content: params.content,
        createdAt: now,
        expiresAt: expiresAt,
        nonce: nonce,
        senderKeyId: keyId,
        signature: signature,
      );

      return _repository.armHce(payload);
    } catch (e) {
      return Left(CryptoFailure('Failed to sign payload: $e'));
    }
  }
}
