import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/navigation/app_route.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../qr/qr_ticket_screen.dart';

/// P-08 Seat Reserved.
///
/// Confirms the booking and hands over the booking ID that the QR pass
/// will carry.
class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key, required this.booking});

  final SeatBooking booking;

  @override
  Widget build(BuildContext context) {
    final time =
        '${DateFormat('HH:mm').format(booking.startTime)} – ${DateFormat('HH:mm').format(booking.endTime)}';

    return AppScaffold(
      title: 'Booking confirmed',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          // Outcome panel: flat success container — mint gradients retired.
          Container(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
            decoration: BoxDecoration(
              color: AppColors.successContainer,
              borderRadius: BorderRadius.circular(AppRadii.xl),
            ),
            child: Column(
              children: [
                const SuccessCheck(size: 84),
                const SizedBox(height: 15),
                Text(
                  'Booking confirmed',
                  textAlign: TextAlign.center,
                  style: AppText.display(
                    22,
                    w: FontWeight.w800,
                    ls: -0.9,
                    color: AppColors.onSuccessContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Seat ${booking.seat.label} is yours.',
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    14,
                    color: AppColors.onSuccessContainer.withValues(alpha: 0.86),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          StaggeredEntrance(
            child: TicketCard(
              top: Column(
                children: [
                  InfoRow(
                    label: 'Seat',
                    value: '${booking.seat.label} (${booking.seat.zoneLabel})',
                  ),
                  const Divider(height: 1),
                  InfoRow(label: 'Floor', value: 'Floor ${booking.seat.floor}'),
                  const Divider(height: 1),
                  InfoRow(
                    label: 'Date',
                    value: DateFormat('EEE d MMM yyyy').format(booking.date),
                  ),
                  const Divider(height: 1),
                  InfoRow(label: 'Time', value: time),
                ],
              ),
              bottom: InfoRow(
                label: 'Booking ID',
                value: booking.id,
                valueColor: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Callout(
            icon: Icons.qr_code_rounded,
            message:
                'Your QR pass is ready. Show it at the entrance.',
          ),
          const SizedBox(height: 26),
          PrimaryButton(
            label: 'Show QR pass',
            onPressed: () => AppRoute.push(
              context,
              QrTicketScreen(booking: booking),
            ),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'Done',
            tone: ButtonTone.secondary,
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }
}
