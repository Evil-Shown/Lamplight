import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/state/test_env.dart';

/// Device-local UI choices that must survive restarts: theme, sounds,
/// haptics. A safe no-op under `flutter test` and whenever storage fails.
class LocalSettings {
  const LocalSettings({
    this.themeMode = ThemeMode.system,
    this.sounds = true,
    this.haptics = true,
  });

  final ThemeMode themeMode;
  final bool sounds;
  final bool haptics;
}

class PreferencesStore {
  PreferencesStore._();

  static const _kTheme = 'themeMode';
  static const _kSounds = 'soundsEnabled';
  static const _kHaptics = 'hapticsEnabled';

  static Future<LocalSettings> load() async {
    if (isRunningInTest) return const LocalSettings();
    try {
      final p = await SharedPreferences.getInstance();
      final mode = ThemeMode.values.firstWhere(
        (m) => m.name == p.getString(_kTheme),
        orElse: () => ThemeMode.system,
      );
      return LocalSettings(
        themeMode: mode,
        sounds: p.getBool(_kSounds) ?? true,
        haptics: p.getBool(_kHaptics) ?? true,
      );
    } catch (_) {
      return const LocalSettings();
    }
  }

  static Future<String> loadPhone(String uid) async {
    if (isRunningInTest) return '';
    try {
      return (await SharedPreferences.getInstance()).getString('phone.$uid') ??
          '';
    } catch (_) {
      return '';
    }
  }

  static Future<void> savePhone(String uid, String phone) =>
      _write((p) => p.setString('phone.$uid', phone));

  static Future<void> saveTheme(ThemeMode mode) =>
      _write((p) => p.setString(_kTheme, mode.name));
  static Future<void> saveSounds(bool v) =>
      _write((p) => p.setBool(_kSounds, v));
  static Future<void> saveHaptics(bool v) =>
      _write((p) => p.setBool(_kHaptics, v));

  static Future<void> _write(
      Future<bool> Function(SharedPreferences p) fn) async {
    if (isRunningInTest) return;
    try {
      await fn(await SharedPreferences.getInstance());
    } catch (_) {}
  }
}
