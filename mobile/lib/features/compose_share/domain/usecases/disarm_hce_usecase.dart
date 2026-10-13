import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/nfc_repository.dart';

class DisarmHceUsecase implements UseCase<void, NoParams> {
  final NfcRepository _repository;
  DisarmHceUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return _repository.disarmHce();
  }
}
