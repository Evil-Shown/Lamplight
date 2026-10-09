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
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xl),
        children: [
          // Calm, neutral treatment: released, not an error and not a win.
          StaggeredEntrance(
            child: Center(
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.neutralSoft,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(Icons.bookmark_remove_outlined,
                        size: 34, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  Text(
                    'Reservation Cancelled',
                    textAlign: TextAlign.center,
                    style: AppText.display(24, w: FontWeight.w800, ls: -0.6),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Your reservation for ${last?.book.title ?? 'this book'} has been '
                    'cancelled successfully.',
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          StaggeredEntrance(
            child: SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Cancelled receipt'),
                  const SizedBox(height: AppSpacing.base),
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
                                  style: AppText.title(15, w: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                last.book.author,
                                style: AppText.body(12.5,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.base),
                    const Divider(),
                    InfoRow(label: 'Reservation ID', value: last.id),
                    const Divider(height: 1),
                    InfoRow(
                      label: 'Status',
                      value: 'Cancelled',
                      valueColor: AppColors.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'Back to My Reservations',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
