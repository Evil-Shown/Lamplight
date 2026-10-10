import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../../screens/my_reservations_screen.dart';
import 'pickup_countdown.dart';

/// reservation-success "Reservation Successful".
///
/// Confirmation, the book that was held, and where and when to collect it.
class ReservationConfirmationScreen extends StatelessWidget {
  const ReservationConfirmationScreen({
    super.key,
    required this.book,
    required this.reservation,
  });

  final Book book;
  final BookReservation reservation;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Book reserved',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xl),
        children: [
          // Outcome panel: glass hero with a soft success tint.
          GlassSurface(
            radius: AppRadii.xl,
            tint: AppColors.success.withValues(alpha: 0.14),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xl),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const SuccessCheck(size: 84),
                  const SizedBox(height: AppSpacing.base),
                  Text(
                    'Book reserved',
                    textAlign: TextAlign.center,
                    style: AppText.title(26, w: FontWeight.w800, ls: -0.9),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${book.title} is waiting for you.',
                    textAlign: TextAlign.center,
                    style: AppText.body(14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          StaggeredEntrance(
            child: SurfaceCard(
              child: Row(
                children: [
                  Semantics(
                      image: true,
                      label: 'Cover of ${book.title}',
                      excludeSemantics: true,
                      child: BookCover(
                        title: book.title,
                        color: book.coverColor,
                        isbn: book.isbn,
                        width: 52,
                        height: 74,
                        heroTag: 'book-${book.id}',
                      )),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(book.title,
                            style: AppText.title(15, w: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          book.author,
                          style: AppText.body(12.5,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ISBN ${book.isbn}',
                          style: AppText.body(11.5, color: AppColors.textFaint),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          StaggeredEntrance(
            index: 1,
            child: SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('PICK UP BY',
                          style: AppText.overline(
                            10.5,
                            color: AppColors.textFaint,
                          )),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      DateFormat('EEE d MMMM yyyy')
                          .format(reservation.pickupBy),
                      style: AppText.title(15, w: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PickupCountdownText(reservation: reservation),
                  ),
                  const Divider(height: 22),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('COLLECT FROM',
                          style: AppText.overline(
                            10.5,
                            color: AppColors.textFaint,
                          )),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${reservation.pickupLocation} – Counter 01',
                        style: AppText.title(15, w: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'View my reservations',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MyReservationsScreen(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Back to home',
            tone: ButtonTone.secondary,
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }
}
