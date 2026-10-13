import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/received_message.dart';
import '../../domain/usecases/validate_nfc_payload_usecase.dart';

part 'receive_event.dart';
part 'receive_state.dart';

class ReceiveBloc extends Bloc<ReceiveEvent, ReceiveState> {
  final ValidateNfcPayloadUsecase _validateUsecase;

  ReceiveBloc(this._validateUsecase) : super(const ReceiveInitial()) {
    on<ReceiveProcessPayloadEvent>(_onProcessPayload);
    on<ReceiveResetEvent>(_onReset);
  }

  Future<void> _onProcessPayload(
    ReceiveProcessPayloadEvent event,
    Emitter<ReceiveState> emit,
  ) async {
    emit(const ReceiveLoading());
    final result = await _validateUsecase(
      ValidateNfcPayloadParams(event.rawPayload),
    );
    result.fold(
      (failure) => emit(ReceiveFailure(failure.message)),
      (message) => emit(ReceiveSuccess(message)),
    );
  }

  void _onReset(ReceiveResetEvent event, Emitter<ReceiveState> emit) {
    emit(const ReceiveInitial());
  }
}
