import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/motion3d.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../waitlist/waitlist_screen.dart';
import 'reservation_confirmation_screen.dart';

/// book-details-v3 "Book Details".
///
/// Cover, availability, description, the catalog identifiers, and the
/// reserve (or waitlist) action pinned to the bottom.
class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final canReserve = book.availability == BookAvailability.available;

    return AppScaffold(
      title: 'Book Details',
      actions: [
        IconButton(
          icon: const Icon(Icons.ios_share_rounded, size: 19),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share link copied')),
            );
          },
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          StaggeredEntrance(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tilt3D(
                  maxTilt: 0.16,
                  lift: 10,
                  child: BookCover(
                    title: book.title,
                    color: book.coverColor,
                    isbn: book.isbn,
                    width: 96,
                    height: 136,
                    radius: AppRadii.sm,
                    heroTag: 'book-${book.id}',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: AppText.display(
                          19,
                          w: FontWeight.w700,
                          ls: -0.3,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        book.author,
                        style: AppText.body(
                          13.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 11),
                      StatusPill(
                        label: switch (book.availability) {
                          BookAvailability.available =>
                            '${book.copiesAvailable} copies available',
                          BookAvailability.onLoan => 'Currently on loan',
                          BookAvailability.waitlisted => 'All copies out',
                        },
                        color: canReserve
                            ? AppColors.success
                            : AppColors.error,
                        icon: canReserve
                            ? Icons.check_circle_outline_rounded
                            : Icons.info_outline_rounded,
                        compact: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          StaggeredEntrance(
            index: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description',
                    style: AppText.body(13.5, w: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  book.description,
                  style: AppText.body(
                    13.5,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          StaggeredEntrance(
            index: 2,
            child: SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  InfoRow(label: 'ISBN', value: book.isbn),
                  const Divider(height: 1),
                  InfoRow(label: 'Shelf Location', value: book.shelfLocation),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Callout(
            icon: canReserve
                ? Icons.inventory_2_outlined
                : Icons.hourglass_empty_rounded,
            tone: canReserve ? CalloutTone.success : CalloutTone.warning,
            message: canReserve
                ? '${book.copiesAvailable} copies available. Located on shelf '
                    '${book.shelfLocation}.'
                : 'All copies are out. Join the waitlist and we will notify you '
                    'the moment one is returned.',
          ),
        ],
      ),
      bottomBar: BottomActionBar(
        child: canReserve
            ? PrimaryButton(
                label: 'RESERVE BOOK',
                icon: Icons.bookmark_add_outlined,
                onPressed: () {
                  final reservation =
                      AppScope.read(context).reserveBook(book);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReservationConfirmationScreen(
                        book: book,
                        reservation: reservation,
                      ),
                    ),
                  );
                },
              )
            : PrimaryButton(
                label: 'JOIN WAITLIST',
                icon: Icons.hourglass_bottom_rounded,
                tone: ButtonTone.secondary,
                // Books use the same waitlist screen as seats, just
                // parameterised (D-08) — no snackbar shortcut.
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WaitlistScreen(book: book),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
