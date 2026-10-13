import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/nfc_payload.dart';

abstract class NfcRepository {
  /// Arms the HCE service with a signed payload for up to 30 seconds.
  Future<Either<Failure, void>> armHce(NfcPayload payload);

  /// Disarms the HCE service and wipes the payload from memory.
  Future<Either<Failure, void>> disarmHce();
}
