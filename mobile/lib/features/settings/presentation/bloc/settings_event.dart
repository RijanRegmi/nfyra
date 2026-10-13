part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class SettingsLoadEvent extends SettingsEvent {
  const SettingsLoadEvent();
}

class SettingsToggleThemeEvent extends SettingsEvent {
  final ThemeMode themeMode;
  const SettingsToggleThemeEvent(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}
