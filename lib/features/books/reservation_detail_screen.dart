import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/navigation/app_route.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../qr/qr_ticket_screen.dart';
import 'pickup_countdown.dart';
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

    final confirmed = await showConfirmDialog(
      context,
      title: 'Cancel Reservation?',
      body: 'Are you sure you want to cancel this reservation? '
          'This action cannot be undone.',
      confirmLabel: 'Yes, Cancel',
      cancelLabel: 'No, Keep',
    );

    if (!confirmed || !context.mounted) return;

    state.cancelReservation(reservation.id);
    AppRoute.pushReplacement(
      context,
      const ReservationCancelledScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = reservation.book;
    final cancelled = reservation.status == ReservationStatus.cancelled;
    final expired =
        AppScope.of(context).pickupRemaining(reservation) == Duration.zero;
    final (statusLabel, statusColor) = switch (reservation.status) {
      _ when expired => ('Expired', AppColors.error),
      ReservationStatus.ready => ('Ready for pickup', AppColors.success),
      ReservationStatus.cancelled => ('Cancelled', AppColors.error),
      _ => ('Active', AppColors.primary),
    };

    return AppScaffold(
      title: 'Reservation Details',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.xl),
        children: [
          if (!cancelled) ...[
            PickupCountdownBanner(reservation: reservation),
            const SizedBox(height: AppSpacing.md),
          ],
          StaggeredEntrance(
            child: TicketCard(
              dimmed: cancelled || expired,
              top: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                      image: true,
                      label: 'Cover of ${book.title}',
                      excludeSemantics: true,
                      child: BookCover(
                        title: book.title,
                        color: book.coverColor,
                        isbn: book.isbn,
                        width: 64,
                        height: 90,
                        heroTag: 'book-${book.id}',
                      )),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(book.title,
                            style: AppText.title(17, w: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          book.author,
                          style:
                              AppText.body(13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Wrap so the pills reflow on narrow screens.
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            StatusPill(
                              label: statusLabel,
                              color: statusColor,
                              icon: cancelled || expired
                                  ? Icons.close_rounded
                                  : Icons.check_rounded,
                              compact: true,
                            ),
                            ShelfTag(book.shelfLocation),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              bottom: Column(
                children: [
                  InfoRow(
                      label: 'Pickup location',
                      value: reservation.pickupLocation,
                      dense: true),
                  InfoRow(
                    label: 'Pickup by',
                    value:
                        DateFormat('yyyy-MM-dd').format(reservation.pickupBy),
                    dense: true,
                  ),
                  InfoRow(
                      label: 'Reservation ID',
                      value: reservation.id,
                      dense: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Status'),
          const SizedBox(height: AppSpacing.md),
          StaggeredEntrance(
            index: 1,
            child: SurfaceCard(
              child: _StatusTimeline(reservation: reservation),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (!cancelled && !expired)
            StaggeredEntrance(
              index: 2,
              child: PrimaryButton(
                label: 'View QR Code',
                icon: Icons.qr_code_rounded,
                onPressed: () => AppRoute.push(
                  context,
                  _ReservationQrScreen(reservation: reservation),
                ),
              ),
            ),
          if (!cancelled) ...[
            const SizedBox(height: AppSpacing.md),
            // Secondary destructive: outlined, never the loudest thing here.
            StaggeredEntrance(
              index: 3,
              child: PressScale(
                onTap: () => _confirmCancel(context),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.55)),
                  ),
                  child: Text(
                    'Cancel Reservation',
                    textAlign: TextAlign.center,
                    style: AppText.label(
                      15,
                      w: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Reserved, ready, collected, with the current step marked by a ring and
/// every step carrying an icon, so status never relies on colour alone.
class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.reservation});

  final BookReservation reservation;

  @override
  Widget build(BuildContext context) {
    final status = reservation.status;
    final cancelled = status == ReservationStatus.cancelled;
    final completed = status == ReservationStatus.completed;
    final ready = status == ReservationStatus.ready;

    final steps = <_Step>[
      _Step(
        'Reserved',
        DateFormat('d MMM yyyy').format(reservation.reservedAt),
        _StepState.done,
      ),
      if (cancelled)
        const _Step('Cancelled', 'This hold was released', _StepState.failed)
      else ...[
        _Step(
          ready ? 'Ready for pickup' : 'Preparing your copy',
          'Pick up by ${DateFormat('d MMM').format(reservation.pickupBy)}',
          completed ? _StepState.done : _StepState.current,
        ),
        _Step(
          'Collected',
          'At ${reservation.pickupLocation}',
          completed ? _StepState.done : _StepState.pending,
        ),
      ],
    ];

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineRow(step: steps[i], last: i == steps.length - 1),
      ],
    );
  }
}

enum _StepState { done, current, pending, failed }

class _Step {
  const _Step(this.title, this.caption, this.state);

  final String title;
  final String caption;
  final _StepState state;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.last});

  final _Step step;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (step.state) {
      _StepState.done => (Icons.check_circle_rounded, AppColors.success),
      _StepState.current => (
          Icons.radio_button_checked_rounded,
          AppColors.primary
        ),
      _StepState.failed => (Icons.cancel_rounded, AppColors.error),
      _StepState.pending => (
          Icons.radio_button_unchecked_rounded,
          AppColors.textFaint
        ),
    };
    final muted = step.state == _StepState.pending;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Icon(icon, size: 22, color: color),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: AppText.title(
                      14.5,
                      w: FontWeight.w700,
                      color: muted ? AppColors.textSecondary : null,
                    ),
                  ),
                  Text(
                    step.caption,
                    style: AppText.body(12.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
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
