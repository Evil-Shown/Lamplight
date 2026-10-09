import 'package:flutter/material.dart';

import '../../core/navigation/app_route.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ledger_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/mock/mock_data.dart';
import '../../models/models.dart';
import 'staff_scanner_screen.dart';

/// P-13 Staff Dashboard.
///
/// The staff home: a search field over the queue, four stat tiles, and the
/// dispatch list with per-entry actions.
class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  final _searchController = TextEditingController();
  String _queueFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<QueueEntry> _filtered(List<QueueEntry> queue) {
    final q = _searchController.text.trim().toLowerCase();
    return queue.where((entry) {
      final matchesQuery = q.isEmpty ||
          entry.studentName.toLowerCase().contains(q) ||
          entry.location.toLowerCase().contains(q);
      final matchesFilter = switch (_queueFilter) {
        'Active' => entry.status == QueueStatus.active,
        'Urgent' => entry.status == QueueStatus.pending,
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    const stats = MockData.dashboardStats;
    final queue = _filtered(state.queue);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            // App-level cached-data banner (D-14).
            ConnectivityBanner(lastSyncedAt: state.lastSyncedAt),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    decoration: BoxDecoration(
                      gradient: AppGradients.hero,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Row(
                      children: [
                        const CampusMark(size: 36, onDark: true),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Staff Dashboard',
                                style: AppText.title(16, w: FontWeight.w700,
                                    color: AppColors.textInverse),
                              ),
                              Text(
                                'Library Control Hub',
                                style: AppText.body(11.5,
                                    color: AppColors.textInverse
                                        .withValues(alpha: 0.66)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => AppRoute.push(
                    context,
                    const StaffScannerScreen(),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    side: BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search students or locations',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () =>
                            setState(() => _searchController.clear()),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'Reservations',
                    value: stats['reservations']!,
                    caption: '+4 today',
                    color: AppColors.primary,
                    icon: Icons.confirmation_num_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    label: 'Waitlisted',
                    value: stats['waitlisted']!,
                    caption: '3 expired',
                    color: AppColors.warning,
                    icon: Icons.hourglass_top_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'On-time',
                    value: stats['onTime']!,
                    suffix: '%',
                    caption: 'Excellent',
                    color: AppColors.success,
                    icon: Icons.schedule_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    label: 'Seat fill',
                    value: stats['seatFill']!,
                    suffix: '%',
                    caption: 'Moderate',
                    color: AppColors.accent,
                    icon: Icons.event_seat_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dispatch queue · ${queue.length}',
                          style: AppText.title(15.5, w: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        'Updates in real time',
                        style: AppText.body(11.5, color: AppColors.textFaint),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilterChipRow(
              options: const ['All', 'Active', 'Urgent'],
              selected: _queueFilter,
              onSelected: (value) => setState(() => _queueFilter = value),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 14),
            if (queue.isEmpty)
              const EmptyState(
                icon: Icons.inbox_rounded,
                title: 'Queue is clear',
                message:
                    'No students waiting. Queue updates in real time.',
              )
            else
              for (var i = 0; i < queue.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                StaggeredEntrance(
                  index: i,
                  child: _QueueRow(
                    entry: queue[i],
                    onApprove: () => state.approveQueueEntry(queue[i].id),
                    onDismiss: () => state.dismissQueueEntry(queue[i].id),
                    onWarn: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${queue[i].studentName} warned')),
                    ),
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({
    required this.entry,
    required this.onApprove,
    required this.onDismiss,
    required this.onWarn,
  });

  final QueueEntry entry;
  final VoidCallback onApprove;
  final VoidCallback onDismiss;
  final VoidCallback onWarn;

  (Color, String) get _status => switch (entry.status) {
        QueueStatus.active => (AppColors.success, 'Active'),
        QueueStatus.pending => (AppColors.warning, 'Pending'),
        QueueStatus.expired => (AppColors.error, 'Expired'),
      };

  @override
  Widget build(BuildContext context) {
    final (color, label) = _status;
    final waited = DateTime.now().difference(entry.requestedAt);

    return SurfaceCard(
      tint: color.withValues(alpha: 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
                child: Text(
                  entry.studentName.substring(0, 1).toUpperCase(),
                  style:
                      AppText.title(14, w: FontWeight.w700, color: color),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.studentName} ${entry.studentId}',
                      style: AppText.title(14, w: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.location} · waited ${waited.inMinutes}m',
                      style:
                          AppText.body(12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              StatusPill(label: label, color: color, compact: true),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _RowAction(
                  label: 'Contact',
                  icon: Icons.phone_outlined,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RowAction(
                  label: entry.status == QueueStatus.expired
                      ? 'Dismiss'
                      : 'Approve',
                  icon: entry.status == QueueStatus.expired
                      ? Icons.close_rounded
                      : Icons.check_rounded,
                  tone: entry.status == QueueStatus.expired
                      ? AppColors.error
                      : AppColors.success,
                  onTap:
                      entry.status == QueueStatus.expired ? onDismiss : onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.tone,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final effectiveTone = tone ?? AppColors.primary;
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: effectiveTone.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.xs),
          border: Border.all(color: effectiveTone.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: effectiveTone),
            const SizedBox(width: 6),
            Text(label,
                style: AppText.label(
                    12.5, w: FontWeight.w600, color: effectiveTone)),
          ],
        ),
      ),
    );
  }
}
