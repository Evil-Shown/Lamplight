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

/// Home — the dark hero dashboard from the Stitch redesign.
///
/// The whole tab sits on a deep navy canvas: avatar header, greeting, the
/// day's session on a blue gradient, dark quick-action tiles, the book
/// waiting for collection, and the noise-level card. The floating nav bar
/// flips to dark glass while this tab is active.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Fixed dark canvas — Home stays dark in both theme modes.
  static const _canvas = Color(0xFF0A0F1E);
  static const _card = Color(0xFF151D33);
  static const _cardBorder = Color(0xFF232D48);

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final booking = state.todayBooking;
    final ready = state.activeReservations.isEmpty
        ? null
        : state.activeReservations.first;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _canvas,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              const _HomeHeader(canvas: _canvas),
              const SizedBox(height: 20),
              if (booking != null)
                _TodaySession(booking: booking)
              else
                const _NoSessionCard(),
              const SizedBox(height: 26),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _DarkSectionLabel('QUICK ACTIONS'),
              ),
              const SizedBox(height: 12),
              const _QuickActions(),
              if (ready != null) ...[
                const SizedBox(height: 26),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: _DarkSectionLabel('READY FOR COLLECTION'),
                      ),
                      PressScale(
                        onTap: () => AppShell.switchTab(context, AppTab.bookings),
                        child: Text(
                          'View shelf',
                          style: AppText.label(
                            12,
                            w: FontWeight.w600,
                            color: const Color(0xFF8FB4FF),
                          ),
                        ),
                      ),
                    ],
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: StaggeredEntrance(
                  index: 3,
                  child: _NoiseLevelCard(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DarkSectionLabel extends StatelessWidget {
  const _DarkSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppText.overline(
        10.5,
        ls: 1.4,
        color: Colors.white.withValues(alpha: 0.45),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.canvas});

  final Color canvas;

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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.aurora,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: AppText.title(14, w: FontWeight.w700,
                      color: AppColors.textInverse),
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
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Home.',
                      style: AppText.display(
                        20,
                        w: FontWeight.w800,
                        ls: -0.4,
                        color: AppColors.textInverse,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              PressScale(
                onTap: () => AppShell.switchTab(context, AppTab.bookings),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.notifications_none_rounded,
                          size: 20, color: Colors.white),
                      if (state.unreadNotifications > 0)
                        Positioned(
                          right: 9,
                          top: 9,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF27171),
                              border: Border.all(
                                  color: HomeScreen._canvas, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppRadii.full),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF34C97B),
                  ),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    'ONLINE CAMPUS · MAIN LIBRARY',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.overline(
                      9.5,
                      ls: 1.2,
                      color: Colors.white.withValues(alpha: 0.60),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Your books, seats and study spots at a glance.',
                  style: AppText.body(
                    13.5,
                    color: Colors.white.withValues(alpha: 0.55),
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

/// The "Today's study session" hero — blue gradient panel per the Stitch
/// design, with facility pills and the starts-in countdown.
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
                  32,
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
            ? const Color(0xFF34C97B).withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(
          color: highlight
              ? const Color(0xFF34C97B).withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: highlight
                ? const Color(0xFF7CE8AB)
                : AppColors.textInverse.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppText.overline(
              9.5,
              ls: 1.0,
              color: highlight
                  ? const Color(0xFF7CE8AB)
                  : AppColors.textInverse.withValues(alpha: 0.85),
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HomeScreen._card,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: HomeScreen._cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryBright.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: const Icon(Icons.event_seat_outlined,
                  size: 20, color: Color(0xFF8FB4FF)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No active session',
                      style: AppText.title(
                          15, w: FontWeight.w600,
                          color: AppColors.textInverse)),
                  const SizedBox(height: 3),
                  Text(
                    'Book a seat to start studying today.',
                    style: AppText.body(
                      12.5,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => AppShell.switchTab(context, AppTab.seats),
              child: const Text(
                'Find a seat',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8FB4FF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The 2x2 quick-action grid on dark glass tiles. QR check-in is the blue
/// gradient tile — the obvious next action.
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
                  tint: const Color(0xFF8FB4FF),
                  onTap: () => AppShell.switchTab(context, AppTab.books),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  index: 1,
                  icon: Icons.event_seat_rounded,
                  label: 'Reserve a seat',
                  caption: 'Smart floor recommendations',
                  tint: const Color(0xFFB5A8FF),
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
                  caption: 'Manage library reservations',
                  tint: const Color(0xFF6FD8E8),
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
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: HomeScreen._card,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: HomeScreen._cardBorder),
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
                      color: tint.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border:
                          Border.all(color: tint.withValues(alpha: 0.22)),
                    ),
                    child: Icon(icon, size: 17, color: tint),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_outward_rounded,
                      size: 14, color: Colors.white.withValues(alpha: 0.30)),
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
                  color: AppColors.textInverse,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                maxLines: 2,
                style: AppText.body(
                  11,
                  color: Colors.white.withValues(alpha: 0.45),
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
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: HomeScreen._card,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: HomeScreen._cardBorder),
          boxShadow: AppShadows.layered(const Color(0xFFD9A441)),
        ),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5B95E).withValues(alpha: 0.16),
                          borderRadius:
                              BorderRadius.circular(AppRadii.full),
                        ),
                        child: Text(
                          'Due $pickupBy',
                          style: AppText.label(
                            10.5,
                            w: FontWeight.w700,
                            color: const Color(0xFFE5B95E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        daysLeft <= 1
                            ? 'Last day!'
                            : '$daysLeft days left',
                        style: AppText.label(
                          10.5,
                          w: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.45),
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
                      color: AppColors.textInverse,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF34C97B),
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
                            color: Colors.white.withValues(alpha: 0.55),
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

/// The quiet-zone noise level card from the Stitch design.
class _NoiseLevelCard extends StatelessWidget {
  const _NoiseLevelCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HomeScreen._card,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: HomeScreen._cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF6FD8E8).withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: const Icon(Icons.graphic_eq_rounded,
                size: 20, color: Color(0xFF6FD8E8)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Silent Room & Study Wing',
                  style: AppText.title(
                    14,
                    w: FontWeight.w700,
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '32 dB · Quiet study zone right now',
                  style: AppText.body(
                    12,
                    color: Colors.white.withValues(alpha: 0.50),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  child: LinearProgressIndicator(
                    value: 0.32,
                    minHeight: 4,
                    backgroundColor:
                        Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF34C97B)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadii.full),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Text(
              'Live',
              style: AppText.label(
                11.5,
                w: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The QR check-in tile — blue gradient, the highest-contrast tile in the
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
                  color: Colors.white.withValues(alpha: 0.62),
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
