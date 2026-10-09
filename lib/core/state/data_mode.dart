import 'test_env.dart';

/// Owner opt-in for sample data: build with `--dart-define=DEMO_MODE=true`.
const bool kDemoMode = bool.fromEnvironment('DEMO_MODE');

/// Sample data may only appear under `flutter test` or an explicit demo
/// build. Production code must never fall back to it.
bool get mockDataAllowed => kDemoMode || isRunningInTest;
