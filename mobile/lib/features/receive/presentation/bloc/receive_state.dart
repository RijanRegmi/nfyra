part of 'receive_bloc.dart';

abstract class ReceiveState extends Equatable {
  const ReceiveState();
  @override
  List<Object?> get props => [];
}

class ReceiveInitial extends ReceiveState {
  const ReceiveInitial();
}

class ReceiveLoading extends ReceiveState {
  const ReceiveLoading();
}

class ReceiveSuccess extends ReceiveState {
  final ReceivedMessage message;
  const ReceiveSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ReceiveFailure extends ReceiveState {
  final String errorMessage;
  const ReceiveFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
