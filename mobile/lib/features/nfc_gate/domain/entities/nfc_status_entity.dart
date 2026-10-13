import 'package:equatable/equatable.dart';

class NfcStatusEntity extends Equatable {
  final bool hasHardware;
  final bool isEnabled;
  final bool hasHce;

  const NfcStatusEntity({
    required this.hasHardware,
    required this.isEnabled,
    required this.hasHce,
  });

  bool get isFullySupported => hasHardware && isEnabled && hasHce;

  @override
  List<Object> get props => [hasHardware, isEnabled, hasHce];
}
