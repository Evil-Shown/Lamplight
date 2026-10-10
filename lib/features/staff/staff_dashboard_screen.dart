import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart' show AppNavInset;
import '../../core/feedback/app_feedback.dart';
import '../../core/navigation/app_route.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/ledger_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import 'admin/widgets/staff_live_states.dart';
import '../../app_shell.dart' show AppShell, AppTab;
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
    final stats = state.dashboardStats;
    final loading = staffLoading(state);
    final failed = staffFailed(state) && state.queue.isEmpty;
    final queue = _filtered(state.queue);
    final waiting =
        state.queue.where((e) => e.status != QueueStatus.expired).length;

    // The staff shell already paints the aurora behind this tab.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: state.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.base,
                AppSpacing.base, AppNavInset.bottom),
            children: [
              // App-level cached-data banner (D-14).
              ConnectivityBanner(lastSyncedAt: state.lastSyncedAt),
              GlassSurface(
                radius: AppRadii.xl,
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Row(
                  children: [
                    const CampusMark(size: 44),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Staff Dashboard',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.title(18, w: FontWeight.w800),
                          ),
                          Text(
                            'Library Control Hub',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(12.5,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CountUp(
                          value: waiting,
                          style: AppText.display(AppText.displayLg,
                              w: FontWeight.w800, color: AppColors.primary),
                        ),
                        Text('in queue',
                            style: AppText.label(12, w: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.md),
                    PressScale(
                      onTap: () {
                        if (!AppShell.switchTab(context, AppTab.scan)) {
                          AppRoute.push(context, const StaffScannerScreen());
                        }
                      },
                      child: Tooltip(
                        message: 'Scan a pass',
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppGradients.hero,
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                          child: Icon(Icons.qr_code_scanner_rounded,
                              size: 24, color: AppColors.textInverse),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.base),
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
              const SizedBox(height: AppSpacing.base),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      label: 'Due today',
                      value: stats.reservationsDueToday,
                      caption: 'Book pickups',
                      color: AppColors.primary,
                      icon: Icons.confirmation_num_outlined,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: StatTile(
                      label: 'Waitlisted',
                      value: stats.waitingCount,
                      caption: 'Waiting for a book or seat',
                      color: AppColors.warning,
                      icon: Icons.hourglass_top_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      label: 'In session',
                      value: stats.activeSessions,
                      caption: 'Seated now',
                      color: AppColors.success,
                      icon: Icons.schedule_rounded,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: StatTile(
                      label: 'Seat fill',
                      value: stats.seatFillPercent,
                      suffix: '%',
                      caption:
                          '${stats.seatsOccupied} of ${stats.seatsTotal} seats',
                      color: AppColors.accent,
                      icon: Icons.event_seat_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
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
                          style: AppText.body(12, color: AppColors.textFaint),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              FilterChipRow(
                options: const ['All', 'Active', 'Urgent'],
                selected: _queueFilter,
                onSelected: (value) => setState(() => _queueFilter = value),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.base),
              if (loading)
                const Column(
                  children: [
                    SkeletonCard(height: 100),
                    SizedBox(height: AppSpacing.md),
                    SkeletonCard(height: 100),
                  ],
                )
              else if (failed)
                ErrorState(
                  message: state.lastError?.message ??
                      'We could not load the dispatch queue.',
                  onRetry: state.refresh,
                )
              else if (queue.isEmpty)
                const EmptyState(
                  icon: Icons.inbox_rounded,
                  title: 'Queue is clear',
                  message: 'No students waiting. Queue updates in real time.',
                )
              else
                for (var i = 0; i < queue.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  StaggeredEntrance(
                    index: i,
                    child: _QueueRow(
                      entry: queue[i],
                      onApprove: () => state.approveQueueEntry(queue[i].id),
                      onDismiss: () => state.dismissQueueEntry(queue[i].id),
                    ),
                  ),
                ],
            ],
          ),
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
  });

  final QueueEntry entry;
  final VoidCallback onApprove;
  final VoidCallback onDismiss;

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
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
                child: Text(
                  entry.studentName.isEmpty
                      ? '?'
                      : entry.studentName.substring(0, 1).toUpperCase(),
                  style: AppText.title(14, w: FontWeight.w700, color: color),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.studentName} ${entry.studentId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title(15, w: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.location} · waited ${waited.inMinutes}m',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(12.5, color: AppColors.textSecondary),
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
                  label: 'Copy ID',
                  icon: Icons.copy_rounded,
                  onTap: () => _showContact(context, entry),
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
                  onTap: entry.status == QueueStatus.expired
                      ? onDismiss
                      : onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Glass sheet with the student's identity and what can be done from the
/// device. A queue entry only carries name, ID and location (no phone or
/// email), and `url_launcher` is not a dependency, so copying the ID is the
/// working action.
void _showContact(BuildContext context, QueueEntry entry) {
  showGlassSheet<void>(
    context,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Copy student ID', style: AppText.title(20, w: FontWeight.w800)),
          const SizedBox(height: AppSpacing.base),
          Text(
              entry.studentName.isEmpty ? 'Unknown student' : entry.studentName,
              style: AppText.title(17, w: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
            entry.studentId.isEmpty ? 'No student ID on file' : entry.studentId,
            style: AppText.body(13.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(entry.location,
              style: AppText.body(13, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.base),
          Text(
            'No phone number or email is on file for this request. '
            'Use the student ID to look them up at the desk.',
            style: AppText.body(12.5, color: AppColors.textFaint),
          ),
          const SizedBox(height: AppSpacing.base),
          PrimaryButton(
            label: 'Copy student ID',
            icon: Icons.copy_rounded,
            onPressed: entry.studentId.isEmpty
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await Clipboard.setData(
                        ClipboardData(text: entry.studentId));
                    AppFeedback.success();
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                    messenger.showSnackBar(
                        const SnackBar(content: Text('Student ID copied')));
                  },
          ),
        ],
      ),
    ),
  );
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
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: effectiveTone.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: effectiveTone.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: effectiveTone),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(13.5,
                        w: FontWeight.w700, color: effectiveTone)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
