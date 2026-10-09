import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/core/state/app_state.dart';
import 'package:library_app/core/theme/app_theme.dart';
import 'package:library_app/models/models.dart';
import 'package:library_app/features/staff/admin/staff_books_screen.dart';
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

void main() {
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
  });
}
