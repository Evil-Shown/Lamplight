import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart' show AppNavInset;
import '../../../core/feedback/app_feedback.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../models/models.dart';
import 'widgets/staff_live_states.dart';
import 'widgets/staff_status_badge.dart';

/// Copies the library owns; falls back to the available count until the
/// document carries a total.
int _totalOf(Book b) {
  final t = b.totalCopies ?? b.copiesAvailable;
  return t < b.copiesAvailable ? b.copiesAvailable : t;
}

/// Staff-side book availability: live catalog with copy counts, quick
/// +/- adjustments (debounced), search, and add / edit in a glass sheet.
class StaffBooksScreen extends StatefulWidget {
  const StaffBooksScreen({super.key});

  @override
  State<StaffBooksScreen> createState() => _StaffBooksScreenState();
}

class _StaffBooksScreenState extends State<StaffBooksScreen> {
  static const _filters = ['All', 'Available', 'Low stock', 'All on loan'];
  static const _debounce = Duration(milliseconds: 600);

  final _search = TextEditingController();
  String _filter = 'All';

  /// Optimistic available counts waiting for their debounced write.
  final Map<String, int> _pending = {};
  final Map<String, Timer> _timers = {};

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _search.dispose();
    super.dispose();
  }

  int _availableOf(Book b) => _pending[b.id] ?? b.copiesAvailable;

  bool _matches(Book b) {
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty &&
        !(b.title.toLowerCase().contains(q) ||
            b.author.toLowerCase().contains(q) ||
            b.subject.toLowerCase().contains(q) ||
            b.isbn.toLowerCase().contains(q))) {
      return false;
    }
    final avail = _availableOf(b);
    final total = _totalOf(b);
    return switch (_filter) {
      'Available' => avail == total,
      'Low stock' => avail > 0 && avail < total,
      'All on loan' => avail == 0,
      _ => true,
    };
  }

  void _adjust(Book book, int delta) {
    final total = _totalOf(book);
    final next = (_availableOf(book) + delta).clamp(0, total).toInt();
    if (next == _availableOf(book)) return;
    setState(() => _pending[book.id] = next);
    _timers[book.id]?.cancel();
    _timers[book.id] = Timer(_debounce, () => _commit(book.id, next));
  }

  Future<void> _commit(String bookId, int available) async {
    _timers.remove(bookId);
    final state = AppScope.read(context);
    try {
      await state.setCopies(bookId, available: available);
    } catch (_) {
      if (!mounted) return;
      AppFeedback.error();
      _snack('Could not save the copy count. Try again.');
    }
    if (mounted && !_timers.containsKey(bookId)) {
      setState(() => _pending.remove(bookId));
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _openForm([Book? book]) async {
    final saved = await showGlassSheet<String>(
      context,
      builder: (context) => _BookFormSheet(book: book),
    );
    if (saved != null && mounted) _snack(saved);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final books = state.adminBooks;
    final visible = books.where(_matches).toList();

    return AppScaffold(
      title: 'Book Availability',
      contentUnderBar: true,
      actions: [
        IconButton(
          tooltip: 'Add a book',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: Icon(Icons.add_rounded, color: AppColors.primary),
          onPressed: () {
            AppFeedback.tap();
            _openForm();
          },
        ),
      ],
      body: Column(
        children: [
          SizedBox(height: GlassAppBar.contentTopPadding(context)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search title, author, subject or ISBN',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(_search.clear),
                      ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilterChipRow(
            options: _filters,
            selected: _filter,
            onSelected: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: StaffLiveGate(
              state: state,
              hasData: books.isNotEmpty,
              builder: (context) {
                if (books.isEmpty) {
                  return StaffScrollable(
                    state: state,
                    child: EmptyState(
                      icon: Icons.menu_book_rounded,
                      title: 'No books yet',
                      message:
                          'The catalog is empty. Add the first title to get started.',
                      actionLabel: 'Add a book',
                      onAction: _openForm,
                    ),
                  );
                }
                if (visible.isEmpty) {
                  return const StaffScrollableEmpty();
                }
                return StaffRefreshable(
                  state: state,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(AppSpacing.base,
                        AppSpacing.sm, AppSpacing.base, AppNavInset.bottom),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final b = visible[index];
                      return _BookCard(
                        book: b,
                        available: _availableOf(b),
                        total: _totalOf(b),
                        onAdjust: (delta) => _adjust(b, delta),
                        onEdit: () => _openForm(b),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// "No matches" block used when search or filter hides every title.
class StaffScrollableEmpty extends StatelessWidget {
  const StaffScrollableEmpty({super.key});

  @override
  Widget build(BuildContext context) => const EmptyState(
        icon: Icons.menu_book_rounded,
        title: 'No matches',
        message: 'No titles match this search or availability filter.',
      );
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.available,
    required this.total,
    required this.onAdjust,
    required this.onEdit,
  });

  final Book book;
  final int available;
  final int total;
  final void Function(int delta) onAdjust;
  final VoidCallback onEdit;

  String get _statusLabel => available == 0
      ? 'All on loan'
      : available == total
          ? 'Available'
          : 'Low stock';

  StaffBadgeTone get _tone => available == 0
      ? StaffBadgeTone.danger
      : available == total
          ? StaffBadgeTone.success
          : StaffBadgeTone.warning;

  Color get _barColor => switch (_tone) {
        StaffBadgeTone.success => AppColors.success,
        StaffBadgeTone.warning => AppColors.warning,
        StaffBadgeTone.danger => AppColors.error,
        _ => AppColors.info,
      };

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(
                title: book.title,
                color: book.coverColor,
                isbn: book.isbn,
                coverUrl: book.coverUrl,
                width: 52,
                height: 72,
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: AppText.title(15, w: FontWeight.w800),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      style: AppText.body(13, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    StaffStatusBadge(label: _statusLabel, tone: _tone),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit ${book.title}',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: Icon(Icons.edit_outlined,
                    size: 20, color: AppColors.textSecondary),
                onPressed: () {
                  AppFeedback.tap();
                  onEdit();
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '$available of $total copies available',
                  style: AppText.label(13,
                      w: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${total - available} on loan',
                style: AppText.label(12, w: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          MeterBar(
            value: total == 0 ? 0.0 : available / total,
            color: _barColor,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  'ISBN ${book.isbn}\nShelf ${book.shelfLocation}',
                  style: AppText.body(12, color: AppColors.textSecondary),
                ),
              ),
              _AdjustButton(
                icon: Icons.remove_rounded,
                tooltip: 'A copy was loaned out',
                onPressed: available > 0 ? () => onAdjust(-1) : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              _AdjustButton(
                icon: Icons.add_rounded,
                tooltip: 'A copy was returned',
                onPressed: available < total ? () => onAdjust(1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdjustButton extends StatelessWidget {
  const _AdjustButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: AppColors.primarySoft,
        foregroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.surface,
        disabledForegroundColor: AppColors.textFaint,
      ),
      onPressed: onPressed == null
          ? null
          : () {
              AppFeedback.select();
              onPressed!();
            },
    );
  }
}

/// Add / edit form. Pops with a confirmation message when saved.
class _BookFormSheet extends StatefulWidget {
  const _BookFormSheet({this.book});

  final Book? book;

  @override
  State<_BookFormSheet> createState() => _BookFormSheetState();
}

class _BookFormSheetState extends State<_BookFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.book?.title);
  late final _author = TextEditingController(text: widget.book?.author);
  late final _subject = TextEditingController(text: widget.book?.subject);
  late final _isbn = TextEditingController(text: widget.book?.isbn);
  late final _shelf = TextEditingController(text: widget.book?.shelfLocation);
  late final _copies = TextEditingController(
      text: widget.book == null ? '1' : '${_totalOf(widget.book!)}');
  bool _saving = false;
  String? _error;

  bool get _editing => widget.book != null;

  @override
  void dispose() {
    for (final c in [_title, _author, _subject, _isbn, _shelf, _copies]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<bool> _confirmReduction(int onLoan, int newTotal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reduce copies?'),
        content: Text(
            'Lowering the total to $newTotal removes copies from circulation. '
            '$onLoan ${onLoan == 1 ? 'copy is' : 'copies are'} currently on loan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reduce'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final state = AppScope.read(context);
    final old = widget.book;
    final total = int.parse(_copies.text.trim());

    var available = total;
    if (old != null) {
      final oldTotal = _totalOf(old);
      final onLoan = oldTotal - old.copiesAvailable;
      available = (total - onLoan).clamp(0, total).toInt();
      if (total < oldTotal && !await _confirmReduction(onLoan, total)) return;
    }
    if (!mounted) return;

    final book = Book(
      id: old?.id ?? '',
      title: _title.text.trim(),
      author: _author.text.trim(),
      subject: _subject.text.trim(),
      isbn: _isbn.text.trim(),
      availability:
          available > 0 ? BookAvailability.available : BookAvailability.onLoan,
      shelfLocation: _shelf.text.trim(),
      copiesAvailable: available,
      description: old?.description ?? '',
      dueDate: old?.dueDate,
      coverColor: old?.coverColor,
      totalCopies: total,
      createdAt: old?.createdAt,
    );

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_editing) {
        await state.editBook(book);
      } else {
        await state.addBook(book);
      }
      if (!mounted) return;
      AppFeedback.success();
      Navigator.of(context)
          .pop(_editing ? '${book.title} updated' : '${book.title} added');
    } catch (_) {
      if (!mounted) return;
      AppFeedback.error();
      setState(() {
        _saving = false;
        _error =
            'Could not save this book. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl + inset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_editing ? 'Edit book' : 'Add a book',
                style: AppText.title(20, w: FontWeight.w800)),
            const SizedBox(height: AppSpacing.base),
            _field(_title, 'Title', validator: _required),
            _field(_author, 'Author', validator: _required),
            _field(_subject, 'Subject', validator: _required),
            _field(_isbn, 'ISBN', validator: _required),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _field(
                    _copies,
                    'Total copies',
                    keyboard: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());
                      return (n == null || n < 1 || n > 999)
                          ? '1 to 999'
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _field(_shelf, 'Shelf', validator: _required)),
              ],
            ),
            if (_error != null) ...[
              Text(_error!, style: AppText.body(13, color: AppColors.error)),
              const SizedBox(height: AppSpacing.sm),
            ],
            PrimaryButton(
              label: _editing ? 'Save changes' : 'Add book',
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboard,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboard,
          validator: validator,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: label),
        ),
      );
}
