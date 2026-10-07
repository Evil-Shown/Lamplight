import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'core/constants/app_constants.dart';
import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_frame.dart';
import 'core/widgets/ledger_widgets.dart';
import 'features/auth/login_screen.dart';

class LibraryApp extends StatefulWidget {
  const LibraryApp({super.key});

  @override
  State<LibraryApp> createState() => _LibraryAppState();
}

class _LibraryAppState extends State<LibraryApp> {
  final AppState _state = AppState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: AnimatedBuilder(
        animation: _state,
        builder: (context, _) {
          // Keep the global palette in sync before any screen builds so
          // both the ThemeData and the hardcoded colour getters agree.
          AppColors.isDark = _state.themeMode == ThemeMode.dark;
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: _state.themeMode,
            builder: (context, child) =>
                AppFrame(child: child ?? const SizedBox.shrink()),
            home: const _AppEntry(),
          );
        },
      ),
    );
  }
}

/// Splash once, then the login screen or the shell depending on whether
/// anyone is signed in.
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
      child: !_opened
          ? SplashScreen(
              key: const ValueKey('splash'),
              onDone: () {
                if (mounted) setState(() => _opened = true);
              },
            )
          : const _SignedInGate(),
    );
  }
}

class _SignedInGate extends StatelessWidget {
  const _SignedInGate();

  @override
  Widget build(BuildContext context) {
    final signedIn = AppScope.of(context).isSignedIn;
    return signedIn
        ? const AppShell(key: ValueKey('shell'))
        : const LoginScreen(key: ValueKey('login'));
  }
}
