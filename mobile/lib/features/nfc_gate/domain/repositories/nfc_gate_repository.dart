import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/nfc_status_entity.dart';

abstract class NfcGateRepository {
  Future<Either<Failure, NfcStatusEntity>> checkNfcStatus();
  Future<Either<Failure, void>> openNfcSettings();
}
