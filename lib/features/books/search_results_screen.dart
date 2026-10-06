import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import 'book_detail_screen.dart';

/// search-results.
///
/// The result list for a query, with the active query shown as a
/// removable chip above the match count.
class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({
    super.key,
    required this.query,
    this.searchType = 'TITLE',
  });

  final String query;
  final String searchType;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late String _query = widget.query;

  List<Book> _matches(List<Book> books) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty || q == 'all titles') return books;
    return books.where((b) {
      return switch (widget.searchType) {
        'AUTHOR' => b.author.toLowerCase().contains(q),
        'ISBN' => b.isbn.replaceAll('-', '').contains(q.replaceAll('-', '')),
        'CATEGORY' => b.subject.toLowerCase().contains(q),
        _ => b.title.toLowerCase().contains(q) ||
            b.author.toLowerCase().contains(q) ||
            b.subject.toLowerCase().contains(q) ||
            b.isbn.replaceAll('-', '').contains(q.replaceAll('-', '')),
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final books = _matches(AppScope.of(context).books);

    return AppScaffold(
      title: 'Search Results',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded,
                            size: 17, color: AppColors.textFaint),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            _query,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(14),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _query = ''),
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: AppColors.textFaint),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${books.length} ${books.length == 1 ? 'book' : 'books'} found',
                style: AppText.body(13, color: AppColors.textSecondary),
              ),
            ),
          ),
          Expanded(
            child: books.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No matches',
                    message:
                        'Nothing in the catalog matches that search. Try a '
                        'different term.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    itemCount: books.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => StaggeredEntrance(
                      index: i,
                      child: _ResultRow(book: books[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final (pillColor, pillLabel) = switch (book.availability) {
      BookAvailability.available => (AppColors.success, 'Available'),
      BookAvailability.onLoan => (AppColors.error, 'Unavailable'),
      BookAvailability.waitlisted => (AppColors.warning, 'Waitlist · 4'),
    };

    return SurfaceCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
      ),
      tint: pillColor.withValues(alpha: 0.22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookCover(
            title: book.title,
            color: book.coverColor,
            isbn: book.isbn,
            width: 52,
            height: 74,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title(15, w: FontWeight.w700, height: 1.25),
                ),
                const SizedBox(height: 2),
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    StatusPill(
                      label: pillLabel,
                      color: pillColor,
                      icon: book.availability == BookAvailability.available
                          ? Icons.check_rounded
                          : Icons.priority_high_rounded,
                      compact: true,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Shelf ${book.shelfLocation}',
                        style:
                            AppText.body(11.5, color: AppColors.textFaint),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 4, top: 2),
            child: Text(
              'VIEW DETAILS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
