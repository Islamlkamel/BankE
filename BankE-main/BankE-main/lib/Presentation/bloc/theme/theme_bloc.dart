import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class ThemeEvent {}
class LoadThemeEvent extends ThemeEvent {}
class ChangeThemeEvent extends ThemeEvent {
  final ThemeMode themeMode;
  ChangeThemeEvent(this.themeMode);
}

// State
class ThemeState {
  final ThemeMode themeMode;
  const ThemeState(this.themeMode);
}

// Bloc
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const String _themeKey = 'theme_preference';

  ThemeBloc() : super(const ThemeState(ThemeMode.system)) {
    on<LoadThemeEvent>((event, emit) async {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
      emit(ThemeState(ThemeMode.values[themeIndex]));
    });

    on<ChangeThemeEvent>((event, emit) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, event.themeMode.index);
      emit(ThemeState(event.themeMode));
    });
  }
}
