import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app_shell.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/motion3d.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../qr/qr_ticket_screen.dart';
import '../reservations/reservations_screen.dart';

/// Redesigned Home Screen â€” A modern, elegant dashboard for SLIIT Campus Library.
///
/// Features:
/// - Personalized header with initial avatar, live greeting & notifications.
/// - Integrated quick-search banner bar.
/// - Hero study session banner (Aurora sweep with countdown & facility pills).
/// - Campus live metrics summary chips.
/// - 2x2 quick action grid with vibrant icons & QR pass entry.
/// - "Ready for collection" hold-shelf showcase.
/// - Real-time floor occupancy gauge & live density meter.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final booking = state.todayBooking;
    final ready = state.activeReservations.isEmpty
        ? null
        : state.activeReservations.first;

    // S02 loading: a skeleton of the real layout until the first
    // snapshot lands (or the offline fallback releases it).
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              // Connectivity Sync Banner
              ConnectivityBanner(lastSyncedAt: state.lastSyncedAt),

              // Header Section
              const _HomeHeader(),

              const SizedBox(height: 16),

              // Search Bar Entry Point
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StaggeredEntrance(
                  index: 0,
                  child: _SearchBarCard(),
                ),
              ),

              const SizedBox(height: 20),

              // Today's Session Hero or Quick Seat Booking Prompt
              if (booking != null)
                _TodaySession(booking: booking)
              else
                const _NoSessionCard(),

              const SizedBox(height: 24),

              // Live Campus Overview Pills
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: StaggeredEntrance(
                  index: 1,
                  child: _CampusOverviewPills(),
                ),
              ),

              const SizedBox(height: 24),

              // Quick Actions Section Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SectionLabel('Quick actions'),
              ),
              const SizedBox(height: 12),
              const _QuickActions(),

              // Ready for Collection Shelf
              if (ready != null) ...[
                const SizedBox(height: 26),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SectionHeader(
                    title: 'Ready for collection',
                    actionLabel: 'View shelf',
                    onAction: () => AppShell.switchTab(context, AppTab.bookings),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StaggeredEntrance(
                    index: 5,
                    child: _ReadyForCollection(reservation: ready),
                  ),
                ),
              ],

              const SizedBox(height: 26),

              // Live Density Gauge
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StaggeredEntrance(
                  index: 6,
                  child: _DensityCard(lastSyncedAt: state.lastSyncedAt),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Personalized header with profile avatar, greeting, and notification button.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final profile = state.activeProfile;
    final nameParts = profile.name.trim().split(RegExp(r'\s+'));
    final initials = nameParts
        .take(2)
        .map((part) => part.isNotEmpty ? part[0] : '')
        .join()
        .toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initials.isEmpty ? 'SL' : initials,
                  style: AppText.title(
                    14,
                    w: FontWeight.w800,
                    color: Colors.white,
                  ),
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
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'SLIIT MAIN LIBRARY â€¢ OPEN',
                            style: AppText.overline(
                              9.5,
                              ls: 1.0,
                              color: AppColors.primary,
                              w: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_greeting, ${profile.firstName} Ã°Å¸â€˜â€¹',
                      style: AppText.display(
                        19,
                        w: FontWeight.w800,
                        ls: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () => AppShell.switchTab(context, AppTab.bookings),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
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
        ],
      ),
    );
  }
}

/// Interactive Search Bar that navigates to the Books tab.
class _SearchBarCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppShell.switchTab(context, AppTab.books),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search books, authors, or study podsâ€¦',
                style: AppText.body(
                  13,
                  color: AppColors.textFaint,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.tune_rounded, size: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick live status pills summarizing library status.
class _CampusOverviewPills extends StatelessWidget {
  const _CampusOverviewPills();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final totalBooks = state.books.length;
    final totalReservations = state.reservations.length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _MetricPill(
            icon: Icons.menu_book_rounded,
            value: '$totalBooks',
            label: 'Books Catalog',
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          _MetricPill(
            icon: Icons.event_seat_rounded,
            value: 'Floor 2',
            label: 'Quiet Study',
            color: AppColors.success,
          ),
          const SizedBox(width: 10),
          _MetricPill(
            icon: Icons.bookmark_added_rounded,
            value: '$totalReservations',
            label: 'Active Holds',
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppText.label(12, w: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: AppText.body(9.5, color: AppColors.textFaint),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Today's study session hero card.
class _TodaySession extends StatelessWidget {
  const _TodaySession({required this.booking});

  final SeatBooking booking;

  @override
  Widget build(BuildContext context) {
    final startsIn = booking.startTime.difference(DateTime.now());
    final time =
        '${DateFormat('h:mm a').format(booking.startTime)} â€“ ${DateFormat('h:mm a').format(booking.endTime)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StaggeredEntrance(
        child: Tilt3D(
          maxTilt: 0.07,
          child: GradientHero(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "TODAY'S STUDY SESSION",
                      style: AppText.overline(
                        10.5,
                        ls: 1.6,
                        color: AppColors.textInverse.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.textInverse,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Confirmed',
                          style: AppText.label(
                            11,
                            w: FontWeight.w700,
                            color: AppColors.textInverse,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Seat ${booking.seat.label}',
                style: AppText.display(
                  28,
                  w: FontWeight.w800,
                  ls: -0.8,
                  color: AppColors.textInverse,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Floor ${booking.seat.floor} Â· ${booking.seat.section}',
                style: AppText.body(
                  13.5,
                  color: AppColors.textInverse.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (booking.seat.hasPowerOutlet)
                    const _HeroPill(
                      icon: Icons.bolt_rounded,
                      label: 'POWER OUTLET',
                      highlight: true,
                    ),
                  const _HeroPill(icon: Icons.wifi_rounded, label: 'HIGH-SPEED WI-FI'),
                  if (booking.seat.nearWindow)
                    const _HeroPill(icon: Icons.wb_sunny_outlined, label: 'NATURAL LIGHT'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 16, color: AppColors.textInverse),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      time,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        13.5,
                        w: FontWeight.w600,
                        color: AppColors.textInverse,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (startsIn.inMinutes > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(AppRadii.full),
                      ),
                      child: Text(
                        'Starts in ${startsIn.inMinutes}m',
                        style: AppText.label(
                          11.5,
                          w: FontWeight.w600,
                          color: AppColors.textInverse,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label, this.highlight = false});

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.white.withValues(alpha: 0.28)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(
          color: highlight
              ? Colors.white.withValues(alpha: 0.50)
              : Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppColors.textInverse,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppText.overline(
              9.5,
              ls: 1.0,
              color: AppColors.textInverse.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoSessionCard extends StatelessWidget {
  const _NoSessionCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SurfaceCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconBadge(
              icon: Icons.event_seat_outlined,
              color: AppColors.primary,
              background: AppColors.primarySoft,
              size: 42,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No active study session',
                      style: AppText.title(15, w: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    'Book a quiet seat or group pod to start studying today.',
                    style: AppText.body(
                      12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => AppShell.switchTab(context, AppTab.seats),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Find Seat',
                style: AppText.label(12.5, w: FontWeight.w700, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The 2x2 quick-action grid.
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  index: 0,
                  icon: Icons.search_rounded,
                  label: 'Search books',
                  caption: 'Find titles & shelf locations',
                  tint: AppColors.primary,
                  onTap: () => AppShell.switchTab(context, AppTab.books),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionTile(
                  index: 1,
                  icon: Icons.event_seat_rounded,
                  label: 'Reserve a seat',
                  caption: 'Smart floor recommendations',
                  tint: AppColors.accent,
                  onTap: () => AppShell.switchTab(context, AppTab.seats),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  index: 2,
                  icon: Icons.confirmation_number_outlined,
                  label: 'My bookings',
                  caption: 'Manage library reservations',
                  tint: AppColors.gold,
                  onTap: () => AppShell.switchTab(context, AppTab.bookings),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QrTile(
                  onTap: () => _openQr(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openQr(BuildContext context) {
    final booking = AppScope.read(context).todayBooking;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => booking == null
            ? const ReservationsScreen()
            : QrTicketScreen(booking: booking),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.index,
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
    required this.tint,
  });

  final int index;
  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return StaggeredEntrance(
      index: index + 2,
      child: PressScale(
        onTap: onTap,
        child: SurfaceCard(
          color: AppColors.surface,
          radius: AppRadii.lg,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconBadge(
                    icon: icon,
                    color: tint,
                    background: tint.withValues(alpha: 0.12),
                    size: 36,
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_outward_rounded,
                      size: 15, color: AppColors.textFaint),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.title(
                  13.5,
                  w: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                caption,
                maxLines: 2,
                style: AppText.body(
                  11,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The book waiting on the hold shelf, with its pickup deadline.
class _ReadyForCollection extends StatelessWidget {
  const _ReadyForCollection({required this.reservation});

  final BookReservation reservation;

  @override
  Widget build(BuildContext context) {
    final book = reservation.book;
    final pickupBy = DateFormat('d MMM').format(reservation.pickupBy);
    final daysLeft = reservation.pickupBy.difference(DateTime.now()).inDays;

    return PressScale(
      onTap: () => AppShell.switchTab(context, AppTab.bookings),
      child: SurfaceCard(
        padding: const EdgeInsets.all(14),
        tint: AppColors.gold.withValues(alpha: 0.25),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(
              title: book.title,
              color: book.coverColor,
              isbn: book.isbn,
              width: 44,
              height: 62,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusPill(
                        label: 'Due $pickupBy',
                        color: AppColors.gold,
                        background: AppColors.goldSoft,
                        compact: true,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        daysLeft <= 1
                            ? 'Last day!'
                            : '$daysLeft days left',
                        style: AppText.label(
                          10.5,
                          w: FontWeight.w600,
                          color: AppColors.textFaint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title(
                      14.5,
                      w: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Ready for pickup Â· Shelf ${book.shelfLocation}',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Real-time floor occupancy and density gauge.
class _DensityCard extends StatelessWidget {
  const _DensityCard({required this.lastSyncedAt});

  final DateTime? lastSyncedAt;

  @override
  Widget build(BuildContext context) {
    final seats = AppScope.of(context)
        .seats
        .where((seat) => seat.floor == 2)
        .toList();
    final total = seats.length;
    final occupied = seats.where((s) => s.status == SeatStatus.occupied).length;
    final ratio = total == 0 ? 0.0 : occupied / total;

    final (tone, toneLabel) = switch (ratio) {
      < 0.5 => (AppColors.success, 'Quiet Zone'),
      < 0.8 => (AppColors.warning, 'Filling Up'),
      _ => (AppColors.error, 'Busy'),
    };

    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'FLOOR 2 â€¢ LIVE DENSITY GAUGE',
                  style: AppText.overline(10, ls: 1.4,
                      color: AppColors.textFaint, w: FontWeight.w700),
                ),
              ),
              IconBadge(
                icon: Icons.groups_rounded,
                color: tone,
                background: tone.withValues(alpha: 0.12),
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              CountUp(
                value: (ratio * 100).round(),
                suffix: '%',
                style: AppText.display(
                  28,
                  w: FontWeight.w800,
                  ls: -0.8,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(
                  toneLabel,
                  style: AppText.label(
                    11.5,
                    w: FontWeight.w700,
                    color: tone,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MeterBar(value: ratio, color: tone, height: 8),
          const SizedBox(height: 10),
          LiveFreshness(lastSyncedAt: lastSyncedAt),
        ],
      ),
    );
  }
}

/// The QR check-in tile â€” high contrast tile in the grid for quick check-in.
class _QrTile extends StatelessWidget {
  const _QrTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StaggeredEntrance(
      index: 5,
      child: Tilt3D(
        maxTilt: 0.12,
        child: PressScale(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              borderRadius: BorderRadius.circular(AppRadii.lg),
            ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Icon(Icons.qr_code_rounded,
                        size: 18, color: AppColors.textInverse),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_outward_rounded,
                      size: 15,
                      color: Color.fromRGBO(255, 255, 255, 0.70)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'QR check-in',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.title(
                  13.5,
                  w: FontWeight.w700,
                  color: AppColors.textInverse,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Open digital pass for entry',
                maxLines: 2,
                style: AppText.body(
                  11,
                  color: Colors.white.withValues(alpha: 0.80),
                  height: 1.35,
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

/// S02 loading skeleton â€” the same geometry as the real home screen:
/// header, hero block, overview pills, the 2x2 action grid, meter.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      children: const [
        // Header: avatar + two text lines + bell.
        Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            children: [
              Skeleton(width: 44, height: 44, radius: 22),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(width: 110, height: 10, radius: AppRadii.full),
                    SizedBox(height: 7),
                    Skeleton(width: 190, height: 16, radius: AppRadii.full),
                  ],
                ),
              ),
              Skeleton(width: 40, height: 40, radius: AppRadii.sm),
            ],
          ),
        ),
        SizedBox(height: 20),
        // Search field.
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Skeleton(height: 50, radius: AppRadii.full),
        ),
        SizedBox(height: 20),
        // Hero block.
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Skeleton(height: 190, radius: AppRadii.xl),
        ),
        SizedBox(height: 24),
        // Overview pills.
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: Skeleton(height: 58, radius: 14)),
              SizedBox(width: 10),
              Expanded(child: Skeleton(height: 58, radius: 14)),
              SizedBox(width: 10),
              Expanded(child: Skeleton(height: 58, radius: 14)),
            ],
          ),
        ),
        SizedBox(height: 24),
        // Quick-action grid.
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(width: 110, height: 10, radius: AppRadii.full),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Skeleton(height: 96, radius: AppRadii.lg),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Skeleton(height: 96, radius: AppRadii.lg),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Skeleton(height: 96, radius: AppRadii.lg),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Skeleton(height: 96, radius: AppRadii.lg),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 26),
        // Density meter.
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 140, height: 10, radius: AppRadii.full),
                SizedBox(height: 12),
                Skeleton(width: 84, height: 24, radius: AppRadii.full),
                SizedBox(height: 12),
                Skeleton(height: 8, radius: AppRadii.full),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
