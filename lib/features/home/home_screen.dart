import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app_shell.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/mock/mock_data.dart';
import '../../models/models.dart';
import '../qr/qr_ticket_screen.dart';
import '../reservations/reservations_screen.dart';

/// P-01 Home.
///
/// Campus eyebrow and greeting, the day's study session, a quick-action
/// grid, the book waiting for collection, and live per-floor occupancy.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final booking = state.todayBooking;
    final ready = state.activeReservations.isEmpty
        ? null
        : state.activeReservations.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            const _HomeHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                'Computer Science · ${state.reservations.length} active reservations',
                style: AppText.body(13, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 18),
            if (booking != null)
              _TodaySession(booking: booking)
            else
              const _NoSessionCard(),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SectionLabel('Quick actions'),
            ),
            const SizedBox(height: 12),
            const _QuickActions(),
            if (ready != null) ...[
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SectionLabel('Ready for collection'),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StaggeredEntrance(
                  index: 2,
                  child: _ReadyForCollection(reservation: ready),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _DensityHeader(),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _DensityList(),
            ),
          ],
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'UNILAG CAMPUS',
                      style:
                          AppText.overline(11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                StaggeredEntrance(
                  index: 1,
                  child: Text(
                    '$_greeting, ${profile.firstName}',
                    style: AppText.display(24, w: FontWeight.w700, ls: -0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () =>
                    AppShell.switchTab(context, AppTab.bookings),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                ),
                icon: const Icon(Icons.notifications_none_rounded, size: 21),
              ),
              if (state.unreadNotifications > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error,
                      border:
                          Border.all(color: AppColors.surface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The "Today's study session" hero — a gradient panel so the day's
/// booking is the first thing the eye lands on.
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
                      border:
                          Border.all(color: Colors.white.withValues(alpha: 0.28)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
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
                  30,
                  w: FontWeight.w800,
                  ls: -0.9,
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
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 15, color: AppColors.textInverse),
                      const SizedBox(width: 6),
                      Text(
                        time,
                        style: AppText.body(
                          13.5,
                          w: FontWeight.w600,
                          color: AppColors.textInverse,
                        ),
                      ),
                    ],
                  ),
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

class _NoSessionCard extends StatelessWidget {
  const _NoSessionCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SurfaceCard(
        child: Row(
          children: [
            const IconBadge(icon: Icons.event_seat_outlined, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No active session',
                      style: AppText.title(15, w: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text('Book a seat to start studying today.',
                      style: AppText.body(12.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => AppShell.switchTab(context, AppTab.seats),
              child: Text(
                'Find a seat',
                style: AppText.label(
                  13,
                  w: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The 2x2 quick-action grid. QR check-in is the inverted tile, matching
/// the prototype.
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
                  caption: 'Find titles and copies',
                  tint: AppColors.primary,
                  onTap: () => AppShell.switchTab(context, AppTab.books),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  index: 1,
                  icon: Icons.event_seat_rounded,
                  label: 'Reserve a seat',
                  caption: 'Live floor availability',
                  tint: AppColors.accent,
                  onTap: () => AppShell.switchTab(context, AppTab.seats),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  index: 2,
                  icon: Icons.confirmation_number_outlined,
                  label: 'My bookings',
                  caption: 'Books, seats and waits',
                  tint: AppColors.cyan,
                  onTap: () => AppShell.switchTab(context, AppTab.bookings),
                ),
              ),
              const SizedBox(width: 10),
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
    this.tint = AppColors.primary,
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
      child: GlassTile(
        onTap: onTap,
        tint: tint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        tint,
                        Color.alphaBlend(
                            Colors.black.withValues(alpha: 0.16), tint),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    boxShadow: AppShadows.glow(tint),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.textInverse),
                ),
                const Spacer(),
                const Icon(Icons.arrow_outward_rounded,
                    size: 15, color: AppColors.textFaint),
              ],
            ),
            const SizedBox(height: 11),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.title(14, w: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              maxLines: 2,
              style: AppText.body(11.5, color: AppColors.textSecondary,
                  height: 1.35),
            ),
          ],
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

    return SurfaceCard(
      onTap: () => AppShell.switchTab(context, AppTab.bookings),
      tint: AppColors.gold,
      elevated: true,
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
                Text(book.title, style: AppText.title(15, w: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(book.author,
                    style: AppText.body(12.5, color: AppColors.textSecondary)),
                const SizedBox(height: 9),
                Text(
                  'Shelf ${book.shelfLocation} · collect by $pickupBy',
                  style: AppText.body(12, color: AppColors.textFaint),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View reservation',
                        style: AppText.label(
                          12,
                          w: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 14, color: AppColors.primary),
                    ],
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

class _DensityHeader extends StatelessWidget {
  const _DensityHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: SectionLabel('Live library density')),
        const StatusPill(
          label: 'Live',
          color: AppColors.success,
          compact: true,
          pulse: true,
        ),
      ],
    );
  }
}

/// Per-floor occupancy bars. Green under 70%, amber to 90%, red above.
class _DensityList extends StatelessWidget {
  const _DensityList();

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      elevated: true,
      child: Column(
        children: [
          for (var i = 0; i < MockData.floorOccupancy.length; i++) ...[
            if (i > 0) const Divider(height: 20),
            _DensityRow(floor: MockData.floorOccupancy[i], index: i),
          ],
        ],
      ),
    );
  }
}

class _DensityRow extends StatelessWidget {
  const _DensityRow({required this.floor, required this.index});

  final FloorOccupancy floor;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = switch (floor.ratio) {
      < 0.70 => AppColors.success,
      < 0.90 => AppColors.warning,
      _ => AppColors.error,
    };

    return StaggeredEntrance(
      index: index + 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(floor.name,
                    style: AppText.body(13, w: FontWeight.w500)),
              ),
              Text(
                '${floor.occupied}/${floor.capacity}',
                style: AppText.label(
                  12.5,
                  w: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          MeterBar(value: floor.ratio, color: color),
        ],
      ),
    );
  }
}

/// The dark QR tile — deliberately the highest-contrast element in the
/// grid so "check in" is the obvious next action.
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
            gradient: AppGradients.panel,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: AppShadows.glow(AppColors.primary),
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
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border:
                          Border.all(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: const Icon(Icons.qr_code_rounded,
                        size: 19, color: AppColors.textInverse),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_outward_rounded,
                      size: 15, color: AppColors.textFaint),
                ],
              ),
              const SizedBox(height: 11),
              Text(
                'QR check-in',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.title(14, w: FontWeight.w700,
                    color: AppColors.textInverse),
              ),
              const SizedBox(height: 2),
              Text(
                'Open digital pass',
                style: AppText.body(
                  11.5,
                  color: AppColors.textInverse.withValues(alpha: 0.62),
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
