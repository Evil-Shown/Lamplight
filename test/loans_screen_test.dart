import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:library_app/core/state/app_state.dart';
import 'package:library_app/core/theme/app_theme.dart';
import 'package:library_app/features/loans/loans_screen.dart';
import 'package:library_app/models/models.dart';

class _LoansState extends AppState {
  _LoansState(this._loans);
  final List<Loan> _loans;

  @override
  List<Loan> get loans => _loans;

  @override
  bool get isHydrated => true;
}

Loan _loan(String id, String title, Duration due,
    {LoanStatus status = LoanStatus.active, DateTime? returnedAt}) {
  final now = DateTime.now();
  return Loan(
    id: id,
    userId: 'u',
    bookId: 'b$id',
    title: title,
    author: 'Author',
    checkedOutAt: now.subtract(const Duration(days: 14)),
    dueAt: now.add(due),
    status: status,
    returnedAt: returnedAt,
  );
}

void main() {
  testWidgets('renders loan sections with renew buttons', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final state = _LoansState([
      _loan('1', 'Late Book', const Duration(days: -3)),
      _loan('2', 'Soon Book', const Duration(hours: 30)),
      _loan('3', 'Fine Book', const Duration(days: 10)),
      _loan('4', 'Old Book', const Duration(days: -20),
          status: LoanStatus.returned, returnedAt: DateTime.now()),
    ]);

    await tester.pumpWidget(AppScope(
      state: state,
      child: MaterialApp(theme: AppTheme.light(), home: const LoansScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Overdue ('), findsOneWidget);
    expect(find.textContaining('Due soon ('), findsOneWidget);
    expect(find.textContaining('Active ('), findsOneWidget);
    expect(find.textContaining('Returned ('), findsOneWidget);
    expect(find.text('3 days overdue'), findsOneWidget);
    expect(find.text('Renew'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  test('loanDueLabel wording', () {
    final now = DateTime.now();
    expect(loanDueLabel(_loan('a', 'T', const Duration(days: 5, hours: 1)), now),
        'Due in 5 days');
    expect(loanDueLabel(_loan('b', 'T', const Duration(days: -2, hours: -1)), now),
        '2 days overdue');
  });
}
