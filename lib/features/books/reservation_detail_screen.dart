import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../qr/qr_ticket_screen.dart';
import 'reservation_cancelled_screen.dart';

/// container-3 Reservation Details.
///
/// The full record for one book hold, with the QR pass, the reservation
/// metadata, and the confirm-then-cancel flow from container-5.
class ReservationDetailScreen extends StatelessWidget {
  const ReservationDetailScreen({super.key, required this.reservation});

  final BookReservation reservation;

  Future<void> _confirmCancel(BuildContext context) async {
    final state = AppScope.read(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Cancel Reservation?',
            style: AppText.title(17, w: FontWeight.w700)),
        content: Text(
          'Are you sure you want to cancel this reservation? '
          'This action cannot be undone.',
          style: AppText.body(13.5, color: AppColors.textSecondary, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Yes, Cancel',
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'No, Keep',
                  tone: ButtonTone.danger,
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    state.cancelReservation(reservation.id);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ReservationCancelledScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = reservation.book;

    return AppScaffold(
      title: 'Reservation Details',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          StaggeredEntrance(
            child: SurfaceCard(
              child: Row(
                children: [
                  BookCover(
                    title: book.title,
                    color: book.coverColor,
                    isbn: book.isbn,
                    width: 56,
                    height: 78,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(book.title,
                            style: AppText.title(16, w: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          book.author,
                          style:
                              AppText.body(12.5, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 9),
                        // Wrap so the three pills reflow on narrow screens.
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            StatusPill(
                              label: 'Book',
                              color: AppColors.neutral,
                              background: AppColors.neutralSoft,
                              compact: true,
                            ),
                            const SizedBox(width: 6),
                            StatusPill(
                              label: switch (reservation.status) {
                                ReservationStatus.ready => 'Ready',
                                ReservationStatus.cancelled => 'Cancelled',
                                _ => 'Active',
                              },
                              color: switch (reservation.status) {
                                ReservationStatus.ready => AppColors.success,
                                ReservationStatus.cancelled => AppColors.error,
                                _ => AppColors.primary,
                              },
                              compact: true,
                            ),
                            if (book.copiesAvailable > 0) ...[
                              const SizedBox(width: 6),
                              StatusPill(
                                label: '${book.copiesAvailable} avail',
                                color: AppColors.success,
                                compact: true,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: SectionLabel('Reservation information'),
          ),
          const SizedBox(height: 10),
          StaggeredEntrance(
            index: 1,
            child: SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  InfoRow(label: 'Reservation ID', value: reservation.id),
                  const Divider(height: 1),
                  InfoRow(
                      label: 'Pickup location', value: reservation.pickupLocation),
                  const Divider(height: 1),
                  InfoRow(
                    label: 'Pickup by',
                    value: DateFormat('yyyy-MM-dd').format(reservation.pickupBy),
                  ),
                  const Divider(height: 1),
                  InfoRow(
                    label: 'Reserved on',
                    value: DateFormat('yyyy-MM-dd')
                        .format(reservation.reservedAt),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'View QR Code',
            icon: Icons.qr_code_rounded,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _ReservationQrScreen(reservation: reservation),
              ),
            ),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'Cancel Reservation',
            tone: ButtonTone.danger,
            onPressed: () => _confirmCancel(context),
          ),
        ],
      ),
    );
  }
}

/// The QR pass for a book hold — same widget as the seat pass, different
/// copy, per the container-4 frame.
class _ReservationQrScreen extends StatelessWidget {
  const _ReservationQrScreen({required this.reservation});

  final BookReservation reservation;

  @override
  Widget build(BuildContext context) {
    final booking = SeatBooking(
      id: reservation.id,
      seat: Seat(
        id: 'counter',
        label: 'Counter',
        floor: 1,
        section: reservation.pickupLocation,
        status: SeatStatus.available,
        category: SeatCategory.collaborative,
        hasPowerOutlet: false,
        hasMonitor: false,
        nearWindow: false,
        row: 0,
        col: 0,
      ),
      date: reservation.reservedAt,
      startTime: reservation.reservedAt,
      endTime: reservation.pickupBy,
      qrCode: reservation.qrCode,
    );

    return QrTicketScreen(booking: booking);
  }
}
