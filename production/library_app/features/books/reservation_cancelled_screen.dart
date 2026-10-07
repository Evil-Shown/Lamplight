import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';

/// container-6 Reservation Cancelled.
///
/// The receipt shown after a hold is cancelled: confirmation, then the
/// details of what was released.
class ReservationCancelledScreen extends StatelessWidget {
  const ReservationCancelledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final last = state.reservations.isEmpty ? null : state.reservations.last;

    return AppScaffold(
      title: 'Reservation Cancelled',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Center(
            child: Column(
              children: [
                const SuccessCheck(size: 78),
                const SizedBox(height: 18),
                Text(
                  'Reservation Cancelled',
                  style: AppText.display(22, w: FontWeight.w700, ls: -0.4),
                ),
                const SizedBox(height: 7),
                Text(
                  'Your reservation for ${last?.book.title ?? 'this book'} has been '
                  'cancelled successfully.',
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          StaggeredEntrance(
            child: SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Cancelled receipt'),
                  const SizedBox(height: 14),
                  if (last != null) ...[
                    Row(
                      children: [
                        BookCover(
                          title: last.book.title,
                          color: last.book.coverColor,
                          isbn: last.book.isbn,
                          width: 46,
                          height: 65,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(last.book.title,
                                  style:
                                      AppText.title(15, w: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                last.book.author,
                                style: AppText.body(
                                    12.5, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    InfoRow(label: 'Reservation ID', value: last.id),
                    const Divider(height: 1),
                    InfoRow(label: 'Status', value: 'Cancelled',
                        valueColor: AppColors.error),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Back to My Reservations',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
