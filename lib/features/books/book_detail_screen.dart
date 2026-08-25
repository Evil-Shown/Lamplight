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
      BookAvailability.available => ('Available now', AppColors.success),
      BookAvailability.onLoan => ('On loan', AppColors.warning),
      BookAvailability.reserved => ('Reserved', AppColors.error),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Book details')),
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
                  width: 120,
                  height: 168,
                  radius: 14,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  book.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  book.author,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                StatusChip(
                  label: statusLabel,
                  color: statusColor,
                  icon: canReserve ? Icons.check_circle_outline : Icons.schedule,
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
                      content: Text("You're on the waitlist — we'll notify you when it's free."),
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
