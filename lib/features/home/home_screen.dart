import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app_shell.dart';
import '../../core/feedback/app_feedback.dart';
import '../../core/navigation/app_route.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../notifications/notifications_screen.dart';
import '../reservations/live_widgets.dart';
import '../qr/qr_ticket_screen.dart';

/// Nordic Modern Campus home — greeting, session hero, bento, occupancy.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    if (!state.isHydrated) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppColors.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: syncFailed(state)
                ? syncErrorState(state)
                : const _HomeSkeleton(),
          ),
        ),
      );
    }

    final booking = state.todayBooking;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: refreshable(
            state,
            ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                bottom: AppSpacing.scrollBottomInset,
              ),
              children: [
                ConnectivityBanner(lastSyncedAt: state.lastSyncedAt),
                const StaggeredEntrance(child: _HomeGreeting()),
                const SizedBox(height: AppSpacing.lg),
                if (state.pendingOffers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenMargin,
                    ),
                    child: OfferStack(offers: state.pendingOffers),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenMargin,
                  ),
                  child: StaggeredEntrance(
                    index: 1,
                    child: booking != null
                        ? _SessionHero(booking: booking)
                        : const _EmptySessionHero(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenMargin,
                  ),
                  child: StaggeredEntrance(index: 2, child: _HomeBento()),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenMargin,
                  ),
                  child: StaggeredEntrance(
                    index: 3,
                    child: _OccupancyMeter(lastSyncedAt: state.lastSyncedAt),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeGreeting extends StatelessWidget {
  const _HomeGreeting();

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final profile = state.activeProfile;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.md,
        AppSpacing.screenMargin,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Campus library · open',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _greeting(),
                  style: AppText.body(
                    15,
                    w: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  profile.firstName,
                  style: AppText.title(32, w: FontWeight.w800, ls: -0.8),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Semantics(
            button: true,
            label: state.unreadCount > 0
                ? 'Notifications, ${state.unreadCount} unread'
                : 'Notifications',
            excludeSemantics: true,
            child: PressScale(
              onTap: () {
                AppFeedback.tap();
                AppRoute.push(context, const NotificationsScreen());
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppGlass.cardFill,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppGlass.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppGlass.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Badge(
                  isLabelVisible: state.unreadCount > 0,
                  label: Text(
                      state.unreadCount > 9 ? '9+' : '${state.unreadCount}'),
                  backgroundColor: AppColors.error,
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: 23,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionHero extends StatelessWidget {
  const _SessionHero({required this.booking});

  final SeatBooking booking;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final demo = state.dataSource == DataSource.demo;

    return DepthHero(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Today\'s study session',
                  style: AppText.body(
                    14,
                    color: AppColors.textInverse.withValues(alpha: 0.9),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.textInverse.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: LiveClock(
                  period: const Duration(seconds: 15),
                  builder: (context, now) {
                    final endsIn = booking.endTime.difference(now);
                    return Text(
                      endsIn.isNegative
                          ? 'Session ended'
                          : '${formatRemaining(endsIn)} left',
                      style: AppText.label(
                        12,
                        w: FontWeight.w700,
                        color: AppColors.textInverse,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.textInverse.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigo.withValues(alpha: 0.45),
                      blurRadius: 16,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Text(
                  'Seat ${booking.seat.label}',
                  style: AppText.title(
                    20,
                    w: FontWeight.w700,
                    color: AppColors.textInverse,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Floor ${booking.seat.floor} · ${booking.seat.section}',
            style: AppText.body(
              13,
              color: AppColors.textInverse.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: CountdownBadge(
              prefix: 'Check in within',
              onGradient: true,
              remaining: (now) => state.graceRemaining(booking, now: now),
            ),
          ),
          if (!demo && booking.checkedInAt == null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Show this QR at the desk to check in.',
              style: AppText.body(
                12.5,
                color: AppColors.textInverse.withValues(alpha: 0.88),
              ),
            ),
          ],
          const SizedBox(height: 18),
          _HeroButton(
            label: 'View QR ticket',
            icon: Icons.qr_code_2_rounded,
            onTap: () => AppRoute.push(
              context,
              QrTicketScreen(booking: booking),
            ),
          ),
        ],
      ),
    );
  }
}

/// White pill on the hero gradient: the one primary action of the screen.
class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () {
        AppFeedback.tap();
        onTap();
      },
      child: Container(
        height: 52,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.textInverse,
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label(
                  15,
                  w: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_rounded,
                size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _EmptySessionHero extends StatelessWidget {
  const _EmptySessionHero();

  @override
  Widget build(BuildContext context) {
    return DepthHero(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No session today',
            style: AppText.title(
              20,
              w: FontWeight.w600,
              color: AppColors.textInverse,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Reserve a quiet seat on Floor 2 in under a minute.',
            style: AppText.body(
              14,
              color: AppColors.textInverse.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 18),
          _HeroButton(
            label: 'Book a seat',
            icon: Icons.event_seat_rounded,
            onTap: () => AppShell.switchTab(context, AppTab.seats),
          ),
        ],
      ),
    );
  }
}

class _HomeBento extends StatelessWidget {
  const _HomeBento();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick actions', style: AppText.title(20, w: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: BentoTile(
                icon: Icons.event_seat_rounded,
                label: 'Seats',
                tint: AppColors.primary,
                onTap: () => AppShell.switchTab(context, AppTab.seats),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: BentoTile(
                icon: Icons.menu_book_rounded,
                label: 'Books',
                tint: AppColors.indigo,
                onTap: () => AppShell.switchTab(context, AppTab.books),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: BentoTile(
                icon: Icons.confirmation_number_rounded,
                label: 'Bookings',
                tint: AppColors.cyan,
                onTap: () => AppShell.switchTab(context, AppTab.bookings),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: BentoTile(
                icon: Icons.qr_code_2_rounded,
                label: 'QR pass',
                tint: AppColors.textSecondary,
                onTap: () => _openQr(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openQr(BuildContext context) {
    final booking = AppScope.read(context).todayBooking;
    if (booking == null) {
      AppShell.switchTab(context, AppTab.bookings);
      return;
    }
    AppRoute.push(context, QrTicketScreen(booking: booking));
  }
}

class _OccupancyMeter extends StatelessWidget {
  const _OccupancyMeter({required this.lastSyncedAt});

  final DateTime? lastSyncedAt;

  @override
  Widget build(BuildContext context) {
    final seats =
        AppScope.of(context).seats.where((s) => s.floor == 2).toList();
    final total = seats.length;
    final occupied = seats.where((s) => s.status == SeatStatus.occupied).length;
    final ratio = total == 0 ? 0.0 : occupied / total;

    final label = switch (ratio) {
      < 0.5 => 'Quiet',
      < 0.8 => 'Busy',
      _ => 'Full',
    };

    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Floor 2 occupancy',
                style: AppText.title(17, w: FontWeight.w700),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (ratio < 0.5
                          ? AppColors.success
                          : ratio < 0.8
                              ? AppColors.warning
                              : AppColors.error)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(
                  label,
                  style: AppText.label(
                    11.5,
                    w: FontWeight.w700,
                    color: ratio < 0.5
                        ? AppColors.success
                        : ratio < 0.8
                            ? AppColors.warning
                            : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Segment(active: ratio < 0.5, color: AppColors.success),
              const SizedBox(width: 6),
              _Segment(
                  active: ratio >= 0.5 && ratio < 0.8,
                  color: AppColors.warning),
              const SizedBox(width: 6),
              _Segment(active: ratio >= 0.8, color: AppColors.error),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                label,
                style: AppText.title(15, w: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${(ratio * 100).round()}% seated',
                style: AppText.body(13, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LiveFreshness(lastSyncedAt: lastSyncedAt),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.active, required this.color});

  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: AppMotion.fast,
        height: 10,
        decoration: BoxDecoration(
          color: active ? color : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadii.full),
        ),
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Skeleton(height: 56, radius: AppRadii.card),
        SizedBox(height: 20),
        Skeleton(height: 180, radius: AppRadii.xl),
        SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Skeleton(height: 96, radius: AppRadii.card)),
            SizedBox(width: 12),
            Expanded(child: Skeleton(height: 96, radius: AppRadii.card)),
          ],
        ),
      ],
    );
  }
}
