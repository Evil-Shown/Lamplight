import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/mock/mock_data.dart';
import '../../models/models.dart';
import 'book_detail_screen.dart';
import 'my_reservations_screen.dart';

class BookSearchScreen extends StatefulWidget {
  const BookSearchScreen({super.key});

  @override
  State<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  String _query = '';
  String _filter = 'All';

  static const _filters = ['All', 'Available', 'On loan', 'Reserved'];

  List<Book> get _filteredBooks {
    return MockData.books.where((book) {
      final matchesQuery = _query.isEmpty ||
          book.title.toLowerCase().contains(_query.toLowerCase()) ||
          book.author.toLowerCase().contains(_query.toLowerCase()) ||
          book.subject.toLowerCase().contains(_query.toLowerCase()) ||
          book.isbn.contains(_query);

      final matchesFilter = switch (_filter) {
        'Available' => book.availability == BookAvailability.available,
        'On loan' => book.availability == BookAvailability.onLoan,
        'Reserved' => book.availability == BookAvailability.reserved,
        _ => true,
      };

      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final books = _filteredBooks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog'),
        actions: [
          IconButton(
            tooltip: 'My reservations',
            icon: Badge(
              isLabelVisible: MockData.activeReservations.isNotEmpty,
              label: Text('${MockData.activeReservations.length}'),
              child: const Icon(Icons.bookmark_outline_rounded),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyReservationsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Semantics(
              label: 'Search books by title, author, subject, or ISBN',
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: AppStrings.searchBooksHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() => _query = ''),
                        ),
                ),
              ),
            ),
          ),
          FilterChipBar(
            options: _filters,
            selected: _filter,
            onSelected: (v) => setState(() => _filter = v),
          ),
          const SizedBox(height: AppSpacing.md),
          SectionHeader(
            title: '${books.length} ${books.length == 1 ? 'result' : 'results'}',
            subtitle: 'Tap a title for details & reserve',
            actionLabel: 'Holds',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyReservationsScreen()),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: books.isEmpty
                ? const EmptyState(
                    icon: Icons.menu_book_outlined,
                    title: 'No books found',
                    message: 'Try a different search term or clear your filters.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppNavInset.bottom,
                    ),
                    itemCount: books.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) => _BookCard(
                      book: books[index],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookDetailScreen(book: books[index]),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book, required this.onTap});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (book.availability) {
      BookAvailability.available => ('Available', AppColors.success),
      BookAvailability.onLoan => ('On loan', AppColors.warning),
      BookAvailability.reserved => ('Reserved', AppColors.error),
    };

    return SoftCard(
      elevated: true,
      onTap: onTap,
      child: Row(
        children: [
          BookCover(
            title: book.title,
            color: book.coverColor,
            width: 58,
            height: 82,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  book.author,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  book.subject,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    StatusChip(label: statusLabel, color: statusColor, compact: true),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        book.shelfLocation,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

String bookAvailabilityLabel(BookAvailability a) {
  return switch (a) {
    BookAvailability.available => 'Available',
    BookAvailability.onLoan => 'On loan',
    BookAvailability.reserved => 'Reserved',
  };
}

String formatDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);
