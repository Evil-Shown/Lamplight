// Books screens at a large text scale: no overflow, no exceptions.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:library_app/core/state/app_state.dart';
import 'package:library_app/core/theme/app_theme.dart';
import 'package:library_app/features/books/book_detail_screen.dart';
import 'package:library_app/features/books/book_search_screen.dart';
import 'package:library_app/features/books/reservation_confirmation_screen.dart';
import 'package:library_app/features/books/reservation_detail_screen.dart';

void main() {
  testWidgets('book screens survive 1.5x text', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final state = AppState();
    final book = state.books.first;
    final reservation = (await state.reserveBook(book))!;
    final screens = <Widget>[
      const BookSearchScreen(),
      BookDetailScreen(book: book),
      ReservationConfirmationScreen(book: book, reservation: reservation),
      ReservationDetailScreen(reservation: reservation),
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
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      expect(tester.takeException(), isNull, reason: '$screen');
    }
    await tester.pumpWidget(const SizedBox());
  });
}
