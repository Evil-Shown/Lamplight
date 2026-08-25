import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import 'my_reservations_screen.dart';

class ReservationConfirmationScreen extends StatelessWidget {
  const ReservationConfirmationScreen({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final pickupBy = DateTime.now().add(const Duration(days: 2));

    return Scaffold(
      appBar: AppBar(title: const Text('Reservation')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Spacer(),
            SuccessHero(
              title: 'You\'re all set',
              subtitle: book.title,
            ),
            const SizedBox(height: AppSpacing.xl),
            SoftCard(
              elevated: true,
              child: Column(
                children: [
                  SummaryRow(
                    label: 'Pickup by',
                    value: DateFormat('MMM d, yyyy').format(pickupBy),
                  ),
                  const Divider(),
                  SummaryRow(label: 'Location', value: book.shelfLocation),
                  const Divider(),
                  const SummaryRow(label: 'QR code', value: 'BOOK-NEW-7X2K'),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyReservationsScreen()),
                );
              },
              child: const Text('View my reservations'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('Back to catalog'),
            ),
          ],
        ),
      ),
    );
  }
}
