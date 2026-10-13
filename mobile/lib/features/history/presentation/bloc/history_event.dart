part of 'history_bloc.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();
  @override
  List<Object?> get props => [];
}

class HistoryLoadEvent extends HistoryEvent {
  const HistoryLoadEvent();
}

class HistoryDeleteEvent extends HistoryEvent {
  final String id;
  const HistoryDeleteEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class HistoryClearEvent extends HistoryEvent {
  const HistoryClearEvent();
}
