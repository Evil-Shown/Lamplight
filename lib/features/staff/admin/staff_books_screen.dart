import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';
import 'staff_mock_data.dart';
import 'widgets/staff_status_badge.dart';

/// Staff-side book availability: catalog with copy counts and quick
/// check-in/check-out style adjustments on local mock state.
class StaffBooksScreen extends StatefulWidget {
  const StaffBooksScreen({super.key});

  @override
  State<StaffBooksScreen> createState() => _StaffBooksScreenState();
}

class _StaffBooksScreenState extends State<StaffBooksScreen> {
  static const _filters = ['All', 'Available', 'Low stock', 'All on loan'];

  String _filter = 'All';

  late final List<StaffBookEntry> _entries =
      List<StaffBookEntry>.from(StaffMockData.books);

  bool _matches(StaffBookEntry e) => switch (_filter) {
        'Available' => e.availableCopies == e.totalCopies,
        'Low stock' =>
          e.availableCopies > 0 && e.availableCopies < e.totalCopies,
        'All on loan' => e.availableCopies == 0,
        _ => true,
      };

  void _adjust(StaffBookEntry entry, int delta) {
    final index = _entries.indexOf(entry);
    if (index == -1) return;

    final next = (entry.availableCopies + delta)
        .clamp(0, entry.totalCopies)
        .toInt();
    if (next == entry.availableCopies) return;

    final updated = entry.copyWith(availableCopies: next);
    setState(() => _entries[index] = updated);
    // Keep the shared mock in sync so changes survive revisits (demo only).
    final mockIndex = StaffMockData.books.indexOf(entry);
    if (mockIndex != -1) StaffMockData.books[mockIndex] = updated;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _entries.where(_matches).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Book Availability')),
      body: Column(
        children: [
          FilterChipRow(
            options: _filters,
            selected: _filter,
            onSelected: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: visible.isEmpty
                ? const EmptyState(
                    icon: Icons.menu_book_rounded,
                    title: 'No matches',
                    message: 'No titles match this availability filter.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                        AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) => _BookCard(
                      entry: visible[index],
                      onAdjust: (delta) => _adjust(visible[index], delta),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.entry, required this.onAdjust});

  final StaffBookEntry entry;
  final void Function(int delta) onAdjust;

  String get _statusLabel => switch (entry.availableCopies) {
        0 => 'All on loan',
        _ when entry.availableCopies == entry.totalCopies => 'Available',
        _ => 'Low stock',
      };

  StaffBadgeTone get _tone => switch (entry.availableCopies) {
        0 => StaffBadgeTone.danger,
        _ when entry.availableCopies == entry.totalCopies =>
          StaffBadgeTone.success,
        _ => StaffBadgeTone.warning,
      };

  Color get _barColor => switch (_tone) {
        StaffBadgeTone.success => AppColors.success,
        StaffBadgeTone.warning => AppColors.warning,
        StaffBadgeTone.danger => AppColors.error,
        _ => AppColors.info,
      };

  @override
  Widget build(BuildContext context) {
    final book = entry.book;

    return SurfaceCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(
                title: book.title,
                color: book.coverColor,
                width: 52,
                height: 72,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    StaffStatusBadge(label: _statusLabel, tone: _tone),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${entry.availableCopies} of ${entry.totalCopies} copies available',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              Text(
                '${entry.totalCopies - entry.availableCopies} on loan',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          MeterBar(
            value: entry.totalCopies == 0
                ? 0.0
                : entry.availableCopies / entry.totalCopies,
            color: _barColor,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  'ISBN ${book.isbn}\nShelf ${book.shelfLocation}',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12, height: 1.5),
                ),
              ),
              _AdjustButton(
                icon: Icons.remove_rounded,
                tooltip: 'A copy was loaned out',
                onPressed:
                    entry.availableCopies > 0 ? () => onAdjust(-1) : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              _AdjustButton(
                icon: Icons.add_rounded,
                tooltip: 'A copy was returned',
                onPressed: entry.availableCopies < entry.totalCopies
                    ? () => onAdjust(1)
                    : null,
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
        minimumSize: const Size(44, 44),
        backgroundColor: AppColors.primarySoft,
        foregroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.surface,
        disabledForegroundColor: AppColors.textFaint,
      ),
      onPressed: onPressed,
    );
  }
}
