import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/app.dart';
import 'package:library_app/core/state/app_state.dart';
import 'package:library_app/core/theme/app_theme.dart';
import 'package:library_app/models/models.dart';
import 'package:flutter/material.dart';

/// Pumps the app past the splash and signs in, so tests can assert on the
/// signed-in shell rather than the opening animation.
Future<AppState> _signIn(WidgetTester tester, {UserRole role = UserRole.student}) async {
  // The hero sheen and status pulses are infinite animations, so
  // pumpAndSettle would never return. Pump fixed frames instead.
  await tester.pumpWidget(const LibraryApp());
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }

  final context = tester.element(find.byType(MaterialApp));
  AppScope.read(context).signIn(identifier: 'test', role: role);
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  return AppScope.read(context);
}

void main() {
  testWidgets('splash hands over to the login screen', (tester) async {
    await tester.pumpWidget(const LibraryApp());
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(find.text('Sign in to Portal'), findsOneWidget);
  });

  testWidgets('student shell shows the prototype navigation', (tester) async {
    await _signIn(tester);

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Seats'), findsOneWidget);
    expect(find.text('Books'), findsOneWidget);
    expect(find.text('Bookings'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('staff shell swaps in the staff navigation', (tester) async {
    await _signIn(tester, role: UserRole.staff);

    expect(find.text('Catalog'), findsOneWidget);
    expect(find.text('Staff'), findsOneWidget);
    expect(find.text('Staff Dashboard'), findsOneWidget);
  });

  testWidgets('reserving a book adds it to state', (tester) async {
    final state = await _signIn(tester);
    final before = state.reservations.length;

    state.reserveBook(state.books.first);

    expect(state.reservations.length, before + 1);
  });

  testWidgets('theme uses the campus blue', (tester) async {
    expect(AppTheme.light().colorScheme.primary, AppColors.primary);
  });
}
