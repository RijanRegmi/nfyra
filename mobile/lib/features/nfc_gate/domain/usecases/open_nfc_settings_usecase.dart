import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/nfc_gate_repository.dart';

class OpenNfcSettingsUsecase implements UseCase<void, NoParams> {
  final NfcGateRepository _repository;
  OpenNfcSettingsUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return _repository.openNfcSettings();
  }
}
