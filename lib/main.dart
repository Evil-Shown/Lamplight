import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/feedback/app_feedback.dart';
import 'data/firebase/firestore_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Populate the catalogue and seat map the first time the app runs.
  unawaited(FirestoreService.instance.seedIfEmpty());
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
  runApp(const LibraryApp());
}
