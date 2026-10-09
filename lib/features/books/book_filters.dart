import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart' show AppTouchTarget;
import '../../core/feedback/app_feedback.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/book_search.dart';

/// Catalogue filters chosen in the filter sheet.
class BookFilters {
  const BookFilters({
    this.subject,
    this.availableOnly = false,
    this.sort = BookSort.title,
  });

  final String? subject;
  final bool availableOnly;
  final BookSort sort;

  /// Filters that narrow the list (sort does not count).
  int get activeCount => (subject != null ? 1 : 0) + (availableOnly ? 1 : 0);

  BookFilters copyWith({
    String? subject,
    bool clearSubject = false,
    bool? availableOnly,
    BookSort? sort,
  }) =>
      BookFilters(
        subject: clearSubject ? null : (subject ?? this.subject),
        availableOnly: availableOnly ?? this.availableOnly,
        sort: sort ?? this.sort,
      );

  @override
  bool operator ==(Object other) =>
      other is BookFilters &&
      other.subject == subject &&
      other.availableOnly == availableOnly &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(subject, availableOnly, sort);
}

String bookSortLabel(BookSort s) => switch (s) {
      BookSort.title => 'Title A-Z',
      BookSort.author => 'Author A-Z',
      BookSort.newest => 'Newest',
      BookSort.availability => 'Most available',
    };

/// Opens the filter sheet. [onChanged] fires on every selection so the list
/// behind the sheet can update live.
Future<void> showBookFilterSheet(
  BuildContext context, {
  required BookFilters initial,
  required List<String> subjects,
  required ValueChanged<BookFilters> onChanged,
}) {
  return showGlassSheet<void>(
    context,
    builder: (_) => BookFilterSheet(
      initial: initial,
      subjects: subjects,
      onChanged: onChanged,
    ),
  );
}

class BookFilterSheet extends StatefulWidget {
  const BookFilterSheet({
    super.key,
    required this.initial,
    required this.subjects,
    required this.onChanged,
  });

  final BookFilters initial;
  final List<String> subjects;
  final ValueChanged<BookFilters> onChanged;

  @override
  State<BookFilterSheet> createState() => _BookFilterSheetState();
}

class _BookFilterSheetState extends State<BookFilterSheet> {
  late BookFilters _filters = widget.initial;

  void _set(BookFilters next) {
    setState(() => _filters = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Filter and sort',
                      style: AppText.title(18, w: FontWeight.w800)),
                ),
                TextButton(
                  onPressed: _filters == const BookFilters()
                      ? null
                      : () {
                          AppFeedback.tap();
                          _set(const BookFilters());
                        },
                  style: TextButton.styleFrom(
                      minimumSize: const Size(48, AppTouchTarget.minSize)),
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text('SUBJECT',
                style: AppText.overline(10.5, color: AppColors.textFaint)),
            const SizedBox(height: AppSpacing.sm),
            if (widget.subjects.isEmpty)
              Text('Subjects appear once the catalogue has loaded.',
                  style: AppText.body(13, color: AppColors.textSecondary))
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final s in widget.subjects)
                    ChoiceChip(
                      label: Text(s),
                      selected: _filters.subject == s,
                      onSelected: (on) {
                        AppFeedback.select();
                        _set(on
                            ? _filters.copyWith(subject: s)
                            : _filters.copyWith(clearSubject: true));
                      },
                    ),
                ],
              ),
            const SizedBox(height: AppSpacing.base),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Available now only',
                  style: AppText.title(14.5, w: FontWeight.w600)),
              value: _filters.availableOnly,
              onChanged: (v) {
                AppFeedback.toggle();
                _set(_filters.copyWith(availableOnly: v));
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('SORT BY',
                style: AppText.overline(10.5, color: AppColors.textFaint)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final s in BookSort.values)
                  ChoiceChip(
                    label: Text(bookSortLabel(s)),
                    selected: _filters.sort == s,
                    onSelected: (_) {
                      AppFeedback.select();
                      _set(_filters.copyWith(sort: s));
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Show results',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
