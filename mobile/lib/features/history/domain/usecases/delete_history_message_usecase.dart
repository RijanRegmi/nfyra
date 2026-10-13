import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/history_repository.dart';

class DeleteHistoryMessageUsecase implements UseCase<void, String> {
  final HistoryRepository _repository;
  DeleteHistoryMessageUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(String params) {
    return _repository.deleteMessage(params);
  }
}
