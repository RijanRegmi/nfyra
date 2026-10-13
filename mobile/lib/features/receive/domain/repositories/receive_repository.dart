import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/received_message.dart';

abstract class ReceiveRepository {
  Future<Either<Failure, ReceivedMessage>> validateAndParse(Map<String, dynamic> rawPayload);
}
