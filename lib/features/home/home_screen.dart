import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../app_shell.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../qr/qr_ticket_screen.dart';
import '../reservations/reservations_screen.dart';

/// Home — a Material 3 dashboard on the tonal surface.
///
/// The header carries the profile avatar and greeting, the day's session
/// sits on the brand aurora sweep, quick actions are tonal cards, and the
/// hold-shelf and noise cards close out the scroll. All colour comes from
/// the seeded scheme, so the tab follows light/dark mode.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final booking = state.todayBooking;
    final ready = state.activeReservations.isEmpty
        ? null
        : state.activeReservations.first;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              // App-level cached-data banner (D-14).
              ConnectivityBanner(lastSyncedAt: state.lastSyncedAt),
              const _HomeHeader(),
              const SizedBox(height: 20),
              if (booking != null)
                _TodaySession(booking: booking)
              else
                const _NoSessionCard(),
              const SizedBox(height: 26),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SectionLabel('Quick actions'),
              ),
              const SizedBox(height: 12),
              const _QuickActions(),
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
                    index: 2,
                    child: _ReadyForCollection(reservation: ready),
                  ),
                ),
              ],
              const SizedBox(height: 26),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StaggeredEntrance(
                  index: 3,
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primarySoft,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: AppText.title(
                    14,
                    w: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CAMPUS COMMONS',
                      style: AppText.overline(
                        10,
                        ls: 1.6,
                        color: AppColors.textFaint,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Main Library · Open',
                      style: AppText.body(
                        13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: () => AppShell.switchTab(context, AppTab.bookings),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceMuted,
                ),
                icon: Badge(
                  isLabelVisible: state.unreadNotifications > 0,
                  child: const Icon(Icons.notifications_none_rounded,
                      size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          StaggeredEntrance(
            index: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting, ${profile.firstName}',
                  style: AppText.display(
                    26,
                    w: FontWeight.w800,
                    ls: -0.7,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Your books, seats and study spots at a glance.',
                  style: AppText.body(
                    13.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The "Today's study session" hero — the brand aurora sweep with
/// facility pills and the starts-in countdown.
class _TodaySession extends StatelessWidget {
  const _TodaySession({required this.booking});

  final SeatBooking booking;

  @override
  Widget build(BuildContext context) {
    final startsIn = booking.startTime.difference(DateTime.now());
    final time =
        '${DateFormat('h:mm a').format(booking.startTime)} – ${DateFormat('h:mm a').format(booking.endTime)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StaggeredEntrance(
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
                        color: AppColors.textInverse.withValues(alpha: 0.78),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28)),
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
                  AppText.displayMd,
                  w: FontWeight.w800,
                  ls: -1.0,
                  color: AppColors.textInverse,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Floor ${booking.seat.floor} · ${booking.seat.section}',
                style: AppText.body(
                  13.5,
                  color: AppColors.textInverse.withValues(alpha: 0.82),
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
                      label: 'FREE POWER',
                      highlight: true,
                    ),
                  const _HeroPill(icon: Icons.wifi_rounded, label: 'FAST WI-FI'),
                  if (booking.seat.nearWindow)
                    const _HeroPill(icon: Icons.wb_sunny_outlined, label: 'DAYLIGHT'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      size: 15, color: AppColors.textInverse),
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
                        color: Colors.white.withValues(alpha: 0.18),
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
            ? Colors.white.withValues(alpha: 0.26)
            : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(
          color: highlight
              ? Colors.white.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.16),
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
              color: AppColors.textInverse.withValues(alpha: 0.90),
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
        child: Row(
          children: [
            IconBadge(
              icon: Icons.event_seat_outlined,
              color: AppColors.primary,
              background: AppColors.infoSoft,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No active session',
                      style: AppText.title(15, w: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(
                    'Book a seat to start studying today.',
                    style: AppText.body(
                      12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => AppShell.switchTab(context, AppTab.seats),
              child: const Text('Find a seat'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The 2x2 quick-action grid. QR check-in is the aurora tile — the
/// obvious next action.
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
                  caption: 'Find titles and shelf locations',
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
      index: index + 4,
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
                    background: Color.alphaBlend(
                        tint.withValues(alpha: 0.14), AppColors.surface),
                    size: 34,
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_outward_rounded,
                      size: 14, color: AppColors.textFaint),
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
              const SizedBox(height: 2),
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
        tint: AppColors.gold.withValues(alpha: 0.30),
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
                          'Ready for pickup · Shelf ${book.shelfLocation}',
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

/// The live-density card. Floor-level only — the seats model has no
/// per-slot occupancy, so the label always says which floor this is and
/// never implies desk-level precision (D-11).
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
      < 0.5 => (AppColors.success, 'Quiet'),
      < 0.8 => (AppColors.warning, 'Filling up'),
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
                  'FLOOR 2 · LIVE DENSITY',
                  style: AppText.overline(10, ls: 1.6,
                      color: AppColors.textFaint),
                ),
              ),
              IconBadge(
                icon: Icons.groups_rounded,
                color: tone,
                background: Color.alphaBlend(
                    tone.withValues(alpha: 0.12), AppColors.surface),
                size: 30,
              ),
            ],
          ),
          const SizedBox(height: 8),
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
              const SizedBox(width: 10),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                      tone.withValues(alpha: 0.12), AppColors.surface),
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
          const SizedBox(height: 8),
          LiveFreshness(lastSyncedAt: lastSyncedAt),
        ],
      ),
    );
  }
}

/// The QR check-in tile — the aurora sweep, the highest-contrast tile in
/// the grid so "check in" is the obvious next action.
class _QrTile extends StatelessWidget {
  const _QrTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StaggeredEntrance(
      index: 7,
      child: PressScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: AppGradients.aurora,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: AppShadows.glow(AppColors.primary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20)),
                    ),
                    child: Icon(Icons.qr_code_rounded,
                        size: 18, color: AppColors.textInverse),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_outward_rounded,
                      size: 14,
                      color: Color.fromRGBO(255, 255, 255, 0.55)),
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
              const SizedBox(height: 2),
              Text(
                'Open digital pass for entry',
                maxLines: 2,
                style: AppText.body(
                  11,
                  color: Colors.white.withValues(alpha: 0.72),
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
