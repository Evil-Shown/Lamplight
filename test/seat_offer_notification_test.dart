// Small, deterministic widget tests for offers, notifications and the
// accessible seat list.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:library_app/core/state/app_state.dart';
import 'package:library_app/core/theme/app_theme.dart';
import 'package:library_app/features/home/home_screen.dart';
import 'package:library_app/features/qr/active_session_screen.dart';
import 'package:library_app/features/qr/qr_ticket_screen.dart';
import 'package:library_app/features/reservations/reservations_screen.dart';
import 'package:library_app/data/mock/mock_data.dart';
import 'package:library_app/features/notifications/notifications_screen.dart';
import 'package:library_app/features/reservations/live_widgets.dart';
import 'package:library_app/features/seats/seat_map_screen.dart';
import 'package:library_app/models/models.dart';

/// Test states report hydrated so screens show data, not skeletons.
class _HydratedState extends AppState {
  @override
  bool get isHydrated => true;
}

class _RecordingState extends _HydratedState {
  final responses = <(String, bool)>[];

  @override
  Future<void> respondToOffer(String entryId, bool accept) async {
    responses.add((entryId, accept));
  }
}

Future<void> _pump(WidgetTester tester, AppState state, Widget screen) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(AppScope(
    state: state,
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: SingleChildScrollView(child: screen)),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 200));
}

class _OfferState extends _HydratedState {
  @override
  List<WaitlistEntry> get pendingOffers => [
        WaitlistEntry(
          id: 'w1',
          type: WaitlistType.book,
          title: 'Clean Code',
          subtitle: 'Robert C. Martin',
          position: 1,
          joinedAt: DateTime.now(),
          status: WaitlistStatus.offered,
          offerExpiresAt: DateTime.now().add(const Duration(minutes: 3)),
        ),
      ];
}

void main() {
  testWidgets('offer card shows the countdown and answers the offer',
      (tester) async {
    final state = _RecordingState();
    final entry = WaitlistEntry(
      id: 'w1',
      type: WaitlistType.seat,
      title: 'Seat 2C',
      subtitle: 'Floor 2',
      position: 1,
      joinedAt: DateTime.now(),
      status: WaitlistStatus.offered,
      offerExpiresAt:
          DateTime.now().add(const Duration(minutes: 10, seconds: 30)),
    );
    await _pump(tester, state, OfferCard(entry: entry));

    expect(find.text('A seat is available for you'), findsOneWidget);
    expect(find.textContaining('Respond within 10 min'), findsOneWidget);

    await tester.tap(find.text('Accept'));
    await tester.pump();
    await tester.tap(find.text('Decline'));
    await tester.pump();
    expect(state.responses, [('w1', true), ('w1', false)]);
  });

  testWidgets('tapping a notification marks it read', (tester) async {
    final state = _HydratedState();
    final before = state.unreadCount;
    expect(before, greaterThan(0));
    final first = state.notifications.firstWhere((n) => !n.isRead);

    await tester.pumpWidget(AppScope(
      state: state,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const NotificationsScreen(),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text(first.title));
    await tester.pump();
    expect(state.unreadCount, before - 1);
  });

  testWidgets('seat list view lists seats grouped by zone', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppScope(
      state: _HydratedState(),
      child: MaterialApp(theme: AppTheme.light(), home: const SeatMapScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('List'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Select'), findsWidgets);
    expect(find.textContaining(' SEATS'), findsWidgets);
  });

  testWidgets('hydrated screens survive 1.5x text with an offer showing',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final booking = MockData.buildBookings().first;
    final screens = <Widget>[
      const HomeScreen(),
      const ReservationsScreen(),
      const NotificationsScreen(),
      QrTicketScreen(booking: booking),
      ActiveSessionScreen(booking: booking),
    ];
    for (final screen in screens) {
      await tester.pumpWidget(AppScope(
        state: _OfferState(),
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: screen,
        ),
      ));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
      expect(tester.takeException(), isNull, reason: '${screen.runtimeType}');
    }
  });
}
