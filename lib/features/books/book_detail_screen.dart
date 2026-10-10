import 'package:flutter/material.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/navigation/app_route.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/motion3d.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../waitlist/waitlist_screen.dart';
import 'reservation_confirmation_screen.dart';

/// book-details-v3 "Book Details".
///
/// Cover hero with a colour glow, availability, description, the catalog
/// identifiers, and the reserve (or waitlist) action pinned to the bottom.
class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    // Prefer the live catalogue copy so counts stay current while open.
    final book = AppScope.of(context)
            .books
            .where((b) => b.id == this.book.id)
            .firstOrNull ??
        this.book;
    final canReserve = book.availability == BookAvailability.available &&
        book.copiesAvailable > 0;
    final glow =
        book.coverColor == null ? AppColors.primary : Color(book.coverColor!);

    return AppScaffold(
      title: 'Book Details',
      actions: [
        IconButton(
          tooltip: 'Share',
          icon: const Icon(Icons.ios_share_rounded, size: 19),
          onPressed: () {
            AppFeedback.tap();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share link copied')),
            );
          },
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
        children: [
          // Cover hero: depth, plus a soft glow in the cover's own colour.
          StaggeredEntrance(
            child: FrostedCard(
              radius: AppRadii.xl,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          glow.withValues(alpha: 0.38),
                          glow.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                    child: Tilt3D(
                      maxTilt: 0.16,
                      lift: 12,
                      child: Semantics(
                          image: true,
                          label: 'Cover of ${book.title}',
                          excludeSemantics: true,
                          child: BookCover(
                            title: book.title,
                            color: book.coverColor,
                            isbn: book.isbn,
                            coverUrl: book.coverUrl,
                            width: 132,
                            height: 188,
                            radius: AppRadii.sm,
                            heroTag: 'book-${book.id}',
                          )),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  Text(
                    book.title,
                    textAlign: TextAlign.center,
                    style: AppText.title(
                      22,
                      w: FontWeight.w800,
                      ls: -0.6,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    textAlign: TextAlign.center,
                    style: AppText.body(14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      StatusPill(
                        label: switch (book.availability) {
                          BookAvailability.available =>
                            '${book.copiesAvailable} copies available',
                          BookAvailability.onLoan => 'Currently on loan',
                          BookAvailability.waitlisted => 'All copies out',
                        },
                        color: canReserve ? AppColors.success : AppColors.error,
                        icon: canReserve
                            ? Icons.check_circle_outline_rounded
                            : Icons.info_outline_rounded,
                        compact: true,
                      ),
                      if (book.subject.isNotEmpty)
                        StatusPill(
                          label: book.subject,
                          color: AppColors.neutral,
                          background: AppColors.neutralSoft,
                          compact: true,
                        ),
                      ShelfTag(book.shelfLocation),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          StaggeredEntrance(
            index: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'About this book'),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  book.description,
                  style: AppText.body(
                    14,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          StaggeredEntrance(
            index: 2,
            child: SurfaceCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base, vertical: AppSpacing.xs),
              child: Column(
                children: [
                  InfoRow(label: 'ISBN', value: book.isbn),
                  const Divider(height: 1),
                  InfoRow(label: 'Shelf Location', value: book.shelfLocation),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          StaggeredEntrance(
            index: 3,
            child: Callout(
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
          ),
        ],
      ),
      bottomBar: BottomActionBar(
        child: canReserve
            ? PrimaryButton(
                label: 'RESERVE BOOK',
                icon: Icons.bookmark_add_outlined,
                onPressed: () {
                    final reservation = AppScope.read(context).reserveBook(book);
                    if (reservation == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You have already reserved this book'),
                        ),
                      );
                      return;
                    }
                  AppRoute.push(
                    context,
                    ReservationConfirmationScreen(
                      book: book,
                      reservation: reservation,
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
                  AppRoute.push(context, WaitlistScreen(book: book));
                },
              ),
      ),
    );
  }
}
