import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app_shell.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../books/reservation_cancelled_screen.dart';
import '../books/reservation_detail_screen.dart';
import '../qr/qr_ticket_screen.dart';
import '../waitlist/waitlist_joined_screen.dart';

/// P-10 My Reservations.
///
/// Two resource tabs — Books | Seats — each with a status filter chip row
/// (Active · Waiting · History). Waitlist entries live under their own
/// resource's Waiting filter rather than being a third peer tab (D-05).
/// Everything reads live from [AppState] so a reservation made anywhere
/// in the app shows up here immediately.
class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  String _tab = 'Books';
  String _filter = 'Active';

  static const _filters = ['Active', 'Waiting', 'History'];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isBooks = _tab == 'Books';

    // Resolve the current tab + filter into a concrete list (D-05).
    final Widget content;    if (isBooks) {
      content = switch (_filter) {
        'Waiting' => _WaitlistEntries(
            entries: state.waitlist
                .where((e) => e.type == WaitlistType.book)
                .toList(),
          ),
        'History' => _BookHolds(
            reservations: state.reservationHistory,
            history: true,
          ),
        _ => _BookHolds(reservations: state.activeReservations),
      };
    } else {
      content = switch (_filter) {
        'Waiting' => _WaitlistEntries(
            entries: state.waitlist
                .where((e) => e.type == WaitlistType.seat)
                .toList(),
          ),
        'History' => _SeatBookings(
            bookings: state.bookings
                .where((b) => b.status != ReservationStatus.active)
                .toList(),
            history: true,
          ),
        _ => _SeatBookings(
            bookings: state.bookings
                .where((b) => b.status == ReservationStatus.active)
                .toList(),
          ),
      };
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // App-level cached-data banner (D-14).
            ConnectivityBanner(lastSyncedAt: state.lastSyncedAt),
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
              options: const ['Books', 'Seats'],
              selected: _tab,
              onSelected: (value) {
                Haptics.selection();
                setState(() {
                  _tab = value;
                  _filter = 'Active';
                });
              },
            ),
            const SizedBox(height: 12),
            FilterChipRow(
              options: _filters,
              selected: _filter,
              onSelected: (value) {
                Haptics.selection();
                setState(() => _filter = value);
              },
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            const SizedBox(height: 16),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

class _BookHolds extends StatelessWidget {
  const _BookHolds({required this.reservations, this.history = false});

  final List<BookReservation> reservations;
  final bool history;

  @override
  Widget build(BuildContext context) {
    if (reservations.isEmpty) {
      return EmptyState(
        icon: Icons.bookmark_border_rounded,
        title: history ? 'No cancelled holds' : 'No active holds',
        message: history
            ? 'Cancelled book reservations will be listed here.'
            : 'Search the catalog and reserve a book to see it listed here.',
        actionLabel: history ? null : 'Browse books',
        onAction: history
            ? null
            : () => AppShell.switchTab(context, AppTab.books),
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
                      label: switch (reservation.status) {
                        ReservationStatus.cancelled => 'Cancelled',
                        ReservationStatus.ready => 'Ready for pickup',
                        _ => 'Active',
                      },
                      color: switch (reservation.status) {
                        ReservationStatus.cancelled => AppColors.error,
                        ReservationStatus.ready => AppColors.success,
                        _ => AppColors.primary,
                      },
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
  const _SeatBookings({required this.bookings, this.history = false});

  final List<SeatBooking> bookings;
  final bool history;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return EmptyState(
        icon: Icons.event_seat_outlined,
        title: history ? 'No past bookings' : 'No active seat bookings',
        message: history
            ? 'Completed and cancelled bookings will be listed here.'
            : 'Reserve a reading-room seat and it will appear here.',
        actionLabel: history ? null : 'Reserve a seat',
        onAction: history
            ? null
            : () => AppShell.switchTab(context, AppTab.seats),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => StaggeredEntrance(
        index: i,
        child: _SeatBookingCard(booking: bookings[i], history: history),
      ),
    );
  }
}

class _SeatBookingCard extends StatelessWidget {
  const _SeatBookingCard({required this.booking, this.history = false});

  final SeatBooking booking;
  final bool history;

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
                label: history ? 'Completed' : 'Active',
                color: history ? AppColors.neutral : AppColors.success,
                compact: true,
                pulse: !history,
              ),
            ],
          ),
          if (!history) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Show QR',
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
        title: 'Nothing in the queue',
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
                        'About ${entry.estimatedWaitMinutes} min (estimate)',
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
              onPressed: () async {
                // M01: leaving the queue confirms — the position is lost.
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'Leave the queue?',
                  body:
                      "You'll lose position #${entry.position} for ${entry.title}.",
                  confirmLabel: 'Leave queue',
                  cancelLabel: 'Stay in queue',
                );
                if (confirmed && context.mounted) {
                  AppScope.read(context).leaveWaitlist(entry.id);
                }
              },
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
