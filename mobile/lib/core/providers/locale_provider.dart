import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  final SharedPreferences prefs;
  static const String localeKey = 'locale';

  Locale _locale = const Locale('en', '');

  LocaleProvider(this.prefs) {
    _loadLocale();
  }

  Locale get locale => _locale;

  void _loadLocale() {
    final String? languageCode = prefs.getString(localeKey);
    if (languageCode != null) {
      _locale = Locale(languageCode, '');
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (!_isSupportedLocale(locale)) return;
    
    _locale = locale;
    await prefs.setString(localeKey, locale.languageCode);
    notifyListeners();
  }

  bool _isSupportedLocale(Locale locale) {
    return ['en', 'fr', 'ar'].contains(locale.languageCode);
  }
}
