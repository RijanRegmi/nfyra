part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final bool biometricRequired;
  final String autoDelete;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.biometricRequired = true,
    this.autoDelete = 'never',
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? biometricRequired,
    String? autoDelete,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      biometricRequired: biometricRequired ?? this.biometricRequired,
      autoDelete: autoDelete ?? this.autoDelete,
    );
  }

  @override
  List<Object?> get props => [themeMode, biometricRequired, autoDelete];
}
