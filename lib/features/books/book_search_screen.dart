import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import 'search_results_screen.dart';

/// book-search-v2 "Find a Book".
///
/// The search entry point: a query field, a search-type selector, the
/// submit button, and the popular-search shortcuts.
class BookSearchScreen extends StatefulWidget {
  const BookSearchScreen({super.key});

  @override
  State<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  final _controller = TextEditingController();
  String _searchType = 'TITLE';

  static const _searchTypes = ['TITLE', 'AUTHOR', 'ISBN', 'CATEGORY'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runSearch() {
    final query = _controller.text.trim();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(
          query: query.isEmpty ? 'All titles' : query,
          searchType: _searchType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final popular =
        AppScope.of(context).books.take(4).map((b) => b.title).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          children: [
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
                'What are you looking for?',
                style: AppText.body(14, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 20),
            StaggeredEntrance(
              index: 2,
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _runSearch(),
                decoration: InputDecoration(
                  hintText: AppStrings.searchBooksHint,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => setState(() => _controller.clear()),
                        ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 24),
            StaggeredEntrance(
              index: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Search type',
                      style: AppText.body(13.5, w: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final type in _searchTypes)
                        PressScale(
                          onTap: () => setState(() => _searchType = type),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                              color: _searchType == type
                                  ? AppColors.primarySoft
                                  : AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppRadii.full),
                              border: Border.all(
                                color: _searchType == type
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              type,
                              style: AppText.label(
                                12.5,
                                w: FontWeight.w600,
                                ls: 0.6,
                                color: _searchType == type
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            StaggeredEntrance(
              index: 4,
              child: PrimaryButton(label: 'SEARCH', onPressed: _runSearch),
            ),
            const SizedBox(height: 30),
            StaggeredEntrance(
              index: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Popular searches',
                      style: AppText.body(13.5, w: FontWeight.w600)),
                  const SizedBox(height: 12),
                  SurfaceCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < popular.length; i++) ...[
                          if (i > 0) const Divider(height: 1, indent: 16),
                          InkWell(
                            onTap: () {
                              _controller.text = popular[i];
                              _runSearch();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 15),
                              child: Row(
                                children: [
                                  const Icon(Icons.search_rounded,
                                      size: 18, color: AppColors.textFaint),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      popular[i],
                                      style: AppText.body(
                                        14,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded,
                                      size: 20, color: AppColors.textFaint),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
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
