import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  final SharedPreferences prefs;
  static const String themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  Timer? _themeUpdateTimer;

  ThemeProvider(this.prefs) {
    _loadTheme();
    _setupThemeUpdateTimer();
  }

  ThemeMode get themeMode {
    // If in system mode, return the appropriate theme based on time
    if (_themeMode == ThemeMode.system) {
      return _isDayTime() ? ThemeMode.light : ThemeMode.dark;
    }
    return _themeMode;
  }

  void _loadTheme() {
    final String? themeString = prefs.getString(themeKey);
    if (themeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
            (e) => e.toString() == themeString,
        orElse: () => ThemeMode.system,
      );
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await prefs.setString(themeKey, mode.toString());
    notifyListeners();
  }

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final isDayTime = _isDayTime();
      print('Current time: ${DateTime.now().hour}:${DateTime.now().minute}, isDayTime: $isDayTime');
      return !isDayTime;
    }
    return _themeMode == ThemeMode.dark;
  }

  void toggleTheme() {
    final newMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(newMode);
  }

  // Check if current time is between 5am and 6pm
  bool _isDayTime() {
    final now = DateTime.now();
    final hour = now.hour;

    // Day time is from 5am (5) to 6pm (18)
    return hour >= 5 && hour < 18;
  }

  // Setup a timer to update the theme at the transition times (5am and 6pm)
  void _setupThemeUpdateTimer() {
    // Cancel any existing timer
    _themeUpdateTimer?.cancel();

    // Calculate time until next theme change
    final now = DateTime.now();
    final currentHour = now.hour;

    DateTime nextUpdate;

    if (currentHour < 5) {
      // Before 5am, next update is at 5am
      nextUpdate = DateTime(now.year, now.month, now.day, 5, 0, 0);
    } else if (currentHour < 18) {
      // Between 5am and 6pm, next update is at 6pm
      nextUpdate = DateTime(now.year, now.month, now.day, 18, 0, 0);
    } else {
      // After 6pm, next update is at 5am tomorrow
      nextUpdate = DateTime(now.year, now.month, now.day, 5, 0, 0).add(const Duration(days: 1));
    }

    // Calculate duration until next update
    final duration = nextUpdate.difference(now);

    // Set timer to update theme at the next transition time
    _themeUpdateTimer = Timer(duration, () {
      if (_themeMode == ThemeMode.system) {
        // Only notify if in system mode
        notifyListeners();
      }
      // Setup the next timer
      _setupThemeUpdateTimer();
    });
  }

  // Force an immediate theme check and update
  void checkAndUpdateTheme() {
    if (_themeMode == ThemeMode.system) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _themeUpdateTimer?.cancel();
    super.dispose();
  }
}
