import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart'
    show AppNavInset, AppStrings, AppTouchTarget;
import '../../core/feedback/app_feedback.dart';
import '../../core/navigation/app_route.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/motion3d.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import 'book_detail_screen.dart';
import 'book_filters.dart';
import 'reservation_confirmation_screen.dart';

/// book-search-v2 "Library Catalog".
///
/// A discovery screen: large title, a glass search field with a filter
/// button, a shelf of tilted covers, then result cards that page in from
/// the server as you scroll.
class BookSearchScreen extends StatefulWidget {
  const BookSearchScreen({super.key});

  @override
  State<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  static const _debounce = Duration(milliseconds: 300);
  static const _pageSize = 20;

  /// Distance from the end of the list at which the next page loads.
  static const _loadMoreExtent = 480.0;

  final _controller = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounceTimer;

  BookFilters _filters = const BookFilters();
  List<Book> _results = [];
  Object? _cursor;
  bool _hasMore = false;
  bool _loadingFirst = true;
  bool _loadingMore = false;
  bool _failed = false;
  bool? _wasHydrated;

  /// Bumped on every new query so late responses are dropped.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-run once when the first snapshot lands (demo data and subjects
    // only exist after that).
    final hydrated = AppScope.read(context).isHydrated;
    if (_wasHydrated != hydrated) {
      final first = _wasHydrated == null;
      _wasHydrated = hydrated;
      if (first) {
        _runSearch();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _runSearch();
        });
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _query => _controller.text.trim();
  bool get _browsing => _query.isEmpty && _filters.activeCount == 0;

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.extentAfter < _loadMoreExtent) _loadMore();
  }

  void _onQueryChanged(String _) {
    setState(() {}); // clear button
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, _runSearch);
  }

  Future<void> _runSearch() async {
    _debounceTimer?.cancel();
    final gen = ++_generation;
    final state = AppScope.read(context);
    setState(() {
      _loadingFirst = true;
      _loadingMore = false;
      _failed = false;
    });
    try {
      final page = await state.searchBooks(
        query: _query,
        subject: _filters.subject,
        availableOnly: _filters.availableOnly,
        sort: _filters.sort,
        pageSize: _pageSize,
      );
      if (!mounted || gen != _generation) return;
      setState(() {
        _results = page.books;
        _cursor = page.cursor;
        _hasMore = page.hasMore;
        _loadingFirst = false;
      });
    } catch (_) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _failed = true;
        _loadingFirst = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingFirst || _loadingMore || !_hasMore || _failed) return;
    final gen = _generation;
    final state = AppScope.read(context);
    setState(() => _loadingMore = true);
    try {
      final page = await state.searchBooks(
        query: _query,
        subject: _filters.subject,
        availableOnly: _filters.availableOnly,
        sort: _filters.sort,
        startAfter: _cursor,
        pageSize: _pageSize,
      );
      if (!mounted || gen != _generation) return;
      setState(() {
        _results = [..._results, ...page.books];
        _cursor = page.cursor;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _loadingMore = false;
        _hasMore = false;
      });
    }
  }

  void _applyFilters(BookFilters next) {
    if (next == _filters) return;
    setState(() => _filters = next);
    _runSearch();
  }

  /// Subjects seen in the loaded catalogue and in the current results.
  List<String> _subjects(AppState state) {
    final set = <String>{
      for (final b in state.books)
        if (b.subject.isNotEmpty) b.subject,
      for (final b in _results)
        if (b.subject.isNotEmpty) b.subject,
      if (_filters.subject != null) _filters.subject!,
    };
    return set.toList()..sort();
  }

  void _openFilters() {
    AppFeedback.tap();
    showBookFilterSheet(
      context,
      initial: _filters,
      subjects: _subjects(AppScope.read(context)),
      onChanged: _applyFilters,
    );
  }

  void _openDetail(Book book) {
    AppRoute.push(context, BookDetailScreen(book: book));
  }

  void _reserve(Book book) {
    final state = AppScope.read(context);
    final reservation = state.reserveBook(book);
    if (reservation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already reserved this book')),
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
  }

  Widget _skeletons() => const Column(
        children: [
          SkeletonCard(height: 92),
          SizedBox(height: AppSpacing.md),
          SkeletonCard(height: 92),
          SizedBox(height: AppSpacing.md),
          SkeletonCard(height: 92),
          SizedBox(height: AppSpacing.md),
          SkeletonCard(height: 92),
        ],
      );

  Widget _activeFilterChips() {
    final chips = <Widget>[
      if (_filters.subject != null)
        _FilterPill(
          label: _filters.subject!,
          clearLabel: 'Clear subject filter ${_filters.subject}',
          onClear: () => _applyFilters(_filters.copyWith(clearSubject: true)),
        ),
      if (_filters.availableOnly)
        _FilterPill(
          label: 'Available now',
          clearLabel: 'Clear available now filter',
          onClear: () => _applyFilters(_filters.copyWith(availableOnly: false)),
        ),
      if (_filters.sort != BookSort.title)
        _FilterPill(
          label: 'Sort: ${bookSortLabel(_filters.sort)}',
          clearLabel: 'Reset sort order',
          onClear: () => _applyFilters(_filters.copyWith(sort: BookSort.title)),
        ),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...chips,
          if (chips.length > 1)
            TextButton(
              onPressed: () {
                AppFeedback.tap();
                _applyFilters(const BookFilters());
              },
              style: TextButton.styleFrom(
                  minimumSize: const Size(48, AppTouchTarget.minSize)),
              child: const Text('Clear all'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final books = _results;
    final browsing = _browsing && state.isHydrated;
    final shelf = state.books
        .where((b) => b.availability == BookAvailability.available)
        .toList();

    // Tab inside the shell: the shell paints the aurora, so stay transparent.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ConnectivityBanner(lastSyncedAt: state.lastSyncedAt),
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
                      style: AppText.title(30, w: FontWeight.w800, ls: -0.6),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppGlass.cardFill,
                            borderRadius: BorderRadius.circular(AppRadii.full),
                            border: Border.all(color: AppGlass.border),
                            boxShadow: [
                              BoxShadow(
                                color: AppGlass.shadow,
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _controller,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) {
                              AppFeedback.tap();
                              _runSearch();
                            },
                            style: AppText.body(15),
                            decoration: InputDecoration(
                              hintText: AppStrings.searchBooksHint,
                              filled: false,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.base, vertical: 14),
                              prefixIcon: Icon(Icons.search_rounded,
                                  size: 22, color: AppColors.primary),
                              suffixIcon: _controller.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear search',
                                      icon: const Icon(Icons.close_rounded,
                                          size: 18),
                                      onPressed: () {
                                        AppFeedback.tap();
                                        _controller.clear();
                                        setState(() {});
                                        _runSearch();
                                      },
                                    ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            onChanged: _onQueryChanged,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Badge(
                        isLabelVisible: _filters.activeCount > 0,
                        label: Text('${_filters.activeCount}'),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _filters.activeCount > 0
                                ? AppColors.primary
                                : AppGlass.cardFill,
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            border: Border.all(
                              color: _filters.activeCount > 0
                                  ? AppColors.primary
                                  : AppGlass.border,
                            ),
                          ),
                          child: IconButton(
                            tooltip: 'Filter and sort',
                            icon: Icon(
                              Icons.tune_rounded,
                              size: 21,
                              color: _filters.activeCount > 0
                                  ? AppColors.textInverse
                                  : AppColors.primary,
                            ),
                            onPressed: _openFilters,
                          ),
                        ),
                      ),
                    ],
                  ),
                  _activeFilterChips(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await state.refresh();
                  if (mounted) await _runSearch();
                },
                child: ListView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, AppNavInset.bottom),
                  children: [
                    if (browsing) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                        height: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadii.card),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                  alpha: AppColors.isDark ? 0.35 : 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadii.card),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.asset(
                                  'assets/images/ancient_tree.jpg',
                                  fit: BoxFit.cover,
                                  alignment: const Alignment(0, -0.3),
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          Container(
                                    color: AppColors.surfaceMuted,
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        (AppColors.isDark
                                                ? const Color(0xFF140F0D)
                                                : const Color(0xFF1E293B))
                                            .withValues(alpha: 0.9),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      stops: const [0.55, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD3A376)
                                            .withValues(alpha: 0.25),
                                        borderRadius:
                                            BorderRadius.circular(AppRadii.full),
                                      ),
                                      child: Text(
                                        'FOREST OF STORIES',
                                        style: AppText.overline(
                                          10,
                                          ls: 1.0,
                                          color: const Color(0xFFFFE0B2),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Curated Campus Stacks',
                                      style: AppText.title(
                                        17,
                                        w: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Over 12,000 academic titles by lamplight',
                                      style: AppText.body(
                                        11.5,
                                        color: const Color(0xFFFFE0B2)
                                            .withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (browsing && shelf.isNotEmpty) ...[
                      const SectionHeader(
                        title: 'Available now',
                        subtitle: 'Ready to reserve today',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      StaggeredEntrance(
                        index: 1,
                        child: _CoverShelf(books: shelf, onOpen: _openDetail),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    StaggeredEntrance(
                      index: 2,
                      child: SectionHeader(
                        title: browsing ? 'Popular on campus' : 'Results',
                        subtitle: _loadingFirst
                            ? 'Searching…'
                            : '${books.length}${_hasMore ? '+' : ''} '
                                '${books.length == 1 ? 'book' : 'books'} found',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_failed)
                      ErrorState(onRetry: _runSearch)
                    else if (_loadingFirst && books.isEmpty ||
                        !state.isHydrated && books.isEmpty)
                      _skeletons()
                    else if (books.isEmpty)
                      EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No matches',
                        message:
                            'Nothing in the catalog matches that search. Try a '
                            'different term or loosen the filters.',
                        actionLabel:
                            _filters.activeCount > 0 ? 'Clear filters' : null,
                        onAction: _filters.activeCount > 0
                            ? () => _applyFilters(const BookFilters())
                            : null,
                      )
                    else ...[
                      for (var i = 0; i < books.length; i++) ...[
                        _CatalogCard(
                          book: books[i],
                          onOpen: () => _openDetail(books[i]),
                          onReserve: () => _reserve(books[i]),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (_loadingMore)
                        const SkeletonCard(height: 92)
                      else if (!_hasMore)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.base),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline_rounded,
                                  size: 16, color: AppColors.textFaint),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  'You have reached the end of the list',
                                  textAlign: TextAlign.center,
                                  style: AppText.body(12.5,
                                      color: AppColors.textFaint),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    // Static, honest tip: scanning ISBNs isn't wired up (D-09).
                    const Callout(
                      tone: CalloutTone.info,
                      icon: Icons.lightbulb_outline_rounded,
                      message:
                          'Tip: search by ISBN. Paste the number from the back '
                          'cover to find an exact edition.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Removable chip for one active filter; the whole pill is the 48 dp
/// clear target.
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.clearLabel,
    required this.onClear,
  });

  final String label;
  final String clearLabel;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: clearLabel,
      excludeSemantics: true,
      onTap: onClear,
      child: PressScale(
        onTap: onClear,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppTouchTarget.minSize),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(12.5,
                        w: FontWeight.w700, color: AppColors.primaryDark),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.close_rounded,
                    size: 16, color: AppColors.primaryDark),
              ],
            ),
          ),
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
                      child: Semantics(
                          image: true,
                          label: 'Cover of ${book.title}',
                          excludeSemantics: true,
                          child: BookCover(
                            title: book.title,
                            color: book.coverColor,
                            isbn: book.isbn,
                            coverUrl: book.coverUrl,
                            width: 108,
                            height: 152,
                            radius: AppRadii.sm,
                            heroTag: 'shelf-${book.id}',
                          )),
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
          Semantics(
              image: true,
              label: 'Cover of ${book.title}',
              excludeSemantics: true,
              child: BookCover(
                title: book.title,
                color: book.coverColor,
                isbn: book.isbn,
                coverUrl: book.coverUrl,
                width: 56,
                height: 80,
                heroTag: 'book-${book.id}',
              )),
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
                  onTap: () {
                    AppFeedback.tap();
                    if (canReserve) {
                      onReserve();
                    } else {
                      onOpen();
                    }
                  },
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: canReserve
                          ? AppColors.primary
                          : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      boxShadow: canReserve
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
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
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: canReserve
                              ? AppColors.textInverse
                              : AppColors.textSecondary,
                        ),
                      ],
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
