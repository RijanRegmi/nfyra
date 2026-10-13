part of 'nfc_gate_bloc.dart';

abstract class NfcGateState extends Equatable {
  const NfcGateState();
  @override
  List<Object?> get props => [];
}

class NfcGateInitial extends NfcGateState {}

class NfcGateLoading extends NfcGateState {}

class NfcGateSupported extends NfcGateState {
  final NfcStatusEntity status;
  const NfcGateSupported(this.status);
  @override
  List<Object> get props => [status];
}

class NfcGateUnsupported extends NfcGateState {
  final NfcStatusEntity status;
  const NfcGateUnsupported(this.status);
  @override
  List<Object> get props => [status];
}

class NfcGateError extends NfcGateState {
  final String message;
  const NfcGateError(this.message);
  @override
  List<Object> get props => [message];
}
