import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ledger_widgets.dart';
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
    final showTrending = _query.isEmpty && _filter == 'All';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 84,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Eyebrow('${MockData.books.length} titles ready'),
            const SizedBox(height: 3),
            Text('The catalog', style: AppText.serif(24)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'My reservations',
            icon: Badge(
              isLabelVisible: MockData.activeReservations.isNotEmpty,
              backgroundColor: AppColors.goldDeep,
              textColor: AppColors.paper,
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
              AppSpacing.xs,
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
          const SizedBox(height: AppSpacing.lg),
          if (showTrending) ...[
            const SectionHeader(title: 'Trending this week', trailing: '5 titles'),
            const SizedBox(height: AppSpacing.md),
            _TrendingCarousel(onTap: _openBook),
            const SizedBox(height: AppSpacing.xl),
          ],
          SectionHeader(title: showTrending ? 'On the shelf' : 'Results'),
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
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppNavInset.bottom,
                    ),
                    itemCount: books.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) => _BookRow(
                      book: books[index],
                      onTap: () => _openBook(books[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _openBook(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
    );
  }
}

class _TrendingCarousel extends StatelessWidget {
  const _TrendingCarousel({required this.onTap});

  final ValueChanged<Book> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: MockData.books.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final book = MockData.books[index];
          final (statusWord, statusColor) = switch (book.availability) {
            BookAvailability.available => ('AVAILABLE', AppColors.stampGreen),
            BookAvailability.onLoan => ('WAITLIST', AppColors.stampGold),
            BookAvailability.reserved => ('RESERVED', AppColors.stampGold),
          };

          return GestureDetector(
            onTap: () => onTap(book),
            child: SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BookCover(
                    title: book.title,
                    color: book.coverColor,
                    isbn: book.isbn,
                    width: 112,
                    height: 154,
                    radius: 12,
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  Text(
                    book.title,
                    style: AppText.serif(14, ls: -0.2, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    statusWord,
                    style: AppText.mono(9.5, w: FontWeight.w700, ls: 2, color: statusColor),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BookRow extends StatelessWidget {
  const _BookRow({required this.book, required this.onTap});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (book.availability) {
      BookAvailability.available => ('Available', AppColors.stampGreen),
      BookAvailability.onLoan => ('On loan', AppColors.stampGold),
      BookAvailability.reserved => ('Reserved', AppColors.stampRed),
    };

    return SoftCard(
      elevated: true,
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          BookCover(
            title: book.title,
            color: book.coverColor,
            isbn: book.isbn,
            width: 48,
            height: 66,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: AppText.serif(16, ls: -0.2, height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${book.author} · ${book.subject}',
                  style: AppText.sans(12, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    StatusChip(label: statusLabel, color: statusColor, compact: true),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        book.shelfLocation,
                        style: AppText.sans(11.5, color: AppColors.textFaint),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _CatalogAction(availability: book.availability),
        ],
      ),
    );
  }
}

class _CatalogAction extends StatelessWidget {
  const _CatalogAction({required this.availability});

  final BookAvailability availability;

  @override
  Widget build(BuildContext context) {
    final available = availability == BookAvailability.available;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: available ? AppColors.ink : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: available ? null : Border.all(color: AppColors.lineStrong),
      ),
      child: Text(
        available ? 'Reserve' : 'Waitlist',
        style: AppText.sans(
          12,
          w: FontWeight.w700,
          color: available ? AppColors.paper : AppColors.ink,
        ),
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
