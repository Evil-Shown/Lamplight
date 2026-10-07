import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import 'active_session_screen.dart';

/// P-12 QR Check-in / container-4.
///
/// The student's scannable pass for a seat booking: a large QR code, the
/// booking reference, and the seat, floor, and window it entitles them to.
class QrTicketScreen extends StatelessWidget {
  const QrTicketScreen({super.key, required this.booking});

  final SeatBooking booking;

  @override
  Widget build(BuildContext context) {
    final time =
        '${DateFormat('h:mm a').format(booking.startTime)} – ${DateFormat('h:mm a').format(booking.endTime)}';
    final day = DateFormat('d MMM yyyy').format(booking.date);

    return AppScaffold(
      title: 'QR Check-in',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            'Scan at the reading-room entrance',
            textAlign: TextAlign.center,
            style: AppText.body(13.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 22),
          StaggeredEntrance(
            child: SurfaceCard(
              elevated: true,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: QrImageView(
                      data: booking.qrCode,
                      version: QrVersions.auto,
                      size: 190,
                      backgroundColor: Colors.white,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.textPrimary,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Booking ${booking.id}',
                    style: AppText.title(15, w: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Show this code at the entrance scanner.',
                    textAlign: TextAlign.center,
                    style: AppText.body(12.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          StaggeredEntrance(
            index: 1,
            child: SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seat ${booking.seat.label} · Floor ${booking.seat.floor}',
                    style: AppText.title(16, w: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  InfoRow(label: 'Date', value: day),
                  const Divider(height: 1),
                  InfoRow(label: 'Time', value: time),
                  const Divider(height: 1),
                  InfoRow(label: 'Zone', value: booking.seat.zoneLabel),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'Complete Check-in',
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: () {
              AppScope.read(context).checkIn();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ActiveSessionScreen(booking: booking),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
