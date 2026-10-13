import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:library_app/core/state/app_state.dart';
import 'package:library_app/core/state/staff_logic.dart';
import 'package:library_app/core/theme/app_theme.dart';
import 'package:library_app/core/widgets/shared_widgets.dart';
import 'package:library_app/features/staff/admin/staff_reservations_screen.dart';
import 'package:library_app/features/staff/admin/staff_waitlist_screen.dart';
import 'package:library_app/features/staff/extend_time_screen.dart';
import 'package:library_app/features/staff/staff_dashboard_screen.dart';
import 'package:library_app/models/models.dart';

// ------------------------------------------------------------------ helpers

final _clock = DateTime(2026, 10, 13, 14, 0);

DateTime _at(int h, int m, [int s = 0]) => DateTime(2026, 10, 13, h, m, s);

AdminReservation _seat(
  String id, {
  required DateTime start,
  required DateTime end,
  DateTime? checkedIn,
  ReservationStatus status = ReservationStatus.active,
  String seatId = 'seat-1',
  String name = 'Nimal Perera',
}) =>
    AdminReservation(
      id: id,
      ownerUid: 'u-$id',
      studentName: name,
      studentId: 'IT-$id',
      isSeat: true,
      itemTitle: 'Seat 2C',
      itemSubtitle: 'Floor 2 · Quiet Zone',
      reservedAt: start,
      dueAt: end,
      status: status,
      path: 'users/u-$id/bookings/$id',
      resourceId: seatId,
      startAt: start,
      endAt: end,
      checkedInAt: checkedIn,
    );

AdminReservation _book(String id,
        {required DateTime due,
        ReservationStatus status = ReservationStatus.ready}) =>
    AdminReservation(
      id: id,
      ownerUid: 'u-$id',
      studentName: 'Hiruni Rathnayake',
      studentId: 'IT-$id',
      isSeat: false,
      itemTitle: 'Clean Code',
      itemSubtitle: 'Robert C. Martin · B2-14',
      reservedAt: _at(9, 0),
      dueAt: due,
      status: status,
      path: 'users/u-$id/reservations/$id',
      resourceId: 'book-1',
    );

class _FakeState extends AppState {
  _FakeState({
    this.rows = const [],
    this.queued = const [],
    this.freeSeats,
  });

  final List<AdminReservation> rows;
  final List<AdminWaitlistItem> queued;
  final int? freeSeats;

  @override
  List<AdminReservation> get adminReservations => rows;

  @override
  List<AdminWaitlistItem> get adminWaitlist => queued;

  @override
  bool get isStaff => true;

  @override
  List<Seat> get adminSeats => freeSeats == null
      ? super.adminSeats
      : [
          for (var i = 0; i < freeSeats!; i++)
            super.adminSeats.first.copyWith(status: SeatStatus.available),
        ];
}

/// Scripted relative to the real clock, with wide margins.
List<AdminReservation> _scripted() {
  final now = DateTime.now();
  return [
    _seat('act',
        start: now.subtract(const Duration(minutes: 30)),
        end: now.add(const Duration(minutes: 90)),
        checkedIn: now.subtract(const Duration(minutes: 28)),
        name: 'Active Student'),
    _seat('pen',
        start: now.subtract(const Duration(minutes: 5)),
        end: now.add(const Duration(hours: 2)),
        name: 'Pending Student'),
    _seat('exp',
        start: now.subtract(const Duration(minutes: 90)),
        end: now.subtract(const Duration(minutes: 20)),
        checkedIn: now.subtract(const Duration(minutes: 85)),
        name: 'Expired Student'),
    _seat('don',
        start: now.subtract(const Duration(hours: 5)),
        end: now.subtract(const Duration(hours: 3)),
        status: ReservationStatus.completed,
        name: 'Done Student'),
    _book('bk', due: now.add(const Duration(days: 2))),
  ];
}

Future<void> _pump(WidgetTester tester, Widget screen, AppState state,
    {double scale = 1, Size size = const Size(1080, 2400)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  // Name the overflowing widget in the failure rather than only the pixels.
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.toString().contains('overflowed')) {
      // ignore: avoid_print
      print('OVERFLOW >>> $details');
    }
    previous?.call(details);
  };
  addTearDown(() => FlutterError.onError = previous);
  await tester.pumpWidget(AppScope(
    state: state,
    child: MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: screen,
    ),
  ));
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  // ---------------------------------------------------------- pure functions

  group('staffReservationState and time notes', () {
    test('active seat counts down to its end', () {
      final r = _seat('a',
          start: _at(13, 20), end: _at(15, 18), checkedIn: _at(13, 22));
      expect(staffReservationState(r, _clock), StaffResState.active);
      expect(staffTimeNote(r, _clock), '1h 18m left');
      expect(staffContextNote(r, _clock), 'Since 13:22');
    });

    test('active seat under an hour shows minutes only', () {
      final r = _seat('a',
          start: _at(13, 0), end: _at(14, 42), checkedIn: _at(13, 1));
      expect(staffTimeNote(r, _clock), '42m left');
    });

    test('pending seat before start, in grace, then no-show', () {
      final upcoming = _seat('p', start: _at(14, 15), end: _at(16, 0));
      expect(staffReservationState(upcoming, _clock), StaffResState.pending);
      expect(staffTimeNote(upcoming, _clock), 'Starts 14:15');

      // Started 10m30s ago: 04:30 of the 15 minute grace left.
      final grace = _seat('p', start: _at(13, 49, 30), end: _at(16, 0));
      expect(staffReservationState(grace, _clock), StaffResState.pending);
      expect(staffTimeNote(grace, _clock), '04:30 grace');

      final late = _seat('p', start: _at(13, 40), end: _at(16, 0));
      expect(staffReservationState(late, _clock), StaffResState.pending);
      expect(staffTimeNote(late, _clock), 'No-show');
    });

    test('expired once the window ends, with overdue time', () {
      final r = _seat('e',
          start: _at(12, 0), end: _at(13, 30), checkedIn: _at(12, 1));
      expect(staffReservationState(r, _clock), StaffResState.expired);
      expect(staffTimeNote(r, _clock), '+30m overdue');
      expect(staffContextNote(r, _clock), 'Ended 13:30');

      final long = _seat('e', start: _at(11, 0), end: _at(12, 55));
      expect(staffTimeNote(long, _clock), '+1h 05m overdue');
    });

    test('completed and cancelled come from the stored status', () {
      final done = _seat('c',
          start: _at(10, 0),
          end: _at(20, 0),
          status: ReservationStatus.completed);
      final gone = _seat('c',
          start: _at(10, 0),
          end: _at(20, 0),
          status: ReservationStatus.cancelled);
      expect(staffReservationState(done, _clock), StaffResState.completed);
      expect(staffReservationState(gone, _clock), StaffResState.cancelled);
    });

    test('book reservations are pending until the pickup deadline', () {
      final open = _book('b', due: DateTime(2026, 10, 15, 14, 0));
      expect(staffReservationState(open, _clock), StaffResState.pending);
      expect(staffTimeNote(open, _clock), '48h 0m left');
      final late = _book('b', due: _at(13, 0));
      expect(staffReservationState(late, _clock), StaffResState.expired);
      expect(staffReservationStatusLabel(late, _clock), 'Expired');
    });
  });

  group('seatExtensionConflict', () {
    final mine = _seat('mine',
        start: _at(13, 0), end: _at(15, 0), checkedIn: _at(13, 1));

    test('is null with nothing else on the seat', () {
      expect(seatExtensionConflict(mine, _at(15, 30), [mine]), isNull);
    });

    test('finds a later booking that starts before the new end', () {
      final next = _seat('next', start: _at(15, 20), end: _at(17, 0));
      expect(seatExtensionConflict(mine, _at(15, 15), [mine, next]), isNull);
      expect(
          seatExtensionConflict(mine, _at(15, 30), [mine, next])?.id, 'next');
    });

    test('ignores other seats, cancelled, completed and earlier bookings', () {
      final otherSeat =
          _seat('o', start: _at(15, 10), end: _at(17, 0), seatId: 'seat-2');
      final cancelled = _seat('c',
          start: _at(15, 10),
          end: _at(17, 0),
          status: ReservationStatus.cancelled);
      final done = _seat('d',
          start: _at(15, 10),
          end: _at(17, 0),
          status: ReservationStatus.completed);
      final earlier = _seat('e', start: _at(9, 0), end: _at(12, 0));
      expect(
          seatExtensionConflict(
              mine, _at(16, 0), [otherSeat, cancelled, done, earlier]),
          isNull);
    });

    test('reports the earliest of several clashes', () {
      final late = _seat('late', start: _at(15, 40), end: _at(18, 0));
      final soon = _seat('soon', start: _at(15, 10), end: _at(15, 40));
      expect(
          seatExtensionConflict(mine, _at(16, 30), [late, soon])?.id, 'soon');
    });
  });

  group('buildReservationsCsv', () {
    test('has a header and one line per row', () {
      final csv = buildReservationsCsv([
        _seat('a', start: _at(13, 0), end: _at(15, 0), checkedIn: _at(13, 1)),
      ], _clock);
      final lines = csv.split('\n');
      expect(lines.first,
          'student,studentId,type,item,detail,reserved,start,end,state');
      expect(lines, hasLength(2));
      expect(
          lines[1],
          'Nimal Perera,IT-a,Seat,Seat 2C,Floor 2 · Quiet Zone,'
          '2026-10-13 13:00,2026-10-13 13:00,2026-10-13 15:00,Active');
    });

    test('quotes commas, quotes and line breaks', () {
      final tricky = AdminReservation(
        id: 'x',
        ownerUid: 'u',
        studentName: 'Perera, Nimal "Nim"',
        studentId: 'IT\n1',
        isSeat: false,
        itemTitle: 'Plain',
        itemSubtitle: 'a,b',
        reservedAt: _at(9, 0),
        dueAt: _at(23, 0),
        status: ReservationStatus.ready,
      );
      final csv = buildReservationsCsv([tricky], _clock);
      expect(csv, contains('"Perera, Nimal ""Nim"""'));
      expect(csv, contains('"IT\n1"'));
      expect(csv, contains('"a,b"'));
      expect(csvField('plain'), 'plain');
    });

    test('an empty list is only the header', () {
      expect(buildReservationsCsv(const [], _clock).split('\n'), hasLength(1));
    });
  });

  test('averageWaitLabel averages waiting entries only', () {
    WaitlistEntry entry(int minutes,
            [WaitlistStatus s = WaitlistStatus.waiting]) =>
        WaitlistEntry(
          id: 'w$minutes',
          type: WaitlistType.seat,
          title: 'Seat',
          subtitle: '',
          position: 1,
          joinedAt: _clock.subtract(Duration(minutes: minutes)),
          status: s,
        );
    expect(averageWaitLabel(const [], _clock), '—');
    expect(averageWaitLabel([entry(10), entry(30)], _clock), '20m');
    expect(
        averageWaitLabel(
            [entry(10), entry(500, WaitlistStatus.offered)], _clock),
        '10m');
    expect(averageWaitLabel([entry(125)], _clock), '2h 5m');
  });

  // ------------------------------------------------------- AppState actions

  group('staff actions in demo mode', () {
    AdminReservation byId(AppState s, String id) =>
        s.adminReservations.firstWhere((r) => r.id == id);

    test('extendSeatBooking moves the end and enforces limits', () async {
      final state = AppState();
      final r = byId(state, 'B-1001');
      await state.extendSeatBooking(r, const Duration(minutes: 30));
      expect(byId(state, 'B-1001').endAt,
          r.endAt!.add(const Duration(minutes: 30)));
      expect(byId(state, 'B-1001').dueAt, byId(state, 'B-1001').endAt);

      await expectLater(
          state.extendSeatBooking(
              byId(state, 'B-1001'), const Duration(hours: 3)),
          throwsA(isA<StaffActionException>()));
      // B-1005 starts on the same seat three hours from now.
      await expectLater(
          state.extendSeatBooking(
              byId(state, 'B-1001'), const Duration(hours: 2)),
          throwsA(isA<StaffActionException>()
              .having((e) => e.message, 'message', contains('Conflicts'))));
    });

    test('check in, cancel and release update state and the seat', () async {
      final state = AppState();
      await state.staffCheckIn(byId(state, 'B-1002'));
      expect(byId(state, 'B-1002').checkedInAt, isNotNull);
      expect(staffReservationState(byId(state, 'B-1002'), DateTime.now()),
          StaffResState.active);

      await state.staffReleaseSeat(byId(state, 'B-1004'));
      expect(byId(state, 'B-1004').status, ReservationStatus.completed);
      expect(state.seats.firstWhere((s) => s.id == 's0_3').status,
          SeatStatus.available);

      await state.staffCancelReservation(byId(state, 'B-1003'));
      expect(byId(state, 'B-1003').status, ReservationStatus.cancelled);
      expect(state.seats.firstWhere((s) => s.id == 's3_1').status,
          SeatStatus.available);
    });

    test('setSeatStatus shows locally without a backend', () async {
      final state = AppState();
      await state.setSeatStatus('s0_0', SeatStatus.available);
      expect(state.seats.firstWhere((s) => s.id == 's0_0').status,
          SeatStatus.available);
    });
  });

  // ----------------------------------------------------------------- widgets

  group('dashboard', () {
    testWidgets('shows the four tiles and per-state actions', (tester) async {
      await _pump(tester, const StaffDashboardScreen(),
          _FakeState(rows: _scripted()),
          size: const Size(1080, 5000));

      expect(find.text('Staff Dashboard'), findsOneWidget);
      expect(find.text('Library Control Hub'), findsOneWidget);
      expect(find.byTooltip('Scan a pass'), findsOneWidget);
      expect(find.text('Search students, seats or IDs'), findsOneWidget);
      for (final t in ['Reservations', 'Waitlist', 'Catalog', 'Seat Avail']) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      expect(find.text('Queue Dispatch'), findsOneWidget);

      // Expired first, then pending, then active.
      final expY = tester.getTopLeft(find.text('Expired Student')).dy;
      final penY = tester.getTopLeft(find.text('Pending Student')).dy;
      final actY = tester.getTopLeft(find.text('Active Student')).dy;
      expect(expY, lessThan(penY));
      expect(penY, lessThan(actY));

      expect(find.text('EXPIRED'), findsOneWidget);
      expect(find.text('PENDING'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      for (final a in [
        'Monitor',
        'Extend',
        'Notify',
        'Check In',
        'Alert',
        'Release Desk'
      ]) {
        expect(find.text(a), findsOneWidget, reason: a);
      }
      // Completed bookings and book reservations are not dispatched.
      expect(find.text('Done Student'), findsNothing);
      expect(find.text('Hiruni Rathnayake'), findsNothing);
    });

    testWidgets('search and the Urgent filter narrow the list',
        (tester) async {
      await _pump(tester, const StaffDashboardScreen(),
          _FakeState(rows: _scripted()),
          size: const Size(1080, 5000));

      await tester.tap(find.text('Urgent'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Active Student'), findsNothing);
      expect(find.text('Pending Student'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'expired');
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Pending Student'), findsNothing);
      expect(find.text('Expired Student'), findsOneWidget);
    });

    testWidgets('empty dispatch shows All clear', (tester) async {
      await _pump(tester, const StaffDashboardScreen(), _FakeState());
      expect(find.text('All clear'), findsOneWidget);
      expect(find.text('No seat bookings need attention right now.'),
          findsOneWidget);
    });

    testWidgets('Check In and Release Desk act on the booking',
        (tester) async {
      final state = AppState();
      await _pump(tester, const StaffDashboardScreen(), state,
          size: const Size(1080, 5000));

      await tester.tap(find.text('Release Desk').first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Release this seat?'), findsOneWidget);
      await tester.tap(find.text('Release'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
          state.adminReservations
              .firstWhere((r) => r.id == 'B-1004')
              .status,
          ReservationStatus.completed);

      await tester.tap(find.text('Check In').first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(
          state.adminReservations
              .firstWhere((r) => r.id == 'B-1002')
              .checkedInAt,
          isNotNull);
    });

    testWidgets('fits 360dp at 1.5x text', (tester) async {
      await _pump(tester, const StaffDashboardScreen(),
          _FakeState(rows: _scripted()),
          scale: 1.5);
      expect(tester.takeException(), isNull);
    });
  });

  group('reservations', () {
    testWidgets('chips carry counts and buttons follow the state',
        (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await _pump(tester, const StaffReservationsScreen(embedded: true),
          _FakeState(rows: _scripted()),
          size: const Size(1080, 6000));

      expect(find.text('5 total'), findsOneWidget);
      expect(find.text('Search name, seat or ID'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);

      // The chip row scrolls sideways, so bring each chip into view first.
      Future<void> chip(String label) async {
        await tester.drag(find.byType(FilterChipRow), const Offset(2000, 0));
        await tester.pump();
        await tester.dragUntilVisible(
            find.text(label), find.byType(FilterChipRow), const Offset(-120, 0));
        await tester.ensureVisible(find.text(label));
        await tester.pump();
        await tester.tap(find.text(label));
        await tester.pump(const Duration(milliseconds: 400));
      }

      for (final c in [
        'Active (1)',
        'Pending (2)',
        'Expired (1)',
        'Completed',
        'Cancelled',
        'All (5)'
      ]) {
        await chip(c);
      }

      await chip('Active (1)');
      expect(find.text('Extend'), findsOneWidget);
      expect(find.text('Monitor'), findsOneWidget);
      expect(find.text('Check In'), findsNothing);

      await chip('Pending (2)');
      expect(find.text('Check In'), findsOneWidget);
      expect(find.text('Cancel'), findsNWidgets(2));
      expect(find.text('Details'), findsOneWidget); // the book
      expect(find.text('Pending Check-In'), findsOneWidget);
      expect(find.text('Pending Pickup'), findsOneWidget);

      await chip('Expired (1)');
      expect(find.text('Release Seat'), findsOneWidget);
      expect(find.text('Alert'), findsOneWidget);

      await chip('Completed');
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Extend'), findsNothing);

      await chip('All (5)');
      await tester.tap(find.text('Export Log'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Copied 5 rows as CSV'), findsOneWidget);
      expect(copied!.split('\n'), hasLength(6));
      expect(copied, contains('Expired Student'));
    });

    testWidgets('Alert opens a prefilled message sheet', (tester) async {
      await _pump(
          tester,
          const StaffReservationsScreen(initialFilter: 'Expired'),
          _FakeState(rows: _scripted()));
      await tester.tap(find.text('Alert'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Message Expired Student'), findsOneWidget);
      expect(find.textContaining('Your seat booking for 2C has ended'),
          findsOneWidget);
      expect(find.text('Send'), findsOneWidget);
    });

    testWidgets('fits 360dp at 1.5x text', (tester) async {
      await _pump(tester, const StaffReservationsScreen(),
          _FakeState(rows: _scripted()),
          scale: 1.5);
      expect(tester.takeException(), isNull);
    });
  });

  group('extend time', () {
    AdminReservation mock(AppState s, String id) =>
        s.adminReservations.firstWhere((r) => r.id == id);

    PrimaryButton confirmButton(WidgetTester tester) => tester.widget(
        find.widgetWithText(PrimaryButton, 'Confirm Extension'));

    testWidgets('preselects +30 and shows the new end time', (tester) async {
      final state = AppState();
      final r = mock(state, 'B-1001');
      await _pump(tester, ExtendTimeScreen(reservation: r), state);

      expect(find.text('Extend Time'), findsOneWidget);
      expect(find.text('Select extension'), findsOneWidget);
      expect(find.text('Max +2 hrs'), findsOneWidget);
      for (final t in ['+15 mins', '+30 mins', '+1 hour', '+2 hours']) {
        expect(find.text(t), findsOneWidget);
      }
      expect(find.text('Recommended'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      final expected = DateFormat('HH:mm')
          .format(r.endAt!.add(const Duration(minutes: 30)));
      expect(find.text(expected), findsOneWidget);
      expect(find.text('Available · No conflicts on 2C'), findsOneWidget);
      expect(confirmButton(tester).onPressed, isNotNull);
    });

    testWidgets('disables confirm when the next booking is in the way',
        (tester) async {
      final state = AppState();
      final r = mock(state, 'B-1001');
      await _pump(tester, ExtendTimeScreen(reservation: r), state);

      await tester.tap(find.text('+2 hours'));
      await tester.pump(const Duration(milliseconds: 400));
      final next = mock(state, 'B-1005');
      expect(
          find.text('Conflicts with the next booking at '
              '${DateFormat('HH:mm').format(next.startAt!)}'),
          findsOneWidget);
      expect(confirmButton(tester).onPressed, isNull);

      await tester.tap(find.text('+15 mins'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(confirmButton(tester).onPressed, isNotNull);
    });

    testWidgets('confirming shows Time Extended', (tester) async {
      final state = AppState();
      final r = mock(state, 'B-1001');
      await _pump(tester, ExtendTimeScreen(reservation: r), state);

      await tester.tap(find.text('Confirm Extension'));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.text('Time Extended'), findsOneWidget);
      expect(find.text('EXTENSION CONFIRMED'), findsOneWidget);
      expect(
          find.text("Nimal Perera's reservation on Seat 2C has been extended "
              'by +30 minutes.'),
          findsOneWidget);
      expect(find.text('Back to Reservations'), findsOneWidget);
      expect(find.text('Extension added'), findsOneWidget);
      expect(mock(state, 'B-1001').endAt,
          r.endAt!.add(const Duration(minutes: 30)));
    });
  });

  group('waiting list', () {
    testWidgets('renders the stats card, queue and actions', (tester) async {
      final now = DateTime.now();
      AdminWaitlistItem item(String n, int minutes, WaitlistStatus s) =>
          AdminWaitlistItem(
            id: n,
            ownerUid: 'u-$n',
            studentName: 'Student $n',
            studentId: 'ID-$n',
            entry: WaitlistEntry(
              id: n,
              type: WaitlistType.seat,
              title: 'Seat 2C',
              subtitle: 'Floor 2',
              position: 1,
              joinedAt: now.subtract(Duration(minutes: minutes)),
              status: s,
            ),
          );
      final state = _FakeState(freeSeats: 5, queued: [
        item('a', 30, WaitlistStatus.waiting),
        item('b', 20, WaitlistStatus.waiting),
        item('c', 10, WaitlistStatus.waiting),
        item('d', 45, WaitlistStatus.offered),
      ]);
      await _pump(tester, const StaffWaitlistScreen(), state,
          size: const Size(1080, 4000));

      expect(find.text('3 in queue'), findsOneWidget);
      expect(find.text('IN LINE'), findsOneWidget);
      expect(find.text('AVG WAIT'), findsOneWidget);
      expect(find.text('FREE SEATS'), findsOneWidget);
      expect(find.text('20m'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('PRIORITY QUEUE'), findsOneWidget);
      expect(find.text('Sorted by wait time'), findsOneWidget);
      expect(
          find.text(
              'Offers are sent automatically when a copy or seat frees up.'),
          findsOneWidget);
      expect(find.text('Notify'), findsNWidgets(4));
      expect(find.text('Details'), findsNWidgets(4));
      // Longest wait first, and over 15 minutes reads as a warning.
      expect(tester.getTopLeft(find.text('Student d')).dy,
          lessThan(tester.getTopLeft(find.text('Student c')).dy));
      expect(find.text('45m ago'), findsOneWidget);
    });

    testWidgets('empty queue shows dashes and fits at 1.5x', (tester) async {
      await _pump(tester, const StaffWaitlistScreen(), _FakeState(),
          scale: 1.5);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Queue is empty'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
