import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class NfcUnavailableFailure extends Failure {
  const NfcUnavailableFailure(super.message);
}

class NfcDisabledFailure extends Failure {
  const NfcDisabledFailure(super.message);
}

class HceUnsupportedFailure extends Failure {
  const HceUnsupportedFailure(super.message);
}

class PayloadValidationFailure extends Failure {
  const PayloadValidationFailure(super.message);
}

class PayloadExpiredFailure extends Failure {
  const PayloadExpiredFailure(super.message);
}

class PayloadReplayFailure extends Failure {
  const PayloadReplayFailure(super.message);
}

class PayloadSignatureFailure extends Failure {
  const PayloadSignatureFailure(super.message);
}

class CryptoFailure extends Failure {
  const CryptoFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class BiometricFailure extends Failure {
  const BiometricFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
