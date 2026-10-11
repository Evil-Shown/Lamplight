import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/core/state/app_state.dart';
import 'package:library_app/core/theme/app_theme.dart';
import 'package:library_app/models/models.dart';
import 'package:library_app/features/staff/admin/staff_books_screen.dart';
import 'package:library_app/features/staff/admin/staff_management_screen.dart';
import 'package:library_app/features/staff/staff_manage_screen.dart';
import 'package:library_app/features/staff/staff_scanner_screen.dart';
import 'package:library_app/features/staff/verification_result_screen.dart';

Future<void> _pump(WidgetTester tester, Widget screen, AppState state) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(AppScope(
    state: state,
    child: MaterialApp(theme: AppTheme.light(), home: screen),
  ));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// A state with no catalogue, as a live build looks before any book exists.
class _EmptyCatalogState extends AppState {
  @override
  List<Book> get adminBooks => const [];

  @override
  bool get isHydrated => true;
}

class _AdminState extends AppState {
  @override
  bool get isAdmin => true;

  @override
  bool get isStaff => true;
}

/// Pumps [screen] on a 360-wide phone at 1.5x text scale and asserts that
/// nothing overflowed or threw.
Future<void> _pumpScaled(
    WidgetTester tester, Widget screen, AppState state) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(AppScope(
    state: state,
    child: MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.5),
        ),
        child: child!,
      ),
      home: screen,
    ),
  ));
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('manage hub lists the four areas at 1.5x text', (tester) async {
    await _pumpScaled(tester, const StaffManageScreen(), AppState());
    expect(find.text('Reservations'), findsOneWidget);
    expect(find.text('Waiting list'), findsOneWidget);
    expect(find.text('Books'), findsOneWidget);
    expect(find.text('Seats'), findsOneWidget);
  });

  testWidgets('scanner works as a tab with no back button', (tester) async {
    await _pumpScaled(
        tester, const StaffScannerScreen(embedded: true), AppState());
    expect(find.byTooltip('Turn torch on'), findsNothing);
    expect(find.text('Verify Entered Code'), findsOneWidget);
  });

  testWidgets('staff management is not available to non-admins',
      (tester) async {
    await _pumpScaled(tester, const StaffManagementScreen(), AppState());
    expect(find.text('Not available'), findsOneWidget);
    expect(find.text('Add staff email'), findsNothing);
  });

  testWidgets('staff management renders for admins at 1.5x text',
      (tester) async {
    await _pumpScaled(tester, const StaffManagementScreen(), _AdminState());
    expect(find.text('Not available'), findsNothing);
    expect(find.text('Add staff email'), findsWidgets);
    expect(find.textContaining('next time they sign in'), findsOneWidget);
  });

  test('staff email validation', () {
    expect(validateStaffEmail(''), isNotNull);
    expect(validateStaffEmail('nope'), isNotNull);
    expect(validateStaffEmail('a@b'), isNotNull);
    expect(validateStaffEmail(' a@b.co '), isNull);
  });

  testWidgets('admin books shows an empty state when the catalog is empty',
      (tester) async {
    await _pump(tester, const StaffBooksScreen(), _EmptyCatalogState());
    expect(find.text('No books yet'), findsOneWidget);
    expect(find.text('Add a book'), findsWidgets);
  });

  testWidgets('valid verification result renders success', (tester) async {
    await _pump(
      tester,
      const VerificationResultScreen(code: 'LIB-1', result: {
        'result': 'valid',
        'kind': 'seat',
        'status': 'active',
        'seatId': 's1',
        'ownerName': 'Test Student',
        'ownerId': 'IT1',
        'docPath': 'users/u/bookings/LIB-1',
      }),
      AppState(),
    );
    expect(find.text('Valid reservation'), findsOneWidget);
    expect(find.text('Confirm Check-in'), findsOneWidget);
  });

  testWidgets('alreadyUsed verification result says so with the time',
      (tester) async {
    await _pump(
      tester,
      VerificationResultScreen(code: 'LIB-2', result: {
        'result': 'alreadyUsed',
        'kind': 'seat',
        'status': 'active',
        'checkedInAt': DateTime(2026, 10, 9, 14, 5),
        'ownerName': 'Test Student',
        'ownerId': 'IT1',
        'docPath': 'users/u/bookings/LIB-2',
      }),
      AppState(),
    );
    expect(find.text('This pass was already used'), findsOneWidget);
    expect(find.textContaining('Used on 9 Oct'), findsOneWidget);
    expect(find.text('Scan Again'), findsOneWidget);
  });

  test('passOutcomeOf maps server results', () {
    expect(passOutcomeOf(null), PassOutcome.notFound);
    expect(passOutcomeOf({'result': 'tooEarly'}), PassOutcome.tooEarly);
    expect(passOutcomeOf({'result': 'expired'}), PassOutcome.expired);
    expect(passOutcomeOf({'result': 'cancelled'}), PassOutcome.cancelled);
    expect(passOutcomeOf({'result': 'malformed'}), PassOutcome.notFound);
    expect(passOutcomeOf({'result': 'invalid'}), PassOutcome.invalid);
    expect(passOutcomeOf({'result': 'ambiguous'}), PassOutcome.ambiguous);
  });
}
