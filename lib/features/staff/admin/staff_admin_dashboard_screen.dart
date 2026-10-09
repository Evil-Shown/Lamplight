import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart'
    show AppNavInset, AppStrings;
import '../../../core/navigation/app_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/shared_widgets.dart';
import 'staff_books_screen.dart';
import 'staff_mock_data.dart';
import 'staff_reservations_screen.dart';
import 'staff_seats_screen.dart';
import 'staff_waitlist_screen.dart';
import 'widgets/staff_quick_action.dart';
import 'widgets/staff_stat_card.dart';
import 'widgets/staff_status_badge.dart';

/// Staff admin module home: today's summary, quick navigation and the
/// pickups that need attention next.
///
/// Sits alongside the Firestore-backed staff dashboard in the parent
/// folder; wire it into navigation once the team decides how the two
/// implementations integrate.
class StaffAdminDashboardScreen extends StatelessWidget {
  const StaffAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());
    final expired = StaffMockData.expiredReservationCount;

    return AppScaffold(
      title: 'Staff Admin',
      showBack: false,
      contentUnderBar: true,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.base,
          GlassAppBar.contentTopPadding(context),
          AppSpacing.base,
          AppNavInset.bottom,
        ),
        children: [
          _StaffHeader(date: today),
          const SizedBox(height: AppSpacing.base),
          if (expired > 0) ...[
            Callout(
              tone: CalloutTone.danger,
              icon: Icons.warning_amber_rounded,
              message:
                  '$expired reservation${expired == 1 ? '' : 's'} expired without pickup — follow up with the students.',
            ),
            const SizedBox(height: AppSpacing.base),
          ],
          const _StatsSection(),
          const SizedBox(height: AppSpacing.xl),
          Text('Quick actions', style: AppText.title(17, w: FontWeight.w800)),
          const SizedBox(height: AppSpacing.md),
          const _QuickActions(),
          const SizedBox(height: AppSpacing.xl),
          const _DueNextSection(),
        ],
      ),
    );
  }
}

/// Glass hero: brand, date, who is on shift and the key live figure.
class _StaffHeader extends StatelessWidget {
  const _StaffHeader({required this.date});

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
                          Text(StaffMockData.staffName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.title(15, w: FontWeight.w700)),
                          Text(
                            '${StaffMockData.staffRole} · ${StaffMockData.staffId}',
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
                  CountUp(
                    value: StaffMockData.activeReservationCount,
                    style: AppText.display(AppText.displayLg,
                        w: FontWeight.w800, color: AppColors.primary),
                  ),
                  Text('active now',
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
  const _StatsSection();

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
            value: '${StaffMockData.activeReservationCount}',
            label: 'Active Reservations',
            color: AppColors.success,
            onTap: () => openReservations('Active'),
          ),
          StaffStatCard(
            icon: Icons.event_busy_rounded,
            value: '${StaffMockData.expiredReservationCount}',
            label: 'Expired Reservations',
            color: AppColors.error,
            onTap: () => openReservations('Expired'),
          ),
          StaffStatCard(
            icon: Icons.hourglass_top_rounded,
            value: '${StaffMockData.waitlistCount}',
            label: 'Waiting List',
            color: AppColors.warning,
            onTap: () => AppRoute.push(
              context,
              const StaffWaitlistScreen(),
            ),
          ),
          StaffStatCard(
            icon: Icons.event_seat_rounded,
            value: '${StaffMockData.availableSeatCount}',
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
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) => AppRoute.push(context, screen);
    final items = [
      StaffQuickAction(
        icon: Icons.bookmark_rounded,
        label: 'Reservations',
        color: AppColors.primary,
        badge: StaffMockData.activeReservationCount,
        onTap: () => open(const StaffReservationsScreen()),
      ),
      StaffQuickAction(
        icon: Icons.hourglass_top_rounded,
        label: 'Waiting list',
        color: AppColors.warning,
        badge: StaffMockData.waitlistCount,
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
  const _DueNextSection();

  @override
  Widget build(BuildContext context) {
    final dueNext = StaffMockData.reservations
        .where((r) =>
            r.status == StaffReservationStatus.active && r.dueAt != null)
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
        if (dueNext.isEmpty)
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
                        icon: r.type == StaffReservationType.book
                            ? Icons.menu_book_rounded
                            : Icons.event_seat_rounded,
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
