import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/received_message.dart';
import '../repositories/receive_repository.dart';

class ValidateNfcPayloadParams {
  final Map<String, dynamic> rawPayload;
  const ValidateNfcPayloadParams(this.rawPayload);
}

class ValidateNfcPayloadUsecase
    implements UseCase<ReceivedMessage, ValidateNfcPayloadParams> {
  final ReceiveRepository _repository;
  ValidateNfcPayloadUsecase(this._repository);

  @override
  Future<Either<Failure, ReceivedMessage>> call(ValidateNfcPayloadParams params) {
    return _repository.validateAndParse(params.rawPayload);
  }
}
