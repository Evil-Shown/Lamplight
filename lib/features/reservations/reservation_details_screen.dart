import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/reservation_repository.dart';
import 'cancel_reservation_dialog.dart';
import 'my_reservations_screen.dart';
import 'qr_checkin_screen.dart';
import 'reservation_cancelled_screen.dart';

class ReservationDetailsScreen extends StatelessWidget {
  const ReservationDetailsScreen({super.key, required this.record});

  final ReservationRecord record;

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showCancelReservationDialog(context, record);
    if (confirmed && context.mounted) {
      ReservationRepository.instance.cancel(record.id);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReservationCancelledScreen(record: record),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cancelled = !record.isActive;

    return Scaffold(
      appBar: AppBar(title: const Text('Reservation Details')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _SummaryCard(record: record),
              const SizedBox(height: AppSpacing.lg),
              _InformationCard(record: record),
              const SizedBox(height: AppSpacing.lg),
              if (!cancelled) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QrCheckInScreen(record: record),
                      ),
                    ),
                    icon: const Icon(Icons.qr_code_2_rounded),
                    label: const Text('View QR Code'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: AppColors.error,
                        width: 1.5,
                      ),
                    ),
                    onPressed: () => _confirmCancel(context),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel Reservation'),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cancel_rounded, color: AppColors.error),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'This reservation has been cancelled. It no longer '
                          'appears in your active reservations.',
                          style: TextStyle(
                            color: AppColors.onErrorContainer,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  MyReservationsScreen.routeName,
                  (route) =>
                      route.settings.name == MyReservationsScreen.routeName ||
                      route.isFirst,
                ),
                child: const Text('Back to My Reservations'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.record});

  final ReservationRecord record;

  @override
  Widget build(BuildContext context) {
    final isBook = record.kind == ReservationKind.book;

    return SurfaceCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isBook)
            BookCover(
              title: record.title,
              color: record.coverColor,
              width: 62,
              height: 86,
            )
          else
            IconBadge(
              icon: Icons.event_seat_rounded,
              color: AppColors.info,
              size: 62,
            ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    StatusPill(
                      label: isBook ? 'Book' : 'Seat',
                      color: AppColors.info,
                      compact: true,
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    StatusPill(
                      label: record.isActive ? 'Active' : 'Cancelled',
                      color: record.isActive ? AppColors.success : AppColors.error,
                      icon: record.isActive
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.record});

  final ReservationRecord record;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              'RESERVATION INFORMATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          InfoRow(label: 'Reservation ID', value: record.id),
          const Divider(),
          InfoRow(label: 'Pickup Location', value: record.location),
          const Divider(),
          InfoRow(
            label: record.kind == ReservationKind.book
                ? 'Pickup By'
                : 'Session',
            value: record.timeRange != null
                ? '${DateFormat('MMM d, yyyy').format(record.pickupBy)} · ${record.timeRange}'
                : DateFormat('yyyy-MM-dd').format(record.pickupBy),
          ),
          const Divider(),
          InfoRow(
            label: 'Reserved On',
            value: DateFormat('yyyy-MM-dd').format(record.reservedOn),
          ),
        ],
      ),
    );
  }
}

