import 'package:flutter/material.dart';
import 'package:absendulu/core/services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isRomanClock = false;

  bool get isDarkMode => _isDarkMode;
  bool get isRomanClock => _isRomanClock;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() {
    _isDarkMode = StorageService.getIsDarkMode();
    _isRomanClock = StorageService.getUseRomanClock();
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    await StorageService.setIsDarkMode(value);
    notifyListeners();
  }

  Future<void> toggleRomanClock(bool value) async {
    _isRomanClock = value;
    await StorageService.setUseRomanClock(value);
    notifyListeners();
  }
}
