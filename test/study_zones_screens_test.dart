import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:library_app/core/state/app_state.dart';
import 'package:library_app/core/theme/app_theme.dart';
import 'package:library_app/features/seats/seat_scout_screen.dart';
import 'package:library_app/features/zones/group_room_booking_screen.dart';
import 'package:library_app/features/zones/library_guide_screen.dart';
import 'package:library_app/features/zones/pod_booking_screen.dart';
import 'package:library_app/features/zones/study_zones_screen.dart';

void main() {
  testWidgets('Study Zones & Campus Scout screens render and survive 1.5x text scaling',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final state = AppState();
    final screens = <Widget>[
      const StudyZonesScreen(),
      const PodBookingScreen(),
      const SeatScoutScreen(),
      const GroupRoomBookingScreen(),
      const LibraryGuideScreen(),
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

  testWidgets('PodBookingScreen selects pod and confirms reservation',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(AppScope(
      state: AppState(),
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const PodBookingScreen(),
      ),
    ));

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Private Glass Pods'), findsOneWidget);

    // Tap Pod 02
    final pod02 = find.text('02');
    expect(pod02, findsWidgets);
    await tester.tap(pod02.first);
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Book Pod Button
    final bookButton = find.text('Reserve Pod 02');
    expect(bookButton, findsOneWidget);
    await tester.tap(bookButton);
    await tester.pumpAndSettle();

    expect(find.text('Pod 02 Reserved!'), findsOneWidget);
    expect(find.text('SMART DIGITAL PASSCODE'), findsOneWidget);
    expect(find.text('7 4 9 2'), findsOneWidget);
  });

  testWidgets('SeatScoutScreen renders campus scout and allows selection', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(AppScope(
      state: AppState(),
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const SeatScoutScreen(),
      ),
    ));

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Library Floor Scout'), findsOneWidget);
    expect(find.text('Live Occupancy & Focus Deals'), findsOneWidget);

    // Tap a seat card
    final card = find.text('Section 01 · Glass Pods');
    expect(card, findsOneWidget);
    await tester.tap(card);
    await tester.pumpAndSettle();
  });
}
