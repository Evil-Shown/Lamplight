import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
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
        title: const Text('Waitlist'),
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
              title: 'You\'re not waiting on anything',
              message:
                  'When a book or seat is unavailable, join the waitlist from its detail screen.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppNavInset.bottom,
              ),
              children: [
                const AlertBanner(
                  tone: AlertTone.success,
                  icon: Icons.notifications_active_outlined,
                  message: 'We\'ll notify you automatically when you\'re next in line.',
                ),
                const SizedBox(height: AppSpacing.md),
                ...entries.map((e) => _WaitlistCard(entry: e)),
              ],
            ),
    );
  }

  void _showInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How the waitlist works',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
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
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
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
    final icon = entry.type == WaitlistType.book
        ? Icons.menu_book_rounded
        : Icons.event_seat_rounded;

    return SoftCard(
      elevated: true,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: icon),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  entry.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              StatusChip(
                label: 'Position #${entry.position}',
                color: AppColors.primary,
              ),
            ],
          ),
          if (entry.estimatedWait != null) ...[
            const SizedBox(height: AppSpacing.md),
            InfoRow(
              icon: Icons.schedule_rounded,
              label: 'Estimated wait',
              value: '~${entry.estimatedWait!.inMinutes} minutes',
            ),
          ],
          if (entry.gracePeriodEndsAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AlertBanner(
              tone: AlertTone.danger,
              icon: Icons.timer_outlined,
              message:
                  'Claim within ${_countdown(entry.gracePeriodEndsAt!)} or the spot goes to the next person.',
            ),
          ],
          const SizedBox(height: AppSpacing.md),
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
