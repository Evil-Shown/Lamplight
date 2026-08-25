import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import 'book_search_screen.dart';
import 'reservation_confirmation_screen.dart';

class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final canReserve = book.availability == BookAvailability.available;
    final (statusLabel, statusColor) = switch (book.availability) {
      BookAvailability.available => ('Available now', AppColors.stampGreen),
      BookAvailability.onLoan => ('On loan', AppColors.stampGold),
      BookAvailability.reserved => ('Reserved', AppColors.stampRed),
    };

    return Scaffold(
      appBar: AppBar(title: Text('Book details', style: AppText.serif(22))),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          SoftCard(
            elevated: true,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                BookCover(
                  title: book.title,
                  color: book.coverColor,
                  isbn: book.isbn,
                  width: 124,
                  height: 172,
                  radius: 14,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  book.title,
                  style: AppText.serif(23),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Container(
                    width: 42,
                    height: 1.6,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  book.author,
                  style: AppText.sans(14, w: FontWeight.w500, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                StatusChip(
                  label: statusLabel,
                  color: statusColor,
                  pulse: canReserve,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SoftCard(
            elevated: true,
            child: Column(
              children: [
                InfoRow(icon: Icons.category_outlined, label: 'Subject', value: book.subject),
                const Divider(),
                InfoRow(icon: Icons.numbers_rounded, label: 'ISBN', value: book.isbn),
                const Divider(),
                InfoRow(
                  icon: Icons.shelves,
                  label: 'Shelf location',
                  value: book.shelfLocation,
                ),
                if (book.dueDate != null) ...[
                  const Divider(),
                  InfoRow(
                    icon: Icons.event_outlined,
                    label: 'Due back',
                    value: formatDate(book.dueDate!),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const AlertBanner(
            tone: AlertTone.success,
            icon: Icons.visibility_off_outlined,
            message: 'Your reservation stays private — only library staff can see it.',
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: canReserve
            ? ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReservationConfirmationScreen(book: book),
                  ),
                ),
                icon: const Icon(Icons.bookmark_add_rounded),
                label: const Text('Reserve book'),
              )
            : OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text("You're on the waitlist — we'll notify you when it's free."),
                    ),
                  );
                },
                icon: const Icon(Icons.hourglass_top_rounded),
                label: const Text('Join waitlist'),
              ),
      ),
    );
  }
}
