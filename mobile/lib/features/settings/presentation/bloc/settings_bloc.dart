import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/security/keystore_service.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final KeystoreService _keystoreService;

  SettingsBloc(this._keystoreService) : super(const SettingsState()) {
    on<SettingsLoadEvent>(_onLoad);
    on<SettingsToggleThemeEvent>(_onToggleTheme);
  }

  Future<void> _onLoad(SettingsLoadEvent event, Emitter<SettingsState> emit) async {
    try {
      final bio = await _keystoreService.secureRead('setting_biometric_required');
      final autoDel = await _keystoreService.secureRead('setting_auto_delete');
      final themeStr = await _keystoreService.secureRead('setting_theme_mode');

      ThemeMode mode = ThemeMode.system;
      if (themeStr == 'dark') mode = ThemeMode.dark;
      if (themeStr == 'light') mode = ThemeMode.light;

      emit(state.copyWith(
        themeMode: mode,
        biometricRequired: bio == null ? true : bio == 'true',
        autoDelete: autoDel ?? 'never',
      ));
    } catch (_) {}
  }

  Future<void> _onToggleTheme(
    SettingsToggleThemeEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(themeMode: event.themeMode));
    await _keystoreService.secureWrite(
      'setting_theme_mode',
      event.themeMode.name,
    );
  }
}
