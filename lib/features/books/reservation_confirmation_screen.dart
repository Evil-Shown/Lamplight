import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';

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
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          // Outcome panel: flat success container — mint gradients retired.
          Container(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
            decoration: BoxDecoration(
              color: AppColors.successContainer,
              borderRadius: BorderRadius.circular(AppRadii.xl),
            ),
            child: Column(
              children: [
                const SuccessCheck(size: 84),
                const SizedBox(height: 15),
                Text(
                  'Book reserved',
                  textAlign: TextAlign.center,
                  style: AppText.display(
                    22,
                    w: FontWeight.w800,
                    ls: -0.9,
                    color: AppColors.onSuccessContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${book.title} is waiting for you.',
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    14,
                    color: AppColors.onSuccessContainer.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          StaggeredEntrance(
            child: SurfaceCard(
              child: Row(
                children: [
                  BookCover(
                    title: book.title,
                    color: book.coverColor,
                    isbn: book.isbn,
                    width: 48,
                    height: 68,
                  ),
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
                          style: AppText.body(
                              12.5, color: AppColors.textSecondary),
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
          const SizedBox(height: 14),
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
                      DateFormat('EEE d MMMM yyyy').format(reservation.pickupBy),
                      style: AppText.title(15, w: FontWeight.w600),
                    ),
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
          const SizedBox(height: 26),
          PrimaryButton(
            label: 'View my reservations',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 10),
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
