import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/nfc_status_entity.dart';
import '../repositories/nfc_gate_repository.dart';

class CheckNfcUsecase implements UseCase<NfcStatusEntity, NoParams> {
  final NfcGateRepository _repository;
  CheckNfcUsecase(this._repository);

  @override
  Future<Either<Failure, NfcStatusEntity>> call(NoParams params) {
    return _repository.checkNfcStatus();
  }
}
