import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/feedback/app_feedback.dart';
import 'data/firebase/firestore_service.dart';
import 'firebase_options.dart';
import 'services/preferences_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 3));
  } catch (e) {
    debugPrint('Firebase initialization timeout or error: $e');
  }
  // Demo builds only (--dart-define=DEMO_MODE=true): seed sample data.
  unawaited(FirestoreService.instance.seedIfEmpty());
  // Theme, sounds and haptics are read before the first frame.
  LocalSettings settings;
  try {
    settings = await PreferencesStore.load().timeout(
      const Duration(seconds: 2),
      onTimeout: () => const LocalSettings(),
    );
  } catch (_) {
    settings = const LocalSettings();
  }
  // Material 3 edge-to-edge: the scaffold and NavigationBar draw behind
  // the system bars; the app bar theme drives icon brightness per screen.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  // Preload UI sounds so the first tap is not late.
  unawaited(AppFeedback.init());
  debugPrint('>>> Calling runApp(LibraryApp)...');
  runApp(LibraryApp(initialSettings: settings));
}
