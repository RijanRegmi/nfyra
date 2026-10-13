import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/history_message.dart';
import '../repositories/history_repository.dart';

class SaveHistoryMessageUsecase implements UseCase<void, HistoryMessage> {
  final HistoryRepository _repository;
  SaveHistoryMessageUsecase(this._repository);

  @override
  Future<Either<Failure, void>> call(HistoryMessage params) {
    return _repository.saveMessage(params);
  }
}
