import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/nfc_status_entity.dart';
import '../../domain/usecases/check_nfc_usecase.dart';
import '../../domain/usecases/open_nfc_settings_usecase.dart';

part 'nfc_gate_event.dart';
part 'nfc_gate_state.dart';

class NfcGateBloc extends Bloc<NfcGateEvent, NfcGateState> {
  final CheckNfcUsecase _checkNfc;
  final OpenNfcSettingsUsecase? _openNfcSettings;

  NfcGateBloc(this._checkNfc, [this._openNfcSettings]) : super(NfcGateInitial()) {
    on<NfcGateCheckEvent>(_onCheck);
    on<NfcGateOpenSettingsEvent>(_onOpenSettings);
  }

  Future<void> _onCheck(NfcGateCheckEvent event, Emitter<NfcGateState> emit) async {
    emit(NfcGateLoading());
    final result = await _checkNfc(const NoParams());
    result.fold(
      (failure) => emit(NfcGateError(failure.message)),
      (status) {
        if (status.isFullySupported) {
          emit(NfcGateSupported(status));
        } else {
          emit(NfcGateUnsupported(status));
        }
      },
    );
  }

  Future<void> _onOpenSettings(
    NfcGateOpenSettingsEvent event,
    Emitter<NfcGateState> emit,
  ) async {
    if (_openNfcSettings != null) {
      await _openNfcSettings(const NoParams());
    }
  }
}
