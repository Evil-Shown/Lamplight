import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app_shell.dart';
import '../../core/navigation/app_route.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../notifications/notifications_screen.dart';
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
          backgroundColor: AppColors.background,
          body: const SafeArea(bottom: false, child: _HomeSkeleton()),
        ),
      );
    }

    final booking = state.todayBooking;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(
              bottom: AppSpacing.scrollBottomInset,
            ),
            children: [
              ConnectivityBanner(lastSyncedAt: state.lastSyncedAt),
              const _HomeGreeting(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: booking != null
                    ? _SessionHero(booking: booking)
                    : const _EmptySessionHero(),
              ),
              const SizedBox(height: 22),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _HomeBento(),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _OccupancyMeter(lastSyncedAt: state.lastSyncedAt),
              ),
            ],
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
    final parts = profile.name.trim().split(RegExp(r'\s+'));
    final initials = parts
        .take(2)
        .map((p) => p.isNotEmpty ? p[0] : '')
        .join()
        .toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.brand,
              boxShadow: AppShadows.ambient,
            ),
            alignment: Alignment.center,
            child: Text(
              initials.isEmpty ? 'SL' : initials,
              style: AppText.title(15, w: FontWeight.w700, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
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
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Campus library · open',
                      style: AppText.body(12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${_greeting()}, ${profile.firstName}',
                  style: AppText.title(22, w: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: () => AppRoute.push(
              context,
              const NotificationsScreen(),
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: Badge(
              isLabelVisible: state.unreadNotifications > 0,
              backgroundColor: AppColors.error,
              child: const Icon(Icons.notifications_none_rounded, size: 22),
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
    final endsIn = booking.endTime.difference(DateTime.now());
    final countdown = endsIn.isNegative
        ? 'Session ended'
        : endsIn.inHours > 0
            ? '${endsIn.inHours}h ${endsIn.inMinutes % 60}m left'
            : '${endsIn.inMinutes}m left';

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
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(
                  countdown,
                  style: AppText.label(
                    12,
                    w: FontWeight.w700,
                    color: AppColors.textInverse,
                  ),
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
                  color: Colors.white.withValues(alpha: 0.2),
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
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => AppRoute.push(
              context,
              QrTicketScreen(booking: booking),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('View QR ticket'),
          ),
        ],
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
          FilledButton(
            onPressed: () => AppShell.switchTab(context, AppTab.seats),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Book a seat'),
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
        Text('Quick actions', style: AppText.title(17, w: FontWeight.w600)),
        const SizedBox(height: 12),
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
            const SizedBox(width: 12),
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
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: BentoTile(
                icon: Icons.confirmation_number_rounded,
                label: 'Bookings',
                tint: AppColors.amberHighlight,
                onTap: () => AppShell.switchTab(context, AppTab.bookings),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BentoTile(
                icon: Icons.qr_code_2_rounded,
                label: 'QR pass',
                tint: const Color(0xFF64748B),
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
    final occupied =
        seats.where((s) => s.status == SeatStatus.occupied).length;
    final ratio = total == 0 ? 0.0 : occupied / total;

    final label = switch (ratio) {
      < 0.5 => 'Quiet',
      < 0.8 => 'Busy',
      _ => 'Full',
    };

    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Floor 2 occupancy',
            style: AppText.title(16, w: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Segment(active: ratio < 0.5, color: AppColors.success),
              const SizedBox(width: 6),
              _Segment(active: ratio >= 0.5 && ratio < 0.8, color: AppColors.warning),
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
