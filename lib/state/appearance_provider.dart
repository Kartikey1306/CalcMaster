import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings → Appearance: System, Ledger (light) or Night ledger (dark).
class AppearanceProvider extends ChangeNotifier {
  static const _kMode = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  AppearanceProvider() {
    _hydrate();
  }

  Future<void> _hydrate() async {
    final sp = await SharedPreferences.getInstance();
    final saved = sp.getString(_kMode);
    final mode = ThemeMode.values.where((m) => m.name == saved).firstOrNull;
    if (mode != null && mode != _mode) {
      _mode = mode;
      notifyListeners();
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kMode, mode.name);
  }
}
