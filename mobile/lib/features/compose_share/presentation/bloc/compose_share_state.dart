part of 'compose_share_bloc.dart';

abstract class ComposeShareState extends Equatable {
  const ComposeShareState();
  @override
  List<Object> get props => [];
}

class ComposeShareInitial extends ComposeShareState {}

class ComposeShareArming extends ComposeShareState {}

class ComposeShareArmed extends ComposeShareState {
  final int secondsRemaining;
  const ComposeShareArmed({required this.secondsRemaining});
  @override
  List<Object> get props => [secondsRemaining];
}

class ComposeShareSent extends ComposeShareState {}

class ComposeShareTimedOut extends ComposeShareState {}

class ComposeShareError extends ComposeShareState {
  final String message;
  const ComposeShareError(this.message);
  @override
  List<Object> get props => [message];
}
