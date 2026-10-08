import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import 'staff_books_screen.dart';
import 'staff_mock_data.dart';
import 'staff_reservations_screen.dart';
import 'staff_role_gate.dart';
import 'staff_seats_screen.dart';
import 'staff_waitlist_screen.dart';
import 'widgets/staff_quick_action.dart';
import 'widgets/staff_stat_card.dart';
import 'widgets/staff_status_badge.dart';

/// Landing screen for library staff: today's summary, quick navigation and
/// the pickups that need attention next.
class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());
    final expired = StaffMockData.expiredReservationCount;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _StaffHeader(date: today)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppNavInset.bottom),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (expired > 0) ...[
                    AlertBanner(
                      tone: AlertTone.danger,
                      icon: Icons.warning_amber_rounded,
                      message:
                          '$expired reservation${expired == 1 ? '' : 's'} expired without pickup — follow up with the students.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const _StatsSection(),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Quick actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const _QuickActions(),
                  const SizedBox(height: AppSpacing.lg),
                  const _DueNextSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffHeader extends StatelessWidget {
  const _StaffHeader({required this.date});

  String get _brandLabel => '${AppStrings.appName} · Staff';

  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F3D2E),
            Color(0xFF1B5E45),
            Color(0xFF2D6A4F),
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned(right: -52, top: -40, child: _circle(180, 0.07)),
          Positioned(left: -44, bottom: -64, child: _circle(170, 0.06)),
          Positioned(right: 52, bottom: -34, child: _circle(96, 0.05)),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              MediaQuery.paddingOf(context).top + AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_library_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _brandLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Exit staff view',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.logout_rounded),
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const StaffRoleGate()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Staff Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                Text(
                  date,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Icon(Icons.badge_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          StaffMockData.staffName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${StaffMockData.staffRole} · ${StaffMockData.staffId}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) {
    void openReservations(String filter) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                StaffReservationsScreen(initialFilter: filter),
          ),
        );

    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 640 ? 4 : 2;
      return GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisExtent: 138,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StaffWaitlistScreen()),
            ),
          ),
          StaffStatCard(
            icon: Icons.event_seat_rounded,
            value: '${StaffMockData.availableSeatCount}',
            label: 'Available Seats',
            color: AppColors.info,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StaffSeatsScreen()),
            ),
          ),
        ],
      );
    });
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StaffQuickAction(
            icon: Icons.bookmark_rounded,
            label: 'Reservations',
            color: AppColors.primary,
            badge: StaffMockData.activeReservationCount,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const StaffReservationsScreen()),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StaffQuickAction(
            icon: Icons.hourglass_top_rounded,
            label: 'Waiting\nList',
            color: AppColors.warning,
            badge: StaffMockData.waitlistCount,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StaffWaitlistScreen()),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StaffQuickAction(
            icon: Icons.menu_book_rounded,
            label: 'Book\nAvailability',
            color: AppColors.secondary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StaffBooksScreen()),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StaffQuickAction(
            icon: Icons.event_seat_rounded,
            label: 'Seat\nAvailability',
            color: AppColors.info,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StaffSeatsScreen()),
            ),
          ),
        ),
      ],
    );
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
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const StaffReservationsScreen()),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (dueNext.isEmpty)
          const SoftCard(
            child: Text(
              'No active reservations right now.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ...dueNext.take(3).map(
                (r) => SoftCard(
                  elevated: true,
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const StaffReservationsScreen()),
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
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${r.itemTitle} · ${r.studentId}',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13),
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
