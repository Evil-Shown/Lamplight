import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/reservation_repository.dart';
import 'my_reservations_screen.dart';

class QrCheckInScreen extends StatelessWidget {
  const QrCheckInScreen({super.key, required this.record});

  final ReservationRecord record;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Check-In')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              SoftCard(
                elevated: true,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: QrImageView(
                        data: record.qrPayload,
                        version: QrVersions.auto,
                        size: 220,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.textPrimary,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.textPrimary,
                        ),
                        gapless: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Show this QR code at the library counter to check in.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _DetailsCard(record: record),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    MyReservationsScreen.routeName,
                    (route) =>
                        route.settings.name == MyReservationsScreen.routeName ||
                        route.isFirst,
                  ),
                  child: const Text('Back to Reservations'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.record});

  final ReservationRecord record;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              if (record.kind == ReservationKind.book)
                BookCover(
                  title: record.title,
                  color: record.coverColor,
                  width: 44,
                  height: 60,
                )
              else
                const IconBadge(
                  icon: Icons.event_seat_rounded,
                  color: AppColors.info,
                  size: 44,
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
          SummaryRow(label: 'Location', value: record.location),
          const Divider(),
          SummaryRow(
            label: 'Pickup by',
            value: DateFormat('yyyy-MM-dd').format(record.pickupBy),
          ),
        ],
      ),
    );
  }
}
