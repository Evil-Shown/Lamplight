import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import 'staff_mock_data.dart';
import 'widgets/staff_status_badge.dart';

/// Staff-side view of the shared book/seat waitlist queues with simple
/// desk actions (notify, mark ready, remove) on mock data.
class StaffWaitlistScreen extends StatefulWidget {
  const StaffWaitlistScreen({super.key});

  @override
  State<StaffWaitlistScreen> createState() => _StaffWaitlistScreenState();
}

class _StaffWaitlistScreenState extends State<StaffWaitlistScreen> {
  @override
  Widget build(BuildContext context) {
    final entries = List<StaffWaitlistItem>.from(StaffMockData.waitlist);

    return Scaffold(
      appBar: AppBar(title: const Text('Waiting List')),
      body: entries.isEmpty
          ? const EmptyState(
              icon: Icons.hourglass_top_outlined,
              title: 'Queue is empty',
              message: 'No students are waiting for books or seats right now.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _WaitlistCard(
                entry: entries[index],
                onChanged: () => setState(() {}),
              ),
            ),
    );
  }
}

class _WaitlistCard extends StatelessWidget {
  const _WaitlistCard({required this.entry, required this.onChanged});

  final StaffWaitlistItem entry;
  final VoidCallback onChanged;

  String get _statusLabel => switch (entry.status) {
        StaffWaitlistStatus.waiting => 'Waiting',
        StaffWaitlistStatus.notified => 'Notified',
        StaffWaitlistStatus.ready => 'Ready',
      };

  StaffBadgeTone get _tone => switch (entry.status) {
        StaffWaitlistStatus.waiting => StaffBadgeTone.neutral,
        StaffWaitlistStatus.notified => StaffBadgeTone.info,
        StaffWaitlistStatus.ready => StaffBadgeTone.success,
      };

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      elevated: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(
            icon: entry.type == WaitlistType.book
                ? Icons.menu_book_rounded
                : Icons.event_seat_rounded,
            color: entry.type == WaitlistType.book
                ? AppColors.primary
                : AppColors.info,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.studentName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StaffStatusBadge(label: _statusLabel, tone: _tone, compact: true),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  entry.studentId,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  '${entry.itemTitle} · Position #${entry.position}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Joined ${DateFormat('MMM d · h:mm a').format(entry.joinedAt)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Desk actions',
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.textSecondary),
            onSelected: (action) => _handleAction(context, action),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'notify',
                child: ListTile(
                  leading: Icon(Icons.notifications_outlined),
                  title: Text('Notify student'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'ready',
                child: ListTile(
                  leading: Icon(Icons.check_circle_outline_rounded),
                  title: Text('Mark as ready'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'remove',
                child: ListTile(
                  leading: Icon(Icons.delete_outline_rounded),
                  title: Text('Remove from waitlist'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'notify':
        _updateStatus(StaffWaitlistStatus.notified);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${entry.studentName} notified by app alert')),
        );
      case 'ready':
        _updateStatus(StaffWaitlistStatus.ready);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${entry.itemTitle} marked ready for ${entry.studentName}')),
        );
      case 'remove':
        _confirmRemove(context);
    }
  }

  void _updateStatus(StaffWaitlistStatus status) {
    final index = StaffMockData.waitlist.indexOf(entry);
    if (index != -1) {
      StaffMockData.waitlist[index] = entry.copyWith(status: status);
    }
    onChanged();
  }

  void _confirmRemove(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove from waitlist?'),
        content: Text(
            '${entry.studentName} will lose position #${entry.position} for ${entry.itemTitle}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(0, 40),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              StaffMockData.waitlist.remove(entry);
              _renumberQueues();
              onChanged();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('${entry.studentName} removed from the waitlist')),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  /// Keep queue positions contiguous after a removal.
  void _renumberQueues() {
    for (final type in WaitlistType.values) {
      final ofType = StaffMockData.waitlist
          .where((w) => w.type == type)
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));
      for (var i = 0; i < ofType.length; i++) {
        final index = StaffMockData.waitlist.indexOf(ofType[i]);
        StaffMockData.waitlist[index] = ofType[i].copyWith(position: i + 1);
      }
    }
  }
}
