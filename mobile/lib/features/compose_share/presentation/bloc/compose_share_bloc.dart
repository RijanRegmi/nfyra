import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/constants/nfc_constants.dart';
import '../../domain/usecases/arm_hce_usecase.dart';
import '../../domain/usecases/disarm_hce_usecase.dart';

part 'compose_share_event.dart';
part 'compose_share_state.dart';

class ComposeShareBloc extends Bloc<ComposeShareEvent, ComposeShareState> {
  final ArmHceUsecase _armHce;
  final DisarmHceUsecase _disarmHce;
  Timer? _countdownTimer;

  ComposeShareBloc(this._armHce, this._disarmHce) : super(ComposeShareInitial()) {
    on<ComposeShareStartEvent>(_onStart);
    on<ComposeShareCancelEvent>(_onCancel);
    on<ComposeShareTickEvent>(_onTick);
    on<ComposeShareSuccessEvent>(_onSuccess);
  }

  Future<void> _onStart(ComposeShareStartEvent event, Emitter<ComposeShareState> emit) async {
    emit(ComposeShareArming());

    final result = await _armHce(ArmHceParams(content: event.content, type: event.type));

    result.fold(
      (failure) => emit(ComposeShareError(failure.message)),
      (_) {
        _startCountdown();
        emit(const ComposeShareArmed(secondsRemaining: kShareWindowSeconds));
      },
    );
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const ComposeShareTickEvent());
    });
  }

  Future<void> _onTick(ComposeShareTickEvent event, Emitter<ComposeShareState> emit) async {
    final current = state;
    if (current is! ComposeShareArmed) return;

    final remaining = current.secondsRemaining - 1;
    if (remaining <= 0) {
      _countdownTimer?.cancel();
      await _disarmHce(const NoParams());
      emit(ComposeShareTimedOut());
    } else {
      emit(ComposeShareArmed(secondsRemaining: remaining));
    }
  }

  Future<void> _onCancel(ComposeShareCancelEvent event, Emitter<ComposeShareState> emit) async {
    _countdownTimer?.cancel();
    await _disarmHce(const NoParams());
    emit(ComposeShareInitial());
  }

  Future<void> _onSuccess(ComposeShareSuccessEvent event, Emitter<ComposeShareState> emit) async {
    _countdownTimer?.cancel();
    await _disarmHce(const NoParams());
    emit(ComposeShareSent());
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    return super.close();
  }
}
