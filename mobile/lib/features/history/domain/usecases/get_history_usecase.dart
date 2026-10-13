import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/history_message.dart';
import '../repositories/history_repository.dart';

class GetHistoryUsecase implements UseCase<List<HistoryMessage>, NoParams> {
  final HistoryRepository _repository;
  GetHistoryUsecase(this._repository);

  @override
  Future<Either<Failure, List<HistoryMessage>>> call(NoParams params) {
    return _repository.getMessages();
  }
}
