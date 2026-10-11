import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/core/state/app_state.dart';
import 'package:library_app/core/theme/app_theme.dart';
import 'package:library_app/features/auth/auth_flow.dart';

void main() {
  Future<void> pumpFlow(WidgetTester tester, {double textScale = 1}) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppScope(
      state: AppState(),
      child: MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const AuthFlow(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('intro -> choose -> sign in, then back', (tester) async {
    await pumpFlow(tester);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Login with Email Address'), findsOneWidget);

    await tester.tap(find.text('Login with Email Address'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Login with Email Address'), findsOneWidget);
  });

  testWidgets('skip and "Create a New Account" open the register form',
      (tester) async {
    await pumpFlow(tester);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a New Account'));
    await tester.pumpAndSettle();
    expect(find.text('Join Lamplight'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('every stage survives 1.5x text on a small phone',
      (tester) async {
    await pumpFlow(tester, textScale: 1.5);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Create a New Account'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
