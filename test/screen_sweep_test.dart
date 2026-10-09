// Renders every screen in the real app and fails on any layout overflow
// or render exception. Complements the on-device visual check, which is
// unreliable under software rendering.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:library_app/core/state/app_state.dart';
import 'package:library_app/core/theme/app_theme.dart';
import 'package:library_app/features/account/account_screen.dart';
import 'package:library_app/features/home/home_screen.dart';
import 'package:library_app/features/books/book_detail_screen.dart';
import 'package:library_app/features/books/book_search_screen.dart';
import 'package:library_app/features/books/reservation_cancelled_screen.dart';
import 'package:library_app/features/books/reservation_confirmation_screen.dart';
import 'package:library_app/features/books/reservation_detail_screen.dart';
import 'package:library_app/features/notifications/notifications_screen.dart';
import 'package:library_app/features/qr/active_session_screen.dart';
import 'package:library_app/features/qr/qr_ticket_screen.dart';
import 'package:library_app/features/reservations/reservations_screen.dart';
import 'package:library_app/features/seats/booking_confirmation_screen.dart';
import 'package:library_app/features/seats/seat_detail_screen.dart';
import 'package:library_app/features/seats/seat_map_screen.dart';
import 'package:library_app/features/settings/settings_screen.dart';
import 'package:library_app/features/settings/value_proposition_screen.dart';
import 'package:library_app/features/staff/staff_dashboard_screen.dart';
import 'package:library_app/features/staff/staff_scanner_screen.dart';
import 'package:library_app/features/staff/verification_result_screen.dart';
import 'package:library_app/features/waitlist/waitlist_joined_screen.dart';
import 'package:library_app/features/waitlist/waitlist_screen.dart';
import 'package:library_app/data/mock/mock_data.dart';

Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  // Render at a real phone size (and again narrow) so layout overflows
  // that only appear on small screens are caught here.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  // Route overflow diagnostics to the console so the failing widget is
  // named — installed before the first pump so nothing slips through.
  final overflows = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.toString();
    if (text.contains('overflowed')) overflows.add(text);
    // Forward every error so the framework surfaces the real failure
    // instead of swallowing it and tripping the teardown assertion.
    previous?.call(details);
  };
  addTearDown(() => FlutterError.onError = previous);

  await tester.pumpWidget(AppScope(
    state: AppState(),
    child: MaterialApp(theme: AppTheme.light(), home: screen),
  ));
  // Several screens hold a repeating pulse/shimmer animation, so
  // pumpAndSettle would never return. Pump a fixed number of frames
  // instead, then assert nothing threw.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }

  await tester.pumpWidget(AppScope(
    state: AppState(),
    child: MaterialApp(theme: AppTheme.light(), home: screen),
  ));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
  for (final o in overflows) {
    // ignore: avoid_print
    print('OVERFLOW-DETAIL >>> $o');
  }
  expect(overflows, isEmpty, reason: 'no RenderFlex overflow');
  expect(tester.takeException(), isNull);
}

void main() {
  final state = AppState();
  final book = MockData.books.first;
  final seat = MockData.seats.firstWhere((s) => s.label == '2C');
  final booking = MockData.buildBookings().first;
  final reservation = MockData.buildReservations().first;

  final screens = <String, Widget>{
    'home': const HomeScreen(),
    'bookSearch': const BookSearchScreen(),
    'bookDetail': BookDetailScreen(book: book),
    'reservationConfirm':
        ReservationConfirmationScreen(book: book, reservation: reservation),
    'reservationDetail': ReservationDetailScreen(reservation: reservation),
    'reservationCancelled': const ReservationCancelledScreen(),
    'seatMap': const SeatMapScreen(),
    'seatDetail': SeatDetailScreen(seat: seat),
    'bookingConfirm': BookingConfirmationScreen(booking: booking),
    'waitlist': const WaitlistScreen(),
    'waitlistJoined': WaitlistJoinedScreen(entry: MockData.buildWaitlist().first),
    'reservations': const ReservationsScreen(),
    'qrTicket': QrTicketScreen(booking: booking),
    'activeSession': ActiveSessionScreen(booking: booking),
    'notifications': const NotificationsScreen(),
    'settings': const SettingsScreen(),
    'valueProp': const ValuePropositionScreen(),
    'account': const AccountScreen(),
    'staffDashboard': const StaffDashboardScreen(),
    'staffScanner': const StaffScannerScreen(),
    'verification': const VerificationResultScreen(
      code: 'LIB-2026-4851',
      result: {
        'kind': 'seat',
        'status': 'active',
        'seatId': 's1',
        'ownerName': 'Damitha Samarakoon',
        'ownerId': 'IT2023-CS-084',
        'docPath': 'users/uid/bookings/LIB-2026-4851',
      },
    ),
  };

  screens.forEach((name, screen) {
    testWidgets('$name renders without exceptions', (tester) async {
      await pumpScreen(tester, screen);
    });
  });

  test('mock data matches the prototype', () {
    expect(state.books.length, greaterThanOrEqualTo(5));
    expect(state.seats.length, 16, reason: '4x4 seat grid');
    expect(state.seats.any((s) => s.label == '2C'), isTrue);
    expect(state.activeReservations, isNotEmpty);
  });
}
