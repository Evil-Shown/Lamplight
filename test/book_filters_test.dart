import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:library_app/core/theme/app_theme.dart';
import 'package:library_app/data/book_search.dart';
import 'package:library_app/features/books/book_filters.dart';

void main() {
  testWidgets('selecting a subject and sort reports filters', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    BookFilters? last;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Column(children: [
          BookFilterSheet(
            initial: const BookFilters(),
            subjects: const ['Computing', 'Law'],
            onChanged: (f) => last = f,
          )
        ]),
      ),
    ));

    await tester.tap(find.text('Law'));
    await tester.pump();
    expect(last?.subject, 'Law');
    expect(last?.activeCount, 1);

    await tester.tap(find.text('Newest'));
    await tester.pump();
    expect(last?.sort, BookSort.newest);
    expect(last?.subject, 'Law');
  });
}
