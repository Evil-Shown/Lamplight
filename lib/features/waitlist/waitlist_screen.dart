import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ledger_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/mock/mock_data.dart';
import '../../models/models.dart';

class WaitlistScreen extends StatelessWidget {
  const WaitlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = MockData.waitlistEntries;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 84,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('YOUR QUEUE'),
            const SizedBox(height: 3),
            Text('Waitlist', style: AppText.serif(24)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'How waitlist works',
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showInfo(context),
          ),
        ],
      ),
      body: entries.isEmpty
          ? const EmptyState(
              icon: Icons.hourglass_empty_rounded,
              title: "You're not waiting on anything",
              message:
                  'When a book or seat is unavailable, join the waitlist from its detail screen.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppNavInset.bottom,
              ),
              children: [
                const AlertBanner(
                  tone: AlertTone.success,
                  icon: Icons.notifications_active_outlined,
                  message:
                      "We'll notify you automatically the moment you reach the front.",
                ),
                const SizedBox(height: AppSpacing.md),
                ...entries.map((e) => _WaitlistCard(entry: e)),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Text(
                    '— end of your queue —',
                    style: AppText.serif(14,
                        w: FontWeight.w500, italic: true, color: AppColors.textFaint),
                  ),
                ),
              ],
            ),
    );
  }

  void _showInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding:
            const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How the waitlist works', style: AppText.serif(20)),
            const SizedBox(height: AppSpacing.lg),
            const _InfoBullet(
              icon: Icons.person_add_alt_1_rounded,
              text: 'Join when a book or seat is full.',
            ),
            const _InfoBullet(
              icon: Icons.notifications_active_outlined,
              text: 'The next person is notified automatically.',
            ),
            const _InfoBullet(
              icon: Icons.timer_outlined,
              text: 'A grace countdown shows before the spot is released.',
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _InfoBullet extends StatelessWidget {
  const _InfoBullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          IconBadge(icon: icon, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(text, style: AppText.sans(14, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

class _WaitlistCard extends StatelessWidget {
  const _WaitlistCard({required this.entry});

  final WaitlistEntry entry;

  @override
  Widget build(BuildContext context) {
    final isBook = entry.type == WaitlistType.book;
    final icon = isBook ? Icons.menu_book_rounded : Icons.event_seat_rounded;

    final coverBook = MockData.books
        .where((b) => b.title == entry.title)
        .firstOrNull;

    return TicketCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isBook && coverBook != null)
                BookCover(
                  title: coverBook.title,
                  color: coverBook.coverColor,
                  isbn: coverBook.isbn,
                  width: 44,
                  height: 60,
                )
              else
                IconBadge(
                  icon: icon,
                  color: isBook ? AppColors.stampRed : AppColors.inkSoft,
                  size: 46,
                ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.title, style: AppText.serif(16.5, ls: -0.2)),
                    const SizedBox(height: 2),
                    Text(
                      isBook
                          ? 'By ${MockData.books.where((b) => b.title == entry.title).firstOrNull?.author ?? 'the author'}'
                          : 'Any available desk',
                      style: AppText.sans(12.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusChip(
                label: 'Pos. ${entry.position}',
                color: AppColors.inkSoft,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const DashedRule(),
          const SizedBox(height: AppSpacing.sm + 2),
          if (entry.estimatedWait != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Estimated wait ',
                    style: AppText.sans(13, color: AppColors.textSecondary),
                  ),
                  Text(
                    '~${entry.estimatedWait!.inMinutes} minutes',
                    style: AppText.sans(13, w: FontWeight.w700),
                  ),
                ],
              ),
            ),
          if (entry.gracePeriodEndsAt != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
              child: AlertBanner(
                tone: AlertTone.danger,
                icon: Icons.timer_outlined,
                message:
                    'Claim within ${_countdown(entry.gracePeriodEndsAt!)} or it passes to the next reader.',
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Left waitlist.')),
                );
              },
              child: const Text('Leave waitlist'),
            ),
          ),
        ],
      ),
    );
  }

  String _countdown(DateTime deadline) {
    final diff = deadline.difference(DateTime.now());
    if (diff.isNegative) return '0:00';
    return '${diff.inMinutes}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}
