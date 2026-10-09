import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart'
    show AppNavInset, AppStrings;
import '../../../core/navigation/app_route.dart';
import '../../../core/state/app_state.dart';
import '../../../models/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/shared_widgets.dart';
import 'staff_books_screen.dart';
import 'staff_reservations_screen.dart';
import 'staff_seats_screen.dart';
import 'staff_waitlist_screen.dart';
import 'widgets/staff_quick_action.dart';
import 'widgets/staff_live_states.dart';
import 'widgets/staff_stat_card.dart';
import 'widgets/staff_status_badge.dart';

/// Staff admin module home: today's summary, quick navigation and the
/// pickups that need attention next.
///
/// Every figure comes from [AppState]; sample data is never shown here.
class StaffAdminDashboardScreen extends StatelessWidget {
  const StaffAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());
    final state = AppScope.of(context);
    final counts = _Counts.of(state);
    final expired = counts.expired;
    final loading = staffLoading(state);
    final failed = staffFailed(state) && state.adminReservations.isEmpty;

    return AppScaffold(
      title: 'Staff Admin',
      showBack: false,
      contentUnderBar: true,
      body: StaffRefreshable(
        state: state,
        child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.base,
          GlassAppBar.contentTopPadding(context),
          AppSpacing.base,
          AppNavInset.bottom,
        ),
        children: [
          _StaffHeader(date: today, counts: counts, loading: loading),
          const SizedBox(height: AppSpacing.base),
          if (failed) ...[
            Callout(
              tone: CalloutTone.danger,
              icon: Icons.cloud_off_rounded,
              message: state.lastError?.message ??
                  'We could not load the latest figures. Pull down to retry.',
            ),
            const SizedBox(height: AppSpacing.base),
          ],
          if (expired > 0) ...[
            Callout(
              tone: CalloutTone.danger,
              icon: Icons.warning_amber_rounded,
              message:
                  '$expired reservation${expired == 1 ? '' : 's'} expired without pickup — follow up with the students.',
            ),
            const SizedBox(height: AppSpacing.base),
          ],
          _StatsSection(counts: counts, loading: loading),
          const SizedBox(height: AppSpacing.xl),
          Text('Quick actions', style: AppText.title(17, w: FontWeight.w800)),
          const SizedBox(height: AppSpacing.md),
          _QuickActions(counts: counts),
          const SizedBox(height: AppSpacing.xl),
          _DueNextSection(
              reservations: state.adminReservations, loading: loading),
        ],
      ),
      ),
    );
  }
}

/// Counts derived once per build from live [AppState] lists.
class _Counts {
  const _Counts({
    required this.active,
    required this.expired,
    required this.waiting,
    required this.freeSeats,
    required this.staffName,
    required this.staffId,
    required this.sessions,
  });

  final int active;
  final int expired;
  final int waiting;
  final int freeSeats;
  final int sessions;
  final String staffName;
  final String staffId;

  factory _Counts.of(AppState state) {
    final now = DateTime.now();
    var active = 0;
    var expired = 0;
    for (final r in state.adminReservations) {
      switch (staffReservationStatusLabel(r, now)) {
        case 'Active':
          active++;
        case 'Expired':
          expired++;
      }
    }
    return _Counts(
      active: active,
      expired: expired,
      waiting: state.dashboardStats.waitingCount,
      freeSeats:
          state.adminSeats.where((s) => s.status == SeatStatus.available).length,
      sessions: state.dashboardStats.activeSessions,
      staffName: state.staffName,
      staffId: state.staffId,
    );
  }
}

/// Glass hero: brand, date, who is on shift and the key live figure.
class _StaffHeader extends StatelessWidget {
  const _StaffHeader({
    required this.date,
    required this.counts,
    required this.loading,
  });

  final _Counts counts;
  final bool loading;

  String get _brandLabel => '${AppStrings.appName} · Staff';

  final String date;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: AppRadii.xl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_library_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  _brandLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(13,
                      w: FontWeight.w700, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          Text('Staff Dashboard',
              style: AppText.display(26, w: FontWeight.w800)),
          const SizedBox(height: AppSpacing.xs),
          Text(date, style: AppText.body(14, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.base),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Row(
                  children: [
                    IconBadge(
                        icon: Icons.badge_rounded, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(counts.staffName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.title(15, w: FontWeight.w700)),
                          Text(
                            counts.staffId.isEmpty
                                ? 'Library staff'
                                : 'Library staff · ${counts.staffId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(12.5,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (loading)
                    const Skeleton(width: 48, height: 40)
                  else
                    CountUp(
                      value: counts.sessions,
                      style: AppText.display(AppText.displayLg,
                          w: FontWeight.w800, color: AppColors.primary),
                    ),
                  Text('seated now',
                      style: AppText.label(12, w: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.counts, required this.loading});

  final _Counts counts;
  final bool loading;

  String _v(int n) => loading ? '—' : '$n';

  @override
  Widget build(BuildContext context) {
    void openReservations(String filter) => AppRoute.push(
          context,
          StaffReservationsScreen(initialFilter: filter),
        );

    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 640 ? 4 : 2;
      return GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisExtent: 156,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
        ),
        children: [
          StaffStatCard(
            icon: Icons.bookmark_rounded,
            value: _v(counts.active),
            label: 'Active Reservations',
            color: AppColors.success,
            onTap: () => openReservations('Active'),
          ),
          StaffStatCard(
            icon: Icons.event_busy_rounded,
            value: _v(counts.expired),
            label: 'Expired Reservations',
            color: AppColors.error,
            onTap: () => openReservations('Expired'),
          ),
          StaffStatCard(
            icon: Icons.hourglass_top_rounded,
            value: _v(counts.waiting),
            label: 'Waiting List',
            color: AppColors.warning,
            onTap: () => AppRoute.push(
              context,
              const StaffWaitlistScreen(),
            ),
          ),
          StaffStatCard(
            icon: Icons.event_seat_rounded,
            value: _v(counts.freeSeats),
            label: 'Available Seats',
            color: AppColors.info,
            onTap: () => AppRoute.push(
              context,
              const StaffSeatsScreen(),
            ),
          ),
        ],
      );
    });
  }
}

/// Bento grid of the four admin destinations.
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.counts});

  final _Counts counts;

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) => AppRoute.push(context, screen);
    final items = [
      StaffQuickAction(
        icon: Icons.bookmark_rounded,
        label: 'Reservations',
        color: AppColors.primary,
        badge: counts.active,
        onTap: () => open(const StaffReservationsScreen()),
      ),
      StaffQuickAction(
        icon: Icons.hourglass_top_rounded,
        label: 'Waiting list',
        color: AppColors.warning,
        badge: counts.waiting,
        onTap: () => open(const StaffWaitlistScreen()),
      ),
      StaffQuickAction(
        icon: Icons.menu_book_rounded,
        label: 'Book availability',
        color: AppColors.accent,
        onTap: () => open(const StaffBooksScreen()),
      ),
      StaffQuickAction(
        icon: Icons.event_seat_rounded,
        label: 'Seat availability',
        color: AppColors.info,
        onTap: () => open(const StaffSeatsScreen()),
      ),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 640 ? 4 : 2;
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: columns,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: columns == 2 ? 1.4 : 1.25,
        children: [
          for (var i = 0; i < items.length; i++)
            StaggeredEntrance(index: i, child: items[i]),
        ],
      );
    });
  }
}

/// Active reservations closest to their pickup deadline / booking end.
class _DueNextSection extends StatelessWidget {
  const _DueNextSection({required this.reservations, required this.loading});

  final List<AdminReservation> reservations;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final dueNext = reservations
        .where((r) =>
            staffReservationStatusLabel(r) == 'Active' && r.dueAt != null)
        .toList()
      ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Needs attention next',
          subtitle: 'Active reservations by pickup deadline',
          actionLabel: 'View all',
          onAction: () => AppRoute.push(
            context,
            const StaffReservationsScreen(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (loading)
          const SkeletonCard(height: 60)
        else if (dueNext.isEmpty)
          SurfaceCard(
            child: Text(
              'No active reservations right now.',
              style: AppText.body(14, color: AppColors.textSecondary),
            ),
          )
        else
          ...dueNext.take(3).map(
                (r) => SurfaceCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  onTap: () => AppRoute.push(
                    context,
                    const StaffReservationsScreen(),
                  ),
                  child: Row(
                    children: [
                      IconBadge(
                        icon: r.isSeat
                            ? Icons.event_seat_rounded
                            : Icons.menu_book_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.studentName,
                              style: AppText.title(15, w: FontWeight.w800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${r.itemTitle} · ${r.studentId}',
                              style: AppText.body(13,
                                  color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StaffStatusBadge(
                        label: _dueLabel(r.dueAt!),
                        tone: _dueTone(r.dueAt!),
                        compact: true,
                      ),
                    ],
                  ),
                ),
              ),
      ],
    );
  }

  String _dueLabel(DateTime due) {
    final diff = due.difference(DateTime.now());
    if (diff.isNegative) return 'Overdue';
    if (diff.inMinutes < 60) return 'in ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'in ${diff.inHours}h';
    return DateFormat('MMM d').format(due);
  }

  StaffBadgeTone _dueTone(DateTime due) {
    final diff = due.difference(DateTime.now());
    if (diff.isNegative) return StaffBadgeTone.danger;
    if (diff.inHours <= 6) return StaffBadgeTone.warning;
    return StaffBadgeTone.success;
  }
}
