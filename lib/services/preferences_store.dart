import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/state/test_env.dart';

/// Device-local UI choices that must survive restarts: theme, sounds,
/// haptics. A safe no-op under `flutter test` and whenever storage fails.
class LocalSettings {
  const LocalSettings({
    this.themeMode = ThemeMode.light,
    this.sounds = true,
    this.haptics = true,
    this.themeHintSeen = true,
  });

  final ThemeMode themeMode;
  final bool sounds;
  final bool haptics;

  /// Whether the one-time "you can change the theme" hint was shown. Defaults
  /// to true so fallbacks and tests never show it.
  final bool themeHintSeen;
}

class PreferencesStore {
  PreferencesStore._();

  static const _kTheme = 'themeMode';
  static const _kSounds = 'soundsEnabled';
  static const _kHaptics = 'hapticsEnabled';
  static const _kThemeHintSeen = 'themeHintSeen';

  static Future<LocalSettings> load() async {
    if (isRunningInTest) return const LocalSettings();
    try {
      final p = await SharedPreferences.getInstance();
      final mode = ThemeMode.values.firstWhere(
        (m) => m.name == p.getString(_kTheme),
        orElse: () => ThemeMode.light,
      );
      return LocalSettings(
        themeMode: mode,
        sounds: p.getBool(_kSounds) ?? true,
        haptics: p.getBool(_kHaptics) ?? true,
        themeHintSeen: p.getBool(_kThemeHintSeen) ?? false,
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

  static Future<void> saveThemeHintSeen(bool v) =>
      _write((p) => p.setBool(_kThemeHintSeen, v));

  static Future<void> _write(
      Future<bool> Function(SharedPreferences p) fn) async {
    if (isRunningInTest) return;
    try {
      await fn(await SharedPreferences.getInstance());
    } catch (_) {}
  }
}
