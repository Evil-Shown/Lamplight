import 'package:flutter/material.dart';
import 'app_shell.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/ledger_widgets.dart';

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _AppEntry(),
    );
  }
}

/// Shows the animated "Opening" once, then hands over to the shell.
class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _opened = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: _opened
          ? const AppShell(key: ValueKey('shell'))
          : SplashScreen(key: const ValueKey('splash'), onDone: () {
              if (mounted) setState(() => _opened = true);
            }),
    );
  }
}
