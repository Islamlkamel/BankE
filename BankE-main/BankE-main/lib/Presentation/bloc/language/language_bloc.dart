import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LanguageEvent {}

class ChangeLanguageEvent extends LanguageEvent {
  final String languageCode;
  ChangeLanguageEvent(this.languageCode);
}

class LoadLanguageEvent extends LanguageEvent {}

class LanguageState {
  final Locale locale;
  LanguageState(this.locale);
}

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  LanguageBloc() : super(LanguageState(const Locale('en'))) {
    on<LoadLanguageEvent>(_onLoadLanguage);
    on<ChangeLanguageEvent>(_onChangeLanguage);
  }

  Future<void> _onLoadLanguage(LoadLanguageEvent event, Emitter<LanguageState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final String languageCode = prefs.getString('LANGUAGE_CODE') ?? 'en';
    emit(LanguageState(Locale(languageCode)));
  }

  Future<void> _onChangeLanguage(ChangeLanguageEvent event, Emitter<LanguageState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('LANGUAGE_CODE', event.languageCode);
    emit(LanguageState(Locale(event.languageCode)));
  }
}
