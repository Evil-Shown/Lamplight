import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../state/test_env.dart';

/// Haptic + sound feedback behind one semantic API.
///
/// Call the intent, not the mechanism: `AppFeedback.tap()` on a press,
/// `select()` when a choice changes, `toggle()` for switches, then
/// `success()` / `warning()` / `error()` for outcomes. Each fires the
/// matching haptic and a short soft sound together.
///
/// Silent no-op under `flutter test`, and it never throws: audio or haptic
/// failures are swallowed. [soundsEnabled] / [hapticsEnabled] are mirrored
/// from `AppState` (Settings switches).
class AppFeedback {
  AppFeedback._();

  static bool soundsEnabled = true;
  static bool hapticsEnabled = true;

  /// Quiet by design — these are garnish, not alerts.
  static const double _volume = 0.35;

  static const _files = <_Cue, String>{
    _Cue.tap: 'sounds/tap.wav',
    _Cue.select: 'sounds/select.wav',
    _Cue.toggle: 'sounds/toggle.wav',
    _Cue.success: 'sounds/success.wav',
    _Cue.error: 'sounds/error.wav',
  };

  static final Map<_Cue, AudioPlayer> _players = {};
  static bool _initStarted = false;

  static bool get _active => !isRunningInTest;

  /// Preloads every sound. Safe to call repeatedly; call at startup.
  static Future<void> init() async {
    if (!_active || _initStarted) return;
    _initStarted = true;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
        ).build(),
      );
    } catch (e) {
      debugPrint('AppFeedback audio context: $e');
    }
    for (final entry in _files.entries) {
      try {
        final player = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(entry.value));
        _players[entry.key] = player;
      } catch (e) {
        debugPrint('AppFeedback preload ${entry.value}: $e');
      }
    }
  }

  /// Light press on a button or card.
  static void tap() => _fire(_Cue.tap, () => _impact('light'));

  /// A choice changed: chips, tabs, segments, dock items.
  static void select() => _fire(_Cue.select, _selection);

  /// A switch or checkbox flipped.
  static void toggle() => _fire(_Cue.toggle, _selection);

  /// A flow completed (booking confirmed, check-in done).
  static void success() =>
      _fire(_Cue.success, () => _notification('success'));

  /// Something needs attention but nothing failed.
  static void warning() =>
      _fire(_Cue.error, () => _notification('warning'));

  /// An action failed or was refused.
  static void error() => _fire(_Cue.error, () => _notification('error'));

  // --- Haptic backends --------------------------------------------------
  // On iPhone these hit the Taptic Engine through the `lamplight/haptics`
  // channel (UINotification/UIImpact/UISelectionFeedbackGenerator). Anywhere
  // else, or if the channel is missing, fall back to Flutter's HapticFeedback.

  static const _haptics = MethodChannel('lamplight/haptics');

  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static Future<void> _impact(String style) async {
    if (_isIOS) {
      try {
        await _haptics.invokeMethod<void>('impact', style);
        return;
      } on MissingPluginException {
        // fall through
      }
    }
    await HapticFeedback.lightImpact();
  }

  static Future<void> _selection() async {
    if (_isIOS) {
      try {
        await _haptics.invokeMethod<void>('selection');
        return;
      } on MissingPluginException {
        // fall through
      }
    }
    await HapticFeedback.selectionClick();
  }

  static Future<void> _notification(String type) async {
    if (_isIOS) {
      try {
        await _haptics.invokeMethod<void>('notification', type);
        return;
      } on MissingPluginException {
        // fall through
      }
    }
    switch (type) {
      case 'success':
        await HapticFeedback.mediumImpact();
      case 'warning':
        await HapticFeedback.heavyImpact();
      default:
        await HapticFeedback.vibrate();
    }
  }

  static void _fire(_Cue cue, Future<void> Function() haptic) {
    if (!_active) return;
    if (hapticsEnabled) {
      try {
        unawaited(haptic().catchError((_) {}));
      } catch (_) {}
    }
    if (soundsEnabled) _play(cue);
  }

  static void _play(_Cue cue) {
    try {
      if (!_initStarted) unawaited(init());
      final player = _players[cue];
      if (player == null) return;
      unawaited(
        player
            .play(AssetSource(_files[cue]!), volume: _volume)
            .catchError((_) {}),
      );
    } catch (_) {}
  }
}

enum _Cue { tap, select, toggle, success, error }
