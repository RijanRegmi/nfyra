import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/history_message.dart';

abstract class HistoryRepository {
  Future<Either<Failure, List<HistoryMessage>>> getMessages();
  Future<Either<Failure, void>> saveMessage(HistoryMessage message);
  Future<Either<Failure, void>> deleteMessage(String id);
  Future<Either<Failure, void>> clearAll();
}
