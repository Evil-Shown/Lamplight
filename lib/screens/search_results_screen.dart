import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/book_model.dart';
import 'book_details_screen.dart';
import '../widgets/book_card.dart';

const Color _bookFlowBackground = Color(0xFF141518);
const Color _bookFlowSurface = Color(0xFF22242A);
const Color _bookFlowBorder = Color(0xFF2E313A);
const Color _bookFlowAccent = Color(0xFFE8A838);
const Color _bookFlowTextPrimary = Colors.white;
final Color _bookFlowTextSecondary = Colors.grey[400]!;

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key, required this.query, this.books});

  final String query;
  final List<BookModel>? books;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late final TextEditingController _controller;

  static final List<BookModel> _fallbackBooks = [
    BookModel(
      id: 'clean-code',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      isbn: '',
      category: 'Software Engineering',
      description: 'Mock search result for clean code.',
      availableCopies: 3,
      shelfLocation: 'B2-14',
      coverUrl: '',
    ),
    BookModel(
      id: 'pragmatic-programmer',
      title: 'The Pragmatic Programmer',
      author: 'David Thomas, Andrew Hunt',
      isbn: '',
      category: 'Software Engineering',
      description: 'Mock search result for pragmatic programmer.',
      availableCopies: 0,
      shelfLocation: 'A1-08',
      coverUrl: '',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<BookModel> get _results {
    final books = widget.books;
    if (books != null && books.isNotEmpty) return books;
    return _fallbackBooks;
  }

  void _openPlaceholder(BookModel book) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookDetailsScreen(book: book),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final queryText = _controller.text.trim().isEmpty
        ? widget.query.trim()
        : _controller.text.trim();

    return Scaffold(
      backgroundColor: _bookFlowBackground,
      appBar: AppBar(
        backgroundColor: _bookFlowBackground,
        foregroundColor: _bookFlowTextPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Search Results'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _SearchSummaryBar(
              controller: _controller,
              onClear: () => setState(_controller.clear),
              onEdit: () {
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Showing ${results.length} result${results.length == 1 ? '' : 's'} for "$queryText"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _bookFlowTextSecondary,
                  ),
            ),
            const SizedBox(height: 18),
            ...results.asMap().entries.map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(
                      bottom: entry.key == results.length - 1 ? 0 : 12,
                    ),
                    child: BookCard(
                      book: entry.value,
                      onTap: () => _openPlaceholder(entry.value),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _SearchSummaryBar extends StatelessWidget {
  const _SearchSummaryBar({
    required this.controller,
    required this.onClear,
    required this.onEdit,
  });

  final TextEditingController controller;
  final VoidCallback onClear;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _bookFlowSurface,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: _bookFlowBorder),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 20, color: _bookFlowAccent),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: _bookFlowSurface,
                  border: InputBorder.none,
                  hintText: 'Search query',
                  hintStyle: TextStyle(color: _bookFlowTextSecondary),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _bookFlowTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                onSubmitted: (_) => onEdit(),
              ),
            ),
            const SizedBox(width: 8),
            if (controller.text.trim().isNotEmpty)
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(Icons.clear_rounded, size: 18),
                color: _bookFlowTextSecondary,
                onPressed: onClear,
              )
            else
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: _bookFlowAccent,
                onPressed: onEdit,
              ),
          ],
        ),
      ),
    );
  }
}