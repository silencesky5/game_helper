import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported UI languages for the desktop console.
enum AppLanguage {
  /// Traditional Chinese (Taiwan).
  zhTw(Locale('zh', 'TW'), 'zh_TW'),

  /// English.
  en(Locale('en'), 'en');

  const AppLanguage(this.locale, this.preferenceValue);

  /// Flutter locale used by MaterialApp.
  final Locale locale;

  /// Persisted preference value.
  final String preferenceValue;

  /// Returns the supported language for [locale], if available.
  static AppLanguage? fromLocale(Locale locale) {
    for (final language in values) {
      if (language.locale.languageCode == locale.languageCode &&
          (language.locale.countryCode == null || language.locale.countryCode == locale.countryCode)) {
        return language;
      }
    }
    return null;
  }

  /// Returns the persisted language value, if supported.
  static AppLanguage? fromPreference(String? value) {
    for (final language in values) {
      if (language.preferenceValue == value) return language;
    }
    return null;
  }
}

/// Loads, stores, and updates the current application language.
class LanguageManager extends ChangeNotifier {
  /// Creates a language manager with an optional preferences dependency.
  LanguageManager({SharedPreferences? preferences}) : _preferences = preferences;

  static const String _preferenceKey = 'game_helper.language';

  SharedPreferences? _preferences;
  AppLanguage _currentLanguage = AppLanguage.zhTw;

  /// The active language.
  AppLanguage get currentLanguage => _currentLanguage;

  /// The active locale.
  Locale get locale => _currentLanguage.locale;

  /// Loads the persisted language, or chooses a supported platform locale.
  Future<void> loadPreference() async {
    _preferences ??= await SharedPreferences.getInstance();
    final savedLanguage = AppLanguage.fromPreference(_preferences?.getString(_preferenceKey));
    _currentLanguage = savedLanguage ?? _defaultLanguage(PlatformDispatcher.instance.locale);
    notifyListeners();
  }

  /// Changes and persists the active language.
  Future<void> changeLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    notifyListeners();
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences?.setString(_preferenceKey, language.preferenceValue);
  }

  AppLanguage _defaultLanguage(Locale platformLocale) {
    if (platformLocale.languageCode == 'zh' && platformLocale.countryCode == 'TW') {
      return AppLanguage.zhTw;
    }
    return AppLanguage.fromLocale(platformLocale) ?? AppLanguage.en;
  }
}
