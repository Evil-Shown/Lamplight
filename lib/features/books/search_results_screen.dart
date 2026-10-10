import 'package:flutter/material.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/navigation/app_route.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Brief skeleton phase so results feel fetched rather than instant.
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _loading = false);
    });
  }

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
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.base, AppSpacing.xs, AppSpacing.base, 0),
            child: FrostedCard(
              radius: AppRadii.full,
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  Icon(Icons.search_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _query.isEmpty ? 'All titles' : _query,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(14.5, w: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      AppFeedback.tap();
                      setState(() => _query = '');
                    },
                    icon: Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.base,
                AppSpacing.base, AppSpacing.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _loading
                  ? const Skeleton(
                      width: 110, height: 12, radius: AppRadii.full)
                  : Text(
                      '${books.length} ${books.length == 1 ? 'book' : 'books'} found',
                      style: AppText.body(13, color: AppColors.textSecondary),
                    ),
            ),
          ),
          Expanded(
            child: _loading
                ? ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.base, 0, AppSpacing.base, AppSpacing.xl),
                    itemCount: 4,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, i) => StaggeredEntrance(
                      index: i,
                      child: const SkeletonCard(height: 98),
                    ),
                  )
                : books.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No matches',
                        message:
                            'Nothing in the catalog matches that search. Try a '
                            'different term, or check the spelling.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.base, 0, AppSpacing.base, AppSpacing.xl),
                        itemCount: books.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
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
      onTap: () => AppRoute.push(context, BookDetailScreen(book: book)),
      tint: pillColor.withValues(alpha: 0.22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookCover(
            title: book.title,
            color: book.coverColor,
            isbn: book.isbn,
            coverUrl: book.coverUrl,
            width: 52,
            height: 74,
            heroTag: 'book-${book.id}',
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
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusPill(
                      label: pillLabel,
                      color: pillColor,
                      icon: book.availability == BookAvailability.available
                          ? Icons.check_rounded
                          : Icons.priority_high_rounded,
                      compact: true,
                    ),
                    ShelfTag(book.shelfLocation),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2),
            child: Icon(Icons.chevron_right_rounded,
                size: 22, color: AppColors.textFaint),
          ),
        ],
      ),
    );
  }
}
