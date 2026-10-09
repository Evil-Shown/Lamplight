import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_app/core/state/app_state.dart';
import 'package:library_app/core/theme/app_theme.dart';
import 'package:library_app/features/seats/seat_map_screen.dart';
import 'package:library_app/models/models.dart';

class _Hydrated extends AppState {
  @override
  bool get isHydrated => true;
}

class _NoSeats extends _Hydrated {
  @override
  List<Seat> get seats => const [];
}

void main() {
  for (final dark in [false, true]) {
    testWidgets('seat map renders in ${dark ? 'dark' : 'light'} at 1.5x text',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      AppColors.isDark = dark;
      addTearDown(() => AppColors.isDark = false);
      await tester.pumpWidget(AppScope(
        state: _Hydrated(),
        child: MaterialApp(
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: const SeatMapScreen(),
        ),
      ));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(tester.takeException(), isNull);
      expect(find.text('Pick your seat'), findsOneWidget);
      expect(find.text('Floor 2'), findsWidgets);
    });
  }

  testWidgets('a floor with no seats offers a way forward', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppScope(
      state: _NoSeats(),
      child: MaterialApp(theme: AppTheme.light(), home: const SeatMapScreen()),
    ));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(tester.takeException(), isNull);
    expect(find.text('Floor 2 has no seats yet'), findsOneWidget);
    expect(find.text('No seats to show'), findsOneWidget);
  });
}
