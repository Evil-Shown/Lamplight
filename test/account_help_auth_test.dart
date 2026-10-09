// Small tests for the connectivity banner, login errors, delete-account
// confirm and FAQ search.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:library_app/core/state/app_state.dart';
import 'package:library_app/core/theme/app_theme.dart';
import 'package:library_app/core/widgets/shared_widgets.dart';
import 'package:library_app/data/firebase/auth_failure.dart';
import 'package:library_app/features/account/account_screen.dart';
import 'package:library_app/features/auth/login_screen.dart';
import 'package:library_app/features/help/help_screen.dart';
import 'package:library_app/features/settings/settings_screen.dart';
import 'package:library_app/models/models.dart';

class _FakeState extends AppState {
  _FakeState(this._status, {this.source = DataSource.live, this.error});

  final SyncStatus _status;
  final DataSource source;
  final SyncError? error;
  int refreshes = 0;

  @override
  SyncStatus get syncStatus => _status;
  @override
  DataSource get dataSource => source;
  @override
  SyncError? get lastError => error;
  @override
  Future<void> refresh() async => refreshes++;
}

class _FailingState extends AppState {
  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
    required UserRole role,
  }) async =>
      throw const AuthFailure('wrong-password', 'Incorrect email or password.');
}

Future<void> _pump(WidgetTester tester, AppState state, Widget child) {
  return tester.pumpWidget(AppScope(
    state: state,
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  ));
}

void main() {
  group('ConnectivityBanner', () {
    final cases = <SyncStatus, String?>{
      SyncStatus.live: null,
      SyncStatus.syncing: 'Syncing…',
      SyncStatus.offline: "You're offline — showing saved data",
      SyncStatus.stale: "You're offline — showing saved data",
      SyncStatus.signedOut: 'Not signed in',
      SyncStatus.permissionDenied:
          "Can't load data: you don't have permission",
      SyncStatus.error: 'Server said no',
    };
    cases.forEach((status, text) {
      testWidgets('shows the right message for $status', (tester) async {
        final state = _FakeState(status,
            error: const SyncError(SyncStatus.error, 'Server said no'));
        await _pump(tester, state,
            ConnectivityBanner(lastSyncedAt: DateTime.now()));
        await tester.pump(const Duration(seconds: 1));
        if (text == null) {
          expect(find.byType(TextButton), findsNothing);
        } else {
          expect(find.text(text), findsOneWidget);
        }
      });
    });

    testWidgets('demo data shows a chip; Retry calls refresh', (tester) async {
      await _pump(tester, _FakeState(SyncStatus.live, source: DataSource.demo),
          const ConnectivityBanner(lastSyncedAt: null));
      expect(find.text('Demo data'), findsOneWidget);

      final offline = _FakeState(SyncStatus.offline);
      await _pump(
          tester, offline, const ConnectivityBanner(lastSyncedAt: null));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Retry'));
      expect(offline.refreshes, 1);
    });
  });

  testWidgets('login shows an AuthFailure message inline', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppScope(
      state: _FailingState(),
      child: MaterialApp(theme: AppTheme.light(), home: const LoginScreen()),
    ));
    await tester.enterText(find.byType(TextField).at(0), 'a@b.lk');
    await tester.enterText(find.byType(TextField).at(1), 'secret1');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });

  testWidgets('delete confirm requires the typed word', (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await showDialog<bool>(
            context: context,
            builder: (_) => const DeleteAccountDialog(),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    FilledButton button() =>
        tester.widget(find.widgetWithText(FilledButton, 'Delete account'));
    expect(button().onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'delete me');
    await tester.pump();
    expect(button().onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    expect(button().onPressed, isNotNull);
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  test('FAQ search filters entries', () {
    final all = buildFaq();
    expect(all.length, greaterThanOrEqualTo(12));
    final hits = filterFaq(all, 'QR scan');
    expect(hits, isNotEmpty);
    expect(hits.length, lessThan(all.length));
    expect(filterFaq(all, 'zzzzqqqq'), isEmpty);
    expect(filterFaq(all, '  '), all);
  });

  for (final entry in <String, Widget>{
    'login': const LoginScreen(),
    'account': const AccountScreen(),
    'settings': const SettingsScreen(),
    'help': const HelpScreen(),
  }.entries) {
    testWidgets('${entry.key} survives 1.5x text on a small phone',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(AppScope(
        state: AppState(),
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: entry.value,
        ),
      ));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      expect(tester.takeException(), isNull);
    });
  }
}
