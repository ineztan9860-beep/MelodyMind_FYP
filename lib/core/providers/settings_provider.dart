import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool isSoundEnabled;
  final bool isDarkMode;

  SettingsState({
    required this.isSoundEnabled,
    required this.isDarkMode,
  });

  SettingsState copyWith({
    bool? isSoundEnabled,
    bool? isDarkMode,
  }) {
    return SettingsState(
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs)
      : super(SettingsState(
          isSoundEnabled: _prefs.getBool('is_sound_enabled') ?? true,
          isDarkMode: _prefs.getBool('is_dark_mode') ?? false,
        ));

  void toggleSound(bool value) {
    _prefs.setBool('is_sound_enabled', value);
    state = state.copyWith(isSoundEnabled: value);
  }

  void toggleDarkMode(bool value) {
    _prefs.setBool('is_dark_mode', value);
    state = state.copyWith(isDarkMode: value);
  }
}

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(); // Should be overridden in main
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return SettingsNotifier(prefs);
});
