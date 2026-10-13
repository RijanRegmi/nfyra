import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/nfc_payload.dart';
import '../../domain/repositories/nfc_repository.dart';
import '../datasources/nfc_datasource.dart';

class NfcRepositoryImpl implements NfcRepository {
  final NfcDatasource _datasource;
  NfcRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, void>> armHce(NfcPayload payload) async {
    try {
      final json = {
        'v': payload.v,
        'type': payload.type,
        'content': payload.content,
        'createdAt': payload.createdAt.toIso8601String(),
        'expiresAt': payload.expiresAt.toIso8601String(),
        'nonce': payload.nonce,
        'senderKeyId': payload.senderKeyId,
        'signature': payload.signature,
      };
      await _datasource.armHce(json);
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('Failed to arm HCE: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> disarmHce() async {
    try {
      await _datasource.disarmHce();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('Failed to disarm HCE: $e'));
    }
  }
}
