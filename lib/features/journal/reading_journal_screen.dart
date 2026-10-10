import 'package:flutter/material.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/shared_widgets.dart';

/// Reading Journal & Reflections screen inspired by Image 3 (Dual split linen & emerald island).
///
/// Features a split-canvas header, reflection notes, passage quotes,
/// and a rowboat journey indicator across calm waters.
class ReadingJournalScreen extends StatefulWidget {
  const ReadingJournalScreen({super.key});

  @override
  State<ReadingJournalScreen> createState() => _ReadingJournalScreenState();
}

class _ReadingJournalScreenState extends State<ReadingJournalScreen> {
  String _selectedFilter = 'All';

  final List<_JournalEntry> _entries = [
    _JournalEntry(
      bookTitle: 'Clean Architecture',
      author: 'Robert C. Martin',
      quote:
          'The only way to go fast is to go well. Every time you rush, you leave messes that slow you down.',
      page: 64,
      reflection:
          'Applied this mindset during today’s study block in the quiet stacks.',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      isQuote: true,
    ),
    _JournalEntry(
      bookTitle: 'The Design of Everyday Things',
      author: 'Don Norman',
      quote:
          'Good design is actually a lot harder to notice than poor design, in part because good designs fit our needs so well that the design is invisible.',
      page: 128,
      reflection:
          'Noticed this in the library reading room ergonomics and desk lighting.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isQuote: true,
    ),
    _JournalEntry(
      bookTitle: 'Deep Work',
      author: 'Cal Newport',
      quote:
          'Clarity about what matters provides clarity about what does not.',
      page: 89,
      reflection:
          'Turned off all notifications for 50 minutes at Desk D-14.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      isQuote: false,
    ),
  ];

  void _showAddReflectionDialog() {
    AppFeedback.tap();
    final quoteController = TextEditingController();
    final noteController = TextEditingController();
    final pageController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = AppColors.isDark;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B2B26) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadii.xl),
              ),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF163832)
                    : const Color(0xFFD8C9B6).withValues(alpha: 0.6),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF163832).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: Color(0xFF163832),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Record a Reading Insight',
                        style: AppText.title(18, w: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: quoteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Favorite Quote or Passage',
                    hintText: '“Stillness is where deep learning takes root...”',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: noteController,
                        decoration: InputDecoration(
                          labelText: 'Your Reflection',
                          hintText: 'Personal takeaway or idea',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: pageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Page #',
                          hintText: '42',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Save Reflection',
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: () {
                    final quote = quoteController.text.trim();
                    if (quote.isNotEmpty) {
                      setState(() {
                        _entries.insert(
                          0,
                          _JournalEntry(
                            bookTitle: 'Clean Code',
                            author: 'Robert C. Martin',
                            quote: quote,
                            page: int.tryParse(pageController.text) ?? 1,
                            reflection: noteController.text.trim().isEmpty
                                ? 'Reflected by lamplight'
                                : noteController.text.trim(),
                            createdAt: DateTime.now(),
                            isQuote: true,
                          ),
                        );
                      });
                      AppFeedback.success();
                    }
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF051F20)
          : const Color(0xFFF5F0E8),
      body: CustomScrollView(
        slivers: [
          // Split-Tone Scenic Header inspired by Image 3
          SliverToBoxAdapter(
            child: _DualCanvasHeader(
              onBack: () => Navigator.pop(context),
            ),
          ),

          // Journey Progress & Statistics Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin,
                vertical: AppSpacing.md,
              ),
              child: _RowboatProgressBar(),
            ),
          ),

          // Filter Pills & Add Button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin,
              ),
              child: Row(
                children: [
                  for (final f in ['All', 'Quotes', 'Notes']) ...[
                    PressScale(
                      onTap: () {
                        AppFeedback.tap();
                        setState(() => _selectedFilter = f);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedFilter == f
                              ? (isDark
                                  ? const Color(0xFF8EB69B)
                                  : const Color(0xFF163832))
                              : (isDark
                                  ? const Color(0xFF0B2B26)
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(AppRadii.full),
                          border: Border.all(
                            color: _selectedFilter == f
                                ? Colors.transparent
                                : (isDark
                                    ? const Color(0xFF163832)
                                    : const Color(0xFFD8C9B6)),
                          ),
                        ),
                        child: Text(
                          f,
                          style: AppText.label(
                            12,
                            w: FontWeight.w700,
                            color: _selectedFilter == f
                                ? (isDark
                                    ? const Color(0xFF051F20)
                                    : Colors.white)
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  PressScale(
                    onTap: _showAddReflectionDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF235347)
                            : const Color(0xFFDAF1DE),
                        borderRadius: BorderRadius.circular(AppRadii.full),
                        border: Border.all(
                          color: const Color(0xFF8EB69B).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: isDark
                                ? const Color(0xFFDAF1DE)
                                : const Color(0xFF163832),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'New Note',
                            style: AppText.label(
                              12,
                              w: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFDAF1DE)
                                  : const Color(0xFF163832),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.md),
          ),

          // Journal Entries List
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenMargin,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = _entries[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _JournalCard(entry: item),
                  );
                },
                childCount: _entries.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.scrollBottomInset),
          ),
        ],
      ),
    );
  }
}

class _JournalEntry {
  _JournalEntry({
    required this.bookTitle,
    required this.author,
    required this.quote,
    required this.page,
    required this.reflection,
    required this.createdAt,
    required this.isQuote,
  });

  final String bookTitle;
  final String author;
  final String quote;
  final int page;
  final String reflection;
  final DateTime createdAt;
  final bool isQuote;
}

/// Dual-tone Split Canvas Header featuring the user artwork.
class _DualCanvasHeader extends StatelessWidget {
  const _DualCanvasHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;

    return Stack(
      children: [
        // Art image container with rounded bottom corners
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(32),
          ),
          child: SizedBox(
            height: 240,
            width: double.infinity,
            child: Image.asset(
              'assets/images/dual_island.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF5F0E8), Color(0xFF163832)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Gradient overlay for legibility
        Positioned.fill(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                    (isDark ? const Color(0xFF051F20) : const Color(0xFF163832))
                        .withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Navigation & Headline Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenMargin,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PressScale(
                      onTap: () {
                        AppFeedback.tap();
                        onBack();
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadii.full),
                      ),
                      child: Text(
                        'DUAL HARMONY',
                        style: AppText.overline(
                          11,
                          ls: 1.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 38),
                Text(
                  'Reading Journal',
                  style: AppText.display(
                    28,
                    w: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reflections & memorable passages captured by lamplight',
                  style: AppText.body(
                    13,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Rowboat Journey progress bar representing reading across the calm lake.
class _RowboatProgressBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B2B26) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: isDark
              ? const Color(0xFF163832)
              : const Color(0xFFD8C9B6).withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sailing_rounded,
                size: 20,
                color: Color(0xFF806B59),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Current Journey: Clean Architecture',
                  style: AppText.label(13, w: FontWeight.w700),
                ),
              ),
              Text(
                '64 / 180 pgs',
                style: AppText.label(
                  12,
                  w: FontWeight.w700,
                  color: const Color(0xFF235347),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Water canal progress track
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.full),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF163832)
                        : const Color(0xFFE4F0E8),
                  ),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.35,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  child: Container(
                    height: 8,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF235347), Color(0xFF8EB69B)],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Rowing past Chapter 4 • 35% completed',
            style: AppText.body(
              11.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  const _JournalCard({required this.entry});

  final _JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B2B26) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: isDark
              ? const Color(0xFF163832)
              : const Color(0xFFD8C9B6).withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF163832).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  entry.bookTitle,
                  style: AppText.label(
                    11.5,
                    w: FontWeight.w700,
                    color: const Color(0xFF163832),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'pg. ${entry.page}',
                style: AppText.label(
                  11,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.bookmark_added_rounded,
                size: 16,
                color: Color(0xFF8EB69B),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            entry.quote,
            style: AppText.serif(
              14.5,
              w: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF5F0E8).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 15,
                  color: Color(0xFFD99246),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entry.reflection,
                    style: AppText.body(
                      12,
                      color: AppColors.textSecondary,
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
