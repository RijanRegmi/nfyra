part of 'receive_bloc.dart';

abstract class ReceiveEvent extends Equatable {
  const ReceiveEvent();
  @override
  List<Object?> get props => [];
}

class ReceiveProcessPayloadEvent extends ReceiveEvent {
  final Map<String, dynamic> rawPayload;
  const ReceiveProcessPayloadEvent(this.rawPayload);

  @override
  List<Object?> get props => [rawPayload];
}

class ReceiveResetEvent extends ReceiveEvent {
  const ReceiveResetEvent();
}
