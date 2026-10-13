import 'package:get_it/get_it.dart';

import '../../features/compose_share/data/datasources/nfc_datasource.dart';
import '../../features/compose_share/data/repositories/nfc_repository_impl.dart';
import '../../features/compose_share/domain/repositories/nfc_repository.dart';
import '../../features/compose_share/domain/usecases/arm_hce_usecase.dart';
import '../../features/compose_share/domain/usecases/disarm_hce_usecase.dart';
import '../../features/compose_share/presentation/bloc/compose_share_bloc.dart';

import '../../features/nfc_gate/data/datasources/nfc_status_datasource.dart';
import '../../features/nfc_gate/data/repositories/nfc_gate_repository_impl.dart';
import '../../features/nfc_gate/domain/repositories/nfc_gate_repository.dart';
import '../../features/nfc_gate/domain/usecases/check_nfc_usecase.dart';
import '../../features/nfc_gate/domain/usecases/open_nfc_settings_usecase.dart';
import '../../features/nfc_gate/presentation/bloc/nfc_gate_bloc.dart';

import '../../features/receive/data/datasources/nfc_receive_datasource.dart';
import '../../features/receive/data/repositories/receive_repository_impl.dart';
import '../../features/receive/domain/repositories/receive_repository.dart';
import '../../features/receive/domain/usecases/validate_nfc_payload_usecase.dart';
import '../../features/receive/presentation/bloc/receive_bloc.dart';

import '../../features/history/data/datasources/history_local_datasource.dart';
import '../../features/history/data/repositories/history_repository_impl.dart';
import '../../features/history/domain/repositories/history_repository.dart';
import '../../features/history/domain/usecases/clear_history_usecase.dart';
import '../../features/history/domain/usecases/delete_history_message_usecase.dart';
import '../../features/history/domain/usecases/get_history_usecase.dart';
import '../../features/history/domain/usecases/save_history_message_usecase.dart';
import '../../features/history/presentation/bloc/history_bloc.dart';

import '../../features/settings/presentation/bloc/settings_bloc.dart';

import '../security/auto_share_service.dart';
import '../security/keystore_service.dart';
import '../security/nonce_cache.dart';

extension GetItInjectableX on GetIt {
  Future<void> init() async {
    // Security & Services
    registerLazySingleton<KeystoreService>(() => KeystoreService());
    registerLazySingleton<NonceCache>(() => NonceCache(this<KeystoreService>()));
    registerLazySingleton<AutoShareService>(() => AutoShareService());

    // NFC Gate
    registerLazySingleton<NfcStatusDatasource>(() => NfcStatusDatasourceImpl());
    registerLazySingleton<NfcGateRepository>(
      () => NfcGateRepositoryImpl(this<NfcStatusDatasource>()),
    );
    registerLazySingleton<CheckNfcUsecase>(
      () => CheckNfcUsecase(this<NfcGateRepository>()),
    );
    registerLazySingleton<OpenNfcSettingsUsecase>(
      () => OpenNfcSettingsUsecase(this<NfcGateRepository>()),
    );
    registerFactory<NfcGateBloc>(
      () => NfcGateBloc(this<CheckNfcUsecase>(), this<OpenNfcSettingsUsecase>()),
    );

    // Compose / Share
    registerLazySingleton<NfcDatasource>(
      () => NfcDatasourceImpl(),
    );
    registerLazySingleton<NfcRepository>(
      () => NfcRepositoryImpl(this<NfcDatasource>()),
    );
    registerLazySingleton<ArmHceUsecase>(
      () => ArmHceUsecase(this<NfcRepository>(), this<KeystoreService>()),
    );
    registerLazySingleton<DisarmHceUsecase>(
      () => DisarmHceUsecase(this<NfcRepository>()),
    );
    registerFactory<ComposeShareBloc>(
      () => ComposeShareBloc(this<ArmHceUsecase>(), this<DisarmHceUsecase>()),
    );

    // Receive
    registerLazySingleton<NfcReceiveDatasource>(
      () => NfcReceiveDatasourceImpl(),
    );
    registerLazySingleton<ReceiveRepository>(
      () => ReceiveRepositoryImpl(this<KeystoreService>(), this<NonceCache>()),
    );
    registerLazySingleton<ValidateNfcPayloadUsecase>(
      () => ValidateNfcPayloadUsecase(this<ReceiveRepository>()),
    );
    registerFactory<ReceiveBloc>(
      () => ReceiveBloc(this<ValidateNfcPayloadUsecase>()),
    );

    // History
    registerLazySingleton<HistoryLocalDatasource>(
      () => HistoryLocalDatasourceImpl(this<KeystoreService>()),
    );
    registerLazySingleton<HistoryRepository>(
      () => HistoryRepositoryImpl(this<HistoryLocalDatasource>()),
    );
    registerLazySingleton<GetHistoryUsecase>(
      () => GetHistoryUsecase(this<HistoryRepository>()),
    );
    registerLazySingleton<SaveHistoryMessageUsecase>(
      () => SaveHistoryMessageUsecase(this<HistoryRepository>()),
    );
    registerLazySingleton<DeleteHistoryMessageUsecase>(
      () => DeleteHistoryMessageUsecase(this<HistoryRepository>()),
    );
    registerLazySingleton<ClearHistoryUsecase>(
      () => ClearHistoryUsecase(this<HistoryRepository>()),
    );
    registerFactory<HistoryBloc>(
      () => HistoryBloc(
        this<GetHistoryUsecase>(),
        this<DeleteHistoryMessageUsecase>(),
        this<ClearHistoryUsecase>(),
      ),
    );

    // Settings
    registerFactory<SettingsBloc>(
      () => SettingsBloc(this<KeystoreService>()),
    );
  }
}
