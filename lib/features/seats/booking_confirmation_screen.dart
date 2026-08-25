import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ledger_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import 'my_bookings_screen.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key, required this.seat});

  final Seat seat;

  @override
  Widget build(BuildContext context) {
    final start = DateTime.now();
    final end = start.add(const Duration(hours: 2));
    final fmt = DateFormat('h:mm a');

    return Scaffold(
      appBar: AppBar(title: Text('Booking', style: AppText.serif(22))),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Spacer(),
            SuccessHero(
              title: 'Seat booked.',
              subtitle: 'Seat ${seat.label} · Floor ${seat.floor}',
            ),
            const SizedBox(height: AppSpacing.xl),
            TicketCard(
              child: Column(
                children: [
                  SummaryRow(label: 'Section', value: seat.section),
                  const Divider(),
                  SummaryRow(
                    label: 'Time',
                    value: '${fmt.format(start)} – ${fmt.format(end)}',
                  ),
                  const Divider(),
                  const SummaryRow(label: 'Grace period', value: '15 min after start'),
                  const Divider(),
                  const SummaryRow(label: 'QR code', value: 'SEAT-NEW-4B8E'),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                );
              },
              child: const Text('View my bookings'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('Back to seat map'),
            ),
          ],
        ),
      ),
    );
  }
}
