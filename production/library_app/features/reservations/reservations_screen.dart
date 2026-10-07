import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../books/reservation_cancelled_screen.dart';
import '../books/reservation_detail_screen.dart';
import '../qr/qr_ticket_screen.dart';
import '../waitlist/waitlist_joined_screen.dart';

/// P-10 My Reservations, folding in the container-2 list variant.
///
/// Three tabs over one screen: book holds, seat bookings, and waitlist
/// entries — all read live from [AppState] so a reservation made anywhere
/// in the app shows up here immediately.
class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  String _tab = 'Books';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Reservations',
                        style:
                            AppText.display(22, w: FontWeight.w700, ls: -0.4)),
                    const SizedBox(height: 3),
                    Text(
                      'Books and reading-room seats',
                      style: AppText.body(13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            SegmentedTabs(
              options: const ['Books', 'Seats', 'Waiting'],
              selected: _tab,
              onSelected: (value) => setState(() => _tab = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: switch (_tab) {
                'Books' => _BookHolds(reservations: state.activeReservations),
                'Seats' => _SeatBookings(bookings: state.bookings),
                _ => _WaitlistEntries(entries: state.waitlist),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BookHolds extends StatelessWidget {
  const _BookHolds({required this.reservations});

  final List<BookReservation> reservations;

  @override
  Widget build(BuildContext context) {
    if (reservations.isEmpty) {
      return EmptyState(
        icon: Icons.bookmark_border_rounded,
        title: 'No active holds',
        message:
            'Search the catalog and reserve a book to see it listed here.',
        actionLabel: 'Browse books',
        onAction: () => Navigator.of(context).pop(),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      itemCount: reservations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => StaggeredEntrance(
        index: i,
        child: _BookHoldCard(reservation: reservations[i]),
      ),
    );
  }
}

class _BookHoldCard extends StatelessWidget {
  const _BookHoldCard({required this.reservation});

  final BookReservation reservation;

  @override
  Widget build(BuildContext context) {
    final book = reservation.book;
    final pickupBy = DateFormat('d MMM').format(reservation.pickupBy);

    return SurfaceCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReservationDetailScreen(reservation: reservation),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(
                title: book.title,
                color: book.coverColor,
                isbn: book.isbn,
                width: 52,
                height: 74,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title,
                        style: AppText.title(15.5, w: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      style: AppText.body(12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 9),
                    StatusPill(
                      label: reservation.status == ReservationStatus.ready
                          ? 'Ready for pickup'
                          : 'Active',
                      color: reservation.status == ReservationStatus.ready
                          ? AppColors.success
                          : AppColors.primary,
                      compact: true,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.textFaint),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 15, color: AppColors.textFaint),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Shelf ${book.shelfLocation}  ·  Pickup by $pickupBy',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(12.5, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeatBookings extends StatelessWidget {
  const _SeatBookings({required this.bookings});

  final List<SeatBooking> bookings;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const EmptyState(
        icon: Icons.event_seat_outlined,
        title: 'No active seat bookings',
        message: 'Reserve a reading-room seat and it will appear here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) =>
          StaggeredEntrance(index: i, child: _SeatBookingCard(booking: bookings[i])),
    );
  }
}

class _SeatBookingCard extends StatelessWidget {
  const _SeatBookingCard({required this.booking});

  final SeatBooking booking;

  @override
  Widget build(BuildContext context) {
    final time =
        '${DateFormat('h:mm a').format(booking.startTime)} – ${DateFormat('h:mm a').format(booking.endTime)}';

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Seat ${booking.seat.label} · ${booking.seat.section}',
                        style: AppText.title(15.5, w: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(
                      'Floor ${booking.seat.floor} · $time',
                      style:
                          AppText.body(12.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Booking ID ${booking.id}',
                      style: AppText.body(12, color: AppColors.textFaint),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: 'Active',
                color: AppColors.success,
                compact: true,
                pulse: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'View QR',
                  icon: Icons.qr_code_rounded,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QrTicketScreen(booking: booking),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: 'Cancel',
                  tone: ButtonTone.secondary,
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Cancel this seat?'),
                        content: Text(
                          'Seat ${booking.seat.label} will be released and '
                          'offered to the next person waiting.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: const Text('Keep booking'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: const Text('Cancel booking'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true || !context.mounted) return;
                    AppScope.read(context).cancelSeatBooking(booking.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Seat ${booking.seat.label} booking cancelled',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaitlistEntries extends StatelessWidget {
  const _WaitlistEntries({required this.entries});

  final List<WaitlistEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const EmptyState(
        icon: Icons.hourglass_empty_rounded,
        title: 'Not waiting on anything',
        message:
            'Join a waitlist for a full book or seat and track your place here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) =>
          StaggeredEntrance(index: i, child: _WaitlistCard(entry: entries[i])),
    );
  }
}

class _WaitlistCard extends StatelessWidget {
  const _WaitlistCard({required this.entry});

  final WaitlistEntry entry;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WaitlistJoinedScreen(entry: entry),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const IconBadge(icon: Icons.hourglass_top_rounded, size: 46),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.title,
                        style: AppText.title(15, w: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(entry.subtitle,
                        style:
                            AppText.body(12.5, color: AppColors.textSecondary)),
                    if (entry.estimatedWaitMinutes != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Estimated wait ~${entry.estimatedWaitMinutes} min',
                        style: AppText.body(12, color: AppColors.textFaint),
                      ),
                    ],
                  ],
                ),
              ),
              CountUp(
                value: entry.position,
                style: AppText.display(
                  24,
                  w: FontWeight.w800,
                  color: AppColors.primary,
                ),
                prefix: '#',
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => AppScope.read(context).leaveWaitlist(entry.id),
              child: Text(
                'Leave queue',
                style: AppText.label(13,
                    w: FontWeight.w600, color: AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Navigates to the cancelled-receipt screen after a cancel is confirmed.
void openReservationCancelled(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const ReservationCancelledScreen(),
    ),
  );
}
