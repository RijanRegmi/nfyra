import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/history_repository.dart';

class ClearHistoryUsecase implements UseCase<void, NoParams> {
  final HistoryRepository _repository;
  ClearHistoryUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return _repository.clearAll();
  }
}
