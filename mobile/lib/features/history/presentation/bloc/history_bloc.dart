import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/history_message.dart';
import '../../domain/usecases/clear_history_usecase.dart';
import '../../domain/usecases/delete_history_message_usecase.dart';
import '../../domain/usecases/get_history_usecase.dart';

part 'history_event.dart';
part 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetHistoryUsecase _getHistoryUsecase;
  final DeleteHistoryMessageUsecase _deleteHistoryMessageUsecase;
  final ClearHistoryUsecase _clearHistoryUsecase;

  HistoryBloc(
    this._getHistoryUsecase,
    this._deleteHistoryMessageUsecase,
    this._clearHistoryUsecase,
  ) : super(const HistoryInitial()) {
    on<HistoryLoadEvent>(_onLoad);
    on<HistoryDeleteEvent>(_onDelete);
    on<HistoryClearEvent>(_onClear);
  }

  Future<void> _onLoad(
    HistoryLoadEvent event,
    Emitter<HistoryState> emit,
  ) async {
    emit(const HistoryLoading());
    final result = await _getHistoryUsecase(const NoParams());
    result.fold(
      (failure) => emit(HistoryError(failure.message)),
      (messages) => emit(HistoryLoaded(messages)),
    );
  }

  Future<void> _onDelete(
    HistoryDeleteEvent event,
    Emitter<HistoryState> emit,
  ) async {
    final result = await _deleteHistoryMessageUsecase(event.id);
    result.fold(
      (failure) => emit(HistoryError(failure.message)),
      (_) => add(const HistoryLoadEvent()),
    );
  }

  Future<void> _onClear(
    HistoryClearEvent event,
    Emitter<HistoryState> emit,
  ) async {
    final result = await _clearHistoryUsecase(const NoParams());
    result.fold(
      (failure) => emit(HistoryError(failure.message)),
      (_) => emit(const HistoryLoaded([])),
    );
  }
}
