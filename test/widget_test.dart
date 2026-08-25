import 'package:flutter_test/flutter_test.dart';

import 'package:library_app/app.dart';

void main() {
  testWidgets('App builds and shows bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const LibraryApp());
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Books'), findsOneWidget);
    expect(find.text('Seats'), findsOneWidget);
  });
}
