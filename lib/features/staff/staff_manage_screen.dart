import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart' show AppNavInset;
import '../../core/navigation/app_route.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import 'admin/staff_books_screen.dart';
import 'admin/staff_reservations_screen.dart';
import 'admin/staff_seats_screen.dart';
import 'admin/staff_waitlist_screen.dart';
import 'admin/widgets/staff_live_states.dart';

/// Staff "Manage" tab: one card per back-office area, each with a live count
/// from [AppState]. Nothing here is sample data.
class StaffManageScreen extends StatelessWidget {
  const StaffManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final loading = staffLoading(state);
    final failed = staffFailed(state) && state.adminReservations.isEmpty;
    final stats = state.dashboardStats;
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
    final seats = state.adminSeats;
    final freeSeats =
        seats.where((s) => s.status == SeatStatus.available).length;
    String v(int n) => loading ? '—' : '$n';

    void open(Widget screen) => AppRoute.push(context, screen);

    return AppScaffold(
      title: 'Manage',
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
                    '$expired reservation${expired == 1 ? '' : 's'} expired without pickup. Follow up with the students.',
              ),
              const SizedBox(height: AppSpacing.base),
            ],
            StaggeredEntrance(
              child: _ManageCard(
                icon: Icons.bookmark_rounded,
                color: AppColors.primary,
                title: 'Reservations',
                subtitle: 'Pickups and seat bookings',
                count: v(active),
                countLabel: 'active',
                onTap: () => open(const StaffReservationsScreen()),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            StaggeredEntrance(
              index: 1,
              child: _ManageCard(
                icon: Icons.hourglass_top_rounded,
                color: AppColors.warning,
                title: 'Waiting list',
                subtitle: 'Students queued for books and seats',
                count: v(stats.waitingCount),
                countLabel: 'waiting',
                onTap: () => open(const StaffWaitlistScreen()),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            StaggeredEntrance(
              index: 2,
              child: _ManageCard(
                icon: Icons.menu_book_rounded,
                color: AppColors.accent,
                title: 'Books',
                subtitle: 'Copies, new titles and edits',
                count: v(state.adminBooks.length),
                countLabel: 'titles',
                onTap: () => open(const StaffBooksScreen()),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            StaggeredEntrance(
              index: 3,
              child: _ManageCard(
                icon: Icons.event_seat_rounded,
                color: AppColors.info,
                title: 'Seats',
                subtitle: 'Availability and releasing desks',
                count: v(freeSeats),
                countLabel: 'free',
                onTap: () => open(const StaffSeatsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManageCard extends StatelessWidget {
  const _ManageCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.countLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String count;
  final String countLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title, $count $countLabel',
      excludeSemantics: true,
      child: SurfaceCard(
        onTap: onTap,
        tint: color.withValues(alpha: 0.12),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            IconBadge(icon: icon, color: color, size: 48),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.title(17, w: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(count,
                    style:
                        AppText.display(26, w: FontWeight.w800, color: color)),
                Text(countLabel, style: AppText.label(12, w: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
