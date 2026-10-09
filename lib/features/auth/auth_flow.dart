import 'package:flutter/material.dart';

import 'intro_screens.dart';
import 'login_screen.dart';

enum _Stage { intro, choose, form }

/// Everything a signed-out user sees: two intro slides, then the sign-in /
/// register sheet. Lives inside one route so it disappears as a unit when
/// the session starts.
class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key});

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  _Stage _stage = _Stage.intro;
  AuthMode _mode = AuthMode.signIn;

  void _go(_Stage stage, {AuthMode? mode}) {
    setState(() {
      _stage = stage;
      if (mode != null) _mode = mode;
    });
  }

  void _back() {
    switch (_stage) {
      case _Stage.form:
        _go(_Stage.choose);
      case _Stage.choose:
        _go(_Stage.intro);
      case _Stage.intro:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _stage == _Stage.intro,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 360),
        switchInCurve: Curves.easeOutCubic,
        child: switch (_stage) {
          _Stage.intro => IntroSlideScreen(
              key: const ValueKey('intro'),
              onContinue: () => _go(_Stage.choose),
              onSkip: () => _go(_Stage.choose),
            ),
          _Stage.choose => IntroChooseScreen(
              key: const ValueKey('choose'),
              onSignIn: () => _go(_Stage.form, mode: AuthMode.signIn),
              onRegister: () => _go(_Stage.form, mode: AuthMode.register),
              onBack: _back,
            ),
          _Stage.form => LoginScreen(
              key: ValueKey('form-${_mode.name}'),
              initialMode: _mode,
              onBack: _back,
            ),
        },
      ),
    );
  }
}
