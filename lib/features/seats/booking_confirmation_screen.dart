import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
        '${DateFormat('h:mm a').format(booking.startTime)} – ${DateFormat('h:mm a').format(booking.endTime)}';

    return AppScaffold(
      title: 'Booking Confirmed',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          GradientHero(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
            gradient: AppGradients.mint,
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 34, color: AppColors.textInverse),
                ),
                const SizedBox(height: 15),
                Text(
                  'Booking Confirmed!',
                  textAlign: TextAlign.center,
                  style: AppText.display(22, w: FontWeight.w800, ls: -0.4,
                      color: AppColors.textInverse),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your seat has been reserved successfully.',
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    13,
                    color: AppColors.textInverse.withValues(alpha: 0.86),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          StaggeredEntrance(
            child: SurfaceCard(
              tint: AppColors.success,
              elevated: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
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
                    value: DateFormat('d MMM yyyy').format(booking.date),
                  ),
                  const Divider(height: 1),
                  InfoRow(label: 'Time', value: time),
                  const Divider(height: 1),
                  InfoRow(
                    label: 'Booking ID',
                    value: booking.id,
                    valueColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Callout(
            icon: Icons.qr_code_rounded,
            message:
                'Show your QR code at the library entrance for quick check-in.',
          ),
          const SizedBox(height: 26),
          PrimaryButton(
            label: 'Show QR pass',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => QrTicketScreen(booking: booking),
              ),
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
