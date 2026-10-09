import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart' show AppStrings;
import '../../core/feedback/app_feedback.dart';
import '../../core/navigation/app_route.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/motion3d.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import 'book_detail_screen.dart';
import 'reservation_confirmation_screen.dart';
import 'search_results_screen.dart';

/// book-search-v2 "Library Catalog".
///
/// A discovery screen: large title, a glass search field, search-type and
/// availability chips, a shelf of tilted covers, then live result cards
/// with reserve actions and an honest "search by ISBN" tip.
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
    AppRoute.push(context, BookDetailScreen(book: book));
  }

  void _reserve(Book book) {
    final state = AppScope.read(context);
    final reservation = state.reserveBook(book);
    AppRoute.push(
      context,
      ReservationConfirmationScreen(
        book: book,
        reservation: reservation,
      ),
    );
  }

  void _openResults() {
    AppRoute.push(
      context,
      SearchResultsScreen(
        query: _controller.text.trim().isEmpty
            ? 'All titles'
            : _controller.text.trim(),
        searchType: _searchType.toUpperCase(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final books = _matches(state.books);
    final browsing = _controller.text.trim().isEmpty &&
        _availabilityFilters.isEmpty &&
        state.isHydrated;
    final shown = _showAll || _controller.text.trim().isNotEmpty
        ? books
        : books.take(4).toList();
    final shelf = books
        .where((b) => b.availability == BookAvailability.available)
        .toList();

    // Tab inside the shell: the shell paints the aurora, so stay transparent.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'LIBRARY CATALOG',
                          style: AppText.overline(11, color: AppColors.primary),
                        ),
                      ),
                      // Driven by the real last-synced timestamp (D-06).
                      Flexible(
                        child: LiveFreshness(lastSyncedAt: state.lastSyncedAt),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  StaggeredEntrance(
                    child: Text(
                      'Find your next read',
                      style: AppText.display(32, w: FontWeight.w800, ls: -1),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  GlassSurface(
                    radius: AppRadii.full,
                    padding: EdgeInsets.zero,
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) {
                        AppFeedback.tap();
                        _openResults();
                      },
                      style: AppText.body(15),
                      decoration: InputDecoration(
                        hintText: AppStrings.searchBooksHint,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.base, vertical: 16),
                        prefixIcon: Icon(Icons.search_rounded,
                            size: 22, color: AppColors.primary),
                        suffixIcon: _controller.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  AppFeedback.tap();
                                  setState(() {
                                    _controller.clear();
                                    _showAll = false;
                                  });
                                },
                              ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                children: [
                  StaggeredEntrance(
                    index: 1,
                    child: SegmentedTabs(
                      options: _searchTypes,
                      selected: _searchType,
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        AppFeedback.select();
                        setState(() => _searchType = value);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Same filter-chip language as the seat map (D-15).
                  StaggeredEntrance(
                    index: 2,
                    child: FilterChipRow(
                      options: _availabilityOptions,
                      selected: '',
                      isSelectedOf: _availabilityFilters.contains,
                      onSelected: (option) {
                        AppFeedback.select();
                        setState(() {
                          if (!_availabilityFilters.remove(option)) {
                            _availabilityFilters.add(option);
                          }
                        });
                      },
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  if (browsing && shelf.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    const SectionHeader(
                      title: 'Available now',
                      subtitle: 'Ready to reserve today',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    StaggeredEntrance(
                      index: 3,
                      child: _CoverShelf(books: shelf, onOpen: _openDetail),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  StaggeredEntrance(
                    index: 4,
                    child: SectionHeader(
                      title: browsing ? 'Popular on campus' : 'Results',
                      subtitle:
                          '${books.length} ${books.length == 1 ? 'book' : 'books'} found',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // S10 loading: four skeleton cards until the first snapshot.
                  if (!state.isHydrated)
                    const Column(
                      children: [
                        SkeletonCard(height: 92),
                        SizedBox(height: AppSpacing.md),
                        SkeletonCard(height: 92),
                        SizedBox(height: AppSpacing.md),
                        SkeletonCard(height: 92),
                        SizedBox(height: AppSpacing.md),
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
                      const SizedBox(height: AppSpacing.md),
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
                  const SizedBox(height: AppSpacing.lg),
                  // Static, honest tip: scanning ISBNs isn't wired up (D-09).
                  const StaggeredEntrance(
                    index: 10,
                    child: Callout(
                      tone: CalloutTone.info,
                      icon: Icons.lightbulb_outline_rounded,
                      message:
                          'Tip: search by ISBN. Paste the number from the back '
                          'cover to find an exact edition.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal shelf of covers with a slight 3D tilt.
class _CoverShelf extends StatelessWidget {
  const _CoverShelf({required this.books, required this.onOpen});

  final List<Book> books;
  final ValueChanged<Book> onOpen;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final book in books) ...[
            SizedBox(
              width: 108,
              child: PressScale(
                onTap: () => onOpen(book),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tilt3D(
                      maxTilt: 0.12,
                      lift: 8,
                      child: BookCover(
                        title: book.title,
                        color: book.coverColor,
                        isbn: book.isbn,
                        width: 108,
                        height: 152,
                        radius: AppRadii.sm,
                        heroTag: 'shelf-${book.id}',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title(13, w: FontWeight.w700),
                    ),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.base),
          ],
        ],
      ),
    );
  }
}

/// A catalog result card: cover, title, author, availability pill, shelf
/// tag, and one clear action (Reserve, or Join Waitlist when unavailable).
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
      BookAvailability.available => (
          AppColors.success,
          'Available · ${book.copiesAvailable} copies',
        ),
      BookAvailability.onLoan => (AppColors.error, 'On loan'),
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
            width: 56,
            height: 80,
            heroTag: 'book-${book.id}',
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title(15, w: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${book.author} · ${book.subject}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusPill(
                      label: pillLabel,
                      color: pillColor,
                      icon: canReserve
                          ? Icons.check_rounded
                          : Icons.hourglass_bottom_rounded,
                      compact: true,
                    ),
                    ShelfTag(book.shelfLocation),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                PressScale(
                  onTap: canReserve ? onReserve : onOpen,
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: canReserve
                          ? AppColors.primary
                          : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Text(
                      canReserve ? 'Reserve copy' : 'Join waitlist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label(
                        12.5,
                        w: FontWeight.w700,
                        color: canReserve
                            ? AppColors.textInverse
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
