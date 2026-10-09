import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import 'book_detail_screen.dart';
import 'reservation_confirmation_screen.dart';
import 'search_results_screen.dart';

/// book-search-v2 "Library Catalog".
///
/// The Stitch redesign: catalog header with a live-freshness indicator,
/// the search field, search-type tabs, filter chips, live result cards
/// with reserve actions, and an honest "search by ISBN" tip callout.
class BookSearchScreen extends StatefulWidget {
  const BookSearchScreen({super.key});

  @override
  State<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  final _controller = TextEditingController();
  String _searchType = 'Title';
  bool _showAll = false;
  final Set<String> _availabilityFilters = {};

  static const _searchTypes = ['Title', 'Author', 'ISBN', 'Category'];
  static const _availabilityOptions = ['Available now', 'On loan'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Book> _matches(List<Book> books) {
    final q = _controller.text.trim().toLowerCase();
    var results = books.where((b) {
      final matchesQuery = q.isEmpty ||
          switch (_searchType) {
            'Author' => b.author.toLowerCase().contains(q),
            'ISBN' =>
              b.isbn.replaceAll('-', '').contains(q.replaceAll('-', '')),
            'Category' => b.subject.toLowerCase().contains(q),
            _ =>
              b.title.toLowerCase().contains(q) ||
                  b.author.toLowerCase().contains(q) ||
                  b.subject.toLowerCase().contains(q),
          };
      if (!matchesQuery) return false;
      // Availability chips (D-15) — empty set means no filter.
      if (_availabilityFilters.isNotEmpty) {
        final matchesAvailability = (_availabilityFilters.contains(
                    'Available now') &&
                b.availability == BookAvailability.available) ||
            (_availabilityFilters.contains('On loan') &&
                b.availability == BookAvailability.onLoan);
        if (!matchesAvailability) return false;
      }
      return true;
    }).toList();
    return results;
  }

  void _openDetail(Book book) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
    );
  }

  void _reserve(Book book) {
    final state = AppScope.read(context);
    final reservation = state.reserveBook(book);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReservationConfirmationScreen(
          book: book,
          reservation: reservation,
        ),
      ),
    );
  }

  void _openResults() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(
          query: _controller.text.trim().isEmpty
              ? 'All titles'
              : _controller.text.trim(),
          searchType: _searchType.toUpperCase(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final books = _matches(state.books);
    final shown = _showAll || _controller.text.trim().isNotEmpty
        ? books
        : books.take(4).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CAMPUS COMMONS',
                          style: AppText.overline(9.5, ls: 1.4)),
                      const SizedBox(height: 2),
                      Text(
                        'Library Catalog',
                        style: AppText.display(
                          20,
                          w: FontWeight.w800,
                          ls: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                // Driven by the real last-synced timestamp (D-06).
                // Flexible so the freshness label ellipsizes instead of
                // pushing the header row past its bounds.
                Flexible(child: LiveFreshness(lastSyncedAt: state.lastSyncedAt)),
              ],
            ),
            const SizedBox(height: 18),
            StaggeredEntrance(
              child: Text(
                'Find a Book',
                style: AppText.display(24, w: FontWeight.w700, ls: -0.5),
              ),
            ),
            const SizedBox(height: 6),
            StaggeredEntrance(
              index: 1,
              child: Text(
                'Search the campus collection by title, author or ISBN.',
                style: AppText.body(14, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 18),
            StaggeredEntrance(
              index: 2,
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _openResults(),
                decoration: InputDecoration(
                  hintText: AppStrings.searchBooksHint,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => setState(() {
                            _controller.clear();
                            _showAll = false;
                          }),
                        ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 14),
            StaggeredEntrance(
              index: 3,
              child: SegmentedTabs(
                options: _searchTypes,
                selected: _searchType,
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  Haptics.selection();
                  setState(() => _searchType = value);
                },
              ),
            ),
            const SizedBox(height: 12),
            // Same filter-chip language as the seat map (D-15).
            StaggeredEntrance(
              index: 3,
              child: FilterChipRow(
                options: _availabilityOptions,
                selected: '',
                isSelectedOf: _availabilityFilters.contains,
                onSelected: (option) {
                  Haptics.selection();
                  setState(() {
                    if (!_availabilityFilters.remove(option)) {
                      _availabilityFilters.add(option);
                    }
                  });
                },
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 22),
            StaggeredEntrance(
              index: 4,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${books.length} ${books.length == 1 ? 'Book' : 'Books'} Found',
                      style: AppText.title(15, w: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Relevant',
                          style: AppText.label(
                            12,
                            w: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(Icons.expand_more_rounded,
                            size: 16, color: AppColors.textFaint),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // S10 loading: four skeleton cards until the first snapshot.
            if (!state.isHydrated)
              const Column(
                children: [
                  SkeletonCard(height: 92),
                  SizedBox(height: 10),
                  SkeletonCard(height: 92),
                  SizedBox(height: 10),
                  SkeletonCard(height: 92),
                  SizedBox(height: 10),
                  SkeletonCard(height: 92),
                ],
              )
            else if (books.isEmpty)
              const EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No matches',
                message:
                    'Nothing in the catalog matches that search. Try a '
                    'different term or search type.',
              )
            else ...[
              for (var i = 0; i < shown.length; i++) ...[
                StaggeredEntrance(
                  index: i + 5,
                  child: _CatalogCard(
                    book: shown[i],
                    onOpen: () => _openDetail(shown[i]),
                    onReserve: () => _reserve(shown[i]),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (!_showAll && books.length > shown.length)
                StaggeredEntrance(
                  index: 9,
                  child: PrimaryButton(
                    label: 'View all ${books.length} results',
                    icon: Icons.arrow_forward_rounded,
                    tone: ButtonTone.secondary,
                    onPressed: _openResults,
                  ),
                ),
            ],
            const SizedBox(height: 18),
            // Static, honest tip — the decorative barcode banner is gone
            // this cycle since scanning ISBNs isn't wired up (D-09).
            const StaggeredEntrance(
              index: 10,
              child: Callout(
                tone: CalloutTone.info,
                icon: Icons.lightbulb_outline_rounded,
                message:
                    'Tip: search by ISBN — paste the number from the back '
                    'cover to find an exact edition.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A catalog result card: cover, title, author, availability pill, shelf
/// line, and View Details / Reserve Copy actions.
class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.book,
    required this.onOpen,
    required this.onReserve,
  });

  final Book book;
  final VoidCallback onOpen;
  final VoidCallback onReserve;

  @override
  Widget build(BuildContext context) {
    final (pillColor, pillLabel) = switch (book.availability) {
      BookAvailability.available => (AppColors.success, 'Available'),
      BookAvailability.onLoan => (AppColors.error, 'On Loan'),
      BookAvailability.waitlisted => (AppColors.warning, 'Waitlist'),
    };
    final canReserve = book.availability == BookAvailability.available;

    return SurfaceCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(14),
      tint: pillColor.withValues(alpha: 0.20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookCover(
            title: book.title,
            color: book.coverColor,
            isbn: book.isbn,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title(14.5, w: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${book.author} · ${book.subject}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    StatusPill(
                      label: pillLabel,
                      color: pillColor,
                      icon: canReserve
                          ? Icons.check_rounded
                          : Icons.hourglass_bottom_rounded,
                      compact: true,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Shelf ${book.shelfLocation}',
                        style: AppText.body(11.5, color: AppColors.textFaint),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: OutlinedButton(
                          onPressed: onOpen,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            side: BorderSide(
                                color:
                                    AppColors.primary.withValues(alpha: 0.45)),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadii.sm),
                            ),
                            textStyle:
                                AppText.label(12.5, w: FontWeight.w700),
                          ),
                          child: const Text('View Details'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: canReserve ? onReserve : onOpen,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canReserve
                                ? AppColors.primary
                                : AppColors.surfaceMuted,
                            foregroundColor: canReserve
                                ? AppColors.textInverse
                                : AppColors.textSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadii.sm),
                            ),
                            textStyle:
                                AppText.label(12.5, w: FontWeight.w700),
                          ),
                          child: Text(
                            canReserve ? 'Reserve Copy' : 'Join Waitlist',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
