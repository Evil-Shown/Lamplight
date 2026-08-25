import 'package:flutter/material.dart';
import 'app_shell.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AppShell(),
    );
  }
}
