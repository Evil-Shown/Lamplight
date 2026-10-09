import 'package:flutter/material.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shared_widgets.dart';

/// True while the first live snapshot has not landed. Demo/test builds
/// carry sample data from the start, so they never show the skeleton.
bool staffLoading(AppState s) =>
    !s.isHydrated && s.dataSource != DataSource.demo;

/// True when Firestore rejected a read or a stream failed.
bool staffFailed(AppState s) =>
    s.syncStatus == SyncStatus.permissionDenied ||
    s.syncStatus == SyncStatus.error;

/// Loading / error wrapper shared by the staff lists. [hasData] says whether
/// anything is already on screen: a failure only replaces the content when
/// there is nothing (last good data stays visible otherwise).
class StaffLiveGate extends StatelessWidget {
  const StaffLiveGate({
    super.key,
    required this.state,
    required this.hasData,
    required this.builder,
    this.skeletonHeight = 120,
  });

  final AppState state;
  final bool hasData;
  final WidgetBuilder builder;
  final double skeletonHeight;

  @override
  Widget build(BuildContext context) {
    if (staffLoading(state)) {
      return ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.base),
        children: [
          for (var i = 0; i < 4; i++) ...[
            SkeletonCard(height: skeletonHeight),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      );
    }
    if (staffFailed(state) && !hasData) {
      return StaffScrollable(
        state: state,
        child: ErrorState(
          message: state.lastError?.message ??
              'We could not load this data just now.',
          onRetry: state.refresh,
        ),
      );
    }
    return builder(context);
  }
}

/// Pull-to-refresh around a scroll view; calls [AppState.refresh].
class StaffRefreshable extends StatelessWidget {
  const StaffRefreshable({super.key, required this.state, required this.child});

  final AppState state;
  final Widget child;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: state.refresh,
        child: child,
      );
}

/// Centres a non-scrolling [child] (empty / error state) inside a scroll view
/// so pull-to-refresh still works on it.
class StaffScrollable extends StatelessWidget {
  const StaffScrollable({super.key, required this.state, required this.child});

  final AppState state;
  final Widget child;

  @override
  Widget build(BuildContext context) => StaffRefreshable(
        state: state,
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : 400,
                child: child,
              ),
            ],
          ),
        ),
      );
}
