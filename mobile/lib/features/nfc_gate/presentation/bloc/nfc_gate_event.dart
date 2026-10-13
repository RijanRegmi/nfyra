part of 'nfc_gate_bloc.dart';

abstract class NfcGateEvent extends Equatable {
  const NfcGateEvent();
  @override
  List<Object> get props => [];
}

class NfcGateCheckEvent extends NfcGateEvent {
  const NfcGateCheckEvent();
}

class NfcGateOpenSettingsEvent extends NfcGateEvent {
  const NfcGateOpenSettingsEvent();
}
