import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:equatable/equatable.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  final Box<dynamic> _settingsBox;
  static const _themeKey = 'app_theme';

  ThemeCubit(this._settingsBox)
    : super(ThemeState(themeMode: _getInitialThemeMode(_settingsBox)));

  static ThemeMode _getInitialThemeMode(Box<dynamic> box) {
    final savedTheme = box.get(_themeKey);
    if (savedTheme == null) {
      // Default to dark theme
      box.put(_themeKey, 'dark');
      return ThemeMode.dark;
    }
    return savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme() {
    final newThemeMode =
        state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _settingsBox.put(
      _themeKey,
      newThemeMode == ThemeMode.dark ? 'dark' : 'light',
    );
    emit(ThemeState(themeMode: newThemeMode));
  }

  void setTheme(ThemeMode themeMode) {
    _settingsBox.put(_themeKey, themeMode == ThemeMode.dark ? 'dark' : 'light');
    emit(ThemeState(themeMode: themeMode));
  }
}
