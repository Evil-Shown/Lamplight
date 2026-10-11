import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/reservation_repository.dart';
import 'my_reservations_screen.dart';

class ReservationCancelledScreen extends StatelessWidget {
  const ReservationCancelledScreen({super.key, required this.record});

  final ReservationRecord record;

  @override
  Widget build(BuildContext context) {
    final cancelledOn = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Reservation Cancelled')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const SizedBox(height: AppSpacing.sm),
              const _CancelledBadge(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Reservation Cancelled',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'Your reservation for ${record.title} has been cancelled '
                  'successfully.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.xs,
                  bottom: AppSpacing.sm,
                ),
                child: Text(
                  'CANCELLED RECEIPT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              _ReceiptCard(record: record, cancelledOn: cancelledOn),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
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

class _CancelledBadge extends StatelessWidget {
  const _CancelledBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.success,
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withValues(alpha: 0.25),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 52,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.record, required this.cancelledOn});

  final ReservationRecord record;
  final DateTime cancelledOn;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              if (record.kind == ReservationKind.book)
                BookCover(
                  title: record.title,
                  color: record.coverColor,
                  width: 52,
                  height: 72,
                )
              else
                const IconBadge(
                  icon: Icons.event_seat_rounded,
                  color: AppColors.info,
                  size: 52,
                ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                  ],
                ),
              ),
            ],
          ),
          const Divider(),
          SummaryRow(label: 'Reservation ID', value: record.id),
          const Divider(),
          SummaryRow(
            label: 'Cancelled On',
            value: DateFormat('yyyy-MM-dd').format(cancelledOn),
          ),
          const Divider(),
          const SummaryRow(label: 'Status', value: 'Cancelled'),
        ],
      ),
    );
  }
}
