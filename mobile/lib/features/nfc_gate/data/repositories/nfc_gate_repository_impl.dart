import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/nfc_status_entity.dart';
import '../../domain/repositories/nfc_gate_repository.dart';
import '../datasources/nfc_status_datasource.dart';

class NfcGateRepositoryImpl implements NfcGateRepository {
  final NfcStatusDatasource _datasource;
  NfcGateRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, NfcStatusEntity>> checkNfcStatus() async {
    try {
      final status = await _datasource.checkStatus();
      return Right(NfcStatusEntity(
        hasHardware: status.hasHardware,
        isEnabled: status.isEnabled,
        hasHce: status.hasHce,
      ));
    } catch (e) {
      return const Left(NfcUnavailableFailure('Failed to check NFC status'));
    }
  }

  @override
  Future<Either<Failure, void>> openNfcSettings() async {
    try {
      await _datasource.openNfcSettings();
      return const Right(null);
    } catch (e) {
      return const Left(UnknownFailure('Failed to open NFC settings'));
    }
  }
}
