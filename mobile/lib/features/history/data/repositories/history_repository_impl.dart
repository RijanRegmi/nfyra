import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/history_message.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_local_datasource.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryLocalDatasource _datasource;

  HistoryRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, List<HistoryMessage>>> getMessages() async {
    try {
      final messages = await _datasource.getMessages();
      return Right(messages);
    } catch (e) {
      return Left(StorageFailure('Failed to load history: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveMessage(HistoryMessage message) async {
    try {
      await _datasource.saveMessage(message);
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure('Failed to save message to history: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(String id) async {
    try {
      await _datasource.deleteMessage(id);
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure('Failed to delete message: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearAll() async {
    try {
      await _datasource.clearAll();
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure('Failed to clear history: $e'));
    }
  }
}
