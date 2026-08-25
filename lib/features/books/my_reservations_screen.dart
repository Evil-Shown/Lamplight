import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/mock/mock_data.dart';
import '../../features/qr/qr_scan_screen.dart';
import 'book_search_screen.dart';

class MyReservationsScreen extends StatelessWidget {
  const MyReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reservations = MockData.activeReservations;

    return Scaffold(
      appBar: AppBar(title: const Text('My reservations')),
      body: reservations.isEmpty
          ? EmptyState(
              icon: Icons.bookmark_border_rounded,
              title: 'No active holds',
              message: 'Search the catalog and reserve a book to see it here.',
              actionLabel: 'Browse books',
              onAction: () => Navigator.pop(context),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: reservations.length,
              itemBuilder: (context, index) {
                final r = reservations[index];
                return SoftCard(
                  elevated: true,
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BookCover(
                            title: r.book.title,
                            color: r.book.coverColor,
                            width: 56,
                            height: 78,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.book.title,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  r.book.author,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                const StatusChip(
                                  label: 'Ready for pickup',
                                  color: AppColors.success,
                                  icon: Icons.check_circle_outline,
                                  compact: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      InfoRow(
                        icon: Icons.shelves,
                        label: 'Pickup location',
                        value: r.book.shelfLocation,
                      ),
                      const Divider(),
                      InfoRow(
                        icon: Icons.event_outlined,
                        label: 'Pickup by',
                        value: formatDate(r.pickupBy),
                      ),
                      const Divider(),
                      InfoRow(
                        icon: Icons.qr_code_rounded,
                        label: 'QR code',
                        value: r.qrCode,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QrScanScreen(
                                mode: QrScanMode.bookPickup,
                                referenceCode: r.qrCode,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          label: const Text('Scan for pickup'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
