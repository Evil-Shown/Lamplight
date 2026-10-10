import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:library_app/core/state/app_state.dart';
import 'package:library_app/core/theme/app_theme.dart';
import 'package:library_app/features/focus/focus_sanctuary_screen.dart';
import 'package:library_app/features/journal/reading_journal_screen.dart';
import 'package:library_app/features/sanctuary/night_sanctuary_screen.dart';

void main() {
  testWidgets('Sanctuary screens render and survive 1.5x text scaling',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final state = AppState();
    final screens = <Widget>[
      const FocusSanctuaryScreen(),
      const ReadingJournalScreen(),
      const NightSanctuaryScreen(),
    ];

    for (final screen in screens) {
      await tester.pumpWidget(AppScope(
        state: state,
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (c, child) => MediaQuery(
            data: MediaQuery.of(c)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: screen,
        ),
      ));

      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }

      expect(tester.takeException(), isNull,
          reason: 'Screen ${screen.runtimeType} should render without exceptions');
    }
  });

  testWidgets('Focus Sanctuary timer controls toggle smoothly', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(AppScope(
      state: AppState(),
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const FocusSanctuaryScreen(),
      ),
    ));

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('ZEN FOCUS'), findsOneWidget);

    // Tap play/pause button
    final playBtn = find.byIcon(Icons.play_arrow_rounded);
    expect(playBtn, findsOneWidget);
    await tester.tap(playBtn);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
  });
}

