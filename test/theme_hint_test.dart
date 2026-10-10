import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/app_shell.dart';
import 'package:library_app/core/state/app_state.dart';
import 'package:library_app/core/theme/app_theme.dart';
import 'package:library_app/services/preferences_store.dart';

class _Hydrated extends AppState {
  @override
  bool get isHydrated => true;
}

Future<AppState> _pumpShell(WidgetTester tester, {required bool seen}) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  final state = _Hydrated()
    ..applyLocalSettings(LocalSettings(themeHintSeen: seen));
  await tester.pumpWidget(AppScope(
    state: state,
    child: MaterialApp(theme: AppTheme.light(), home: const AppShell()),
  ));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  return state;
}

void main() {
  testWidgets('theme hint shows once when not yet seen', (tester) async {
    final state = await _pumpShell(tester, seen: false);
    expect(find.text('Light theme is on'), findsOneWidget);
    expect(state.themeHintSeen, isTrue);
  });

  testWidgets('theme hint stays hidden when already seen', (tester) async {
    await _pumpShell(tester, seen: true);
    expect(find.text('Light theme is on'), findsNothing);
  });
}
