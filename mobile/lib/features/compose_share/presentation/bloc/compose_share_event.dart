part of 'compose_share_bloc.dart';

abstract class ComposeShareEvent extends Equatable {
  const ComposeShareEvent();
  @override
  List<Object> get props => [];
}

class ComposeShareStartEvent extends ComposeShareEvent {
  final String content;
  final String type;
  const ComposeShareStartEvent({required this.content, required this.type});
  @override
  List<Object> get props => [content, type];
}

class ComposeShareCancelEvent extends ComposeShareEvent {
  const ComposeShareCancelEvent();
}

class ComposeShareTickEvent extends ComposeShareEvent {
  const ComposeShareTickEvent();
}

class ComposeShareSuccessEvent extends ComposeShareEvent {
  const ComposeShareSuccessEvent();
}
