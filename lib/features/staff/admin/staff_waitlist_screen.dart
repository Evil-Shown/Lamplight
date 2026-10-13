import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart' show AppNavInset;
import '../../../core/feedback/app_feedback.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../models/models.dart';
import '../staff_actions.dart';
import 'widgets/staff_live_states.dart';
import 'widgets/staff_status_badge.dart';

String _statusLabel(WaitlistStatus s) => switch (s) {
      WaitlistStatus.waiting => 'Waiting',
      WaitlistStatus.offered => 'Offered',
      WaitlistStatus.accepted => 'Accepted',
      WaitlistStatus.declined => 'Declined',
      WaitlistStatus.expired => 'Expired',
    };

/// A wait past this many minutes is flagged.
const _longWait = Duration(minutes: 15);

/// "20m ago" / "2h 5m ago" / "3d ago".
String _ago(Duration d) {
  if (d.inMinutes < 60) return '${d.inMinutes < 0 ? 0 : d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ${d.inMinutes.remainder(60)}m ago';
  return '${d.inDays}d ago';
}

/// Mean wait of the entries still waiting, as "14m" / "1h 5m"; "—" when none.
String averageWaitLabel(Iterable<WaitlistEntry> entries, DateTime now) {
  final waiting = entries.where((e) => e.status == WaitlistStatus.waiting);
  if (waiting.isEmpty) return '—';
  final total = waiting.fold<int>(
      0, (sum, e) => sum + now.difference(e.joinedAt).inMinutes);
  final mean = (total / waiting.length).round().clamp(0, 1 << 30);
  return mean < 60 ? '${mean}m' : '${mean ~/ 60}h ${mean % 60}m';
}

/// Staff-side view of the shared book/seat waitlist (live). Offers are sent
/// by the server; staff can nudge a student with a message.
class StaffWaitlistScreen extends StatefulWidget {
  const StaffWaitlistScreen({super.key});

  @override
  State<StaffWaitlistScreen> createState() => _StaffWaitlistScreenState();
}

class _StaffWaitlistScreenState extends State<StaffWaitlistScreen> {
  static const _filters = [
    'All',
    'Waiting',
    'Offered',
    'Accepted',
    'Declined',
    'Expired',
  ];

  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final all = state.adminWaitlist;
    final now = DateTime.now();
    final entries = all
        .where(
            (w) => _filter == 'All' || _statusLabel(w.entry.status) == _filter)
        .toList()
      ..sort((a, b) => a.entry.joinedAt.compareTo(b.entry.joinedAt));
    final waiting =
        all.where((w) => w.entry.status == WaitlistStatus.waiting).length;
    final freeSeats = state.adminSeats
        .where((s) => s.status == SeatStatus.available)
        .length;

    return AppScaffold(
      title: 'Waiting List',
      contentUnderBar: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.base),
          child: Center(
            child: StatusPill(
                label: '$waiting in queue',
                color: AppColors.primary,
                compact: true),
          ),
        ),
      ],
      body: Column(
        children: [
          SizedBox(height: GlassAppBar.contentTopPadding(context)),
          Expanded(
            child: StaffLiveGate(
              state: state,
              hasData: all.isNotEmpty,
              builder: (context) => StaffRefreshable(
                state: state,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(AppSpacing.base,
                      AppSpacing.sm, AppSpacing.base, AppNavInset.bottom),
                  children: [
                    SurfaceCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Stat(label: 'IN LINE', value: '$waiting'),
                          _Stat(
                              label: 'AVG WAIT',
                              value: averageWaitLabel(
                                  all.map((w) => w.entry), now)),
                          _Stat(label: 'FREE SEATS', value: '$freeSeats'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.base),
                    Row(
                      children: [
                        Expanded(
                          child: Text('PRIORITY QUEUE',
                              style: AppText.overline(11.5)),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text('Sorted by wait time',
                              textAlign: TextAlign.end,
                              style: AppText.label(12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilterChipRow(
                      options: _filters,
                      selected: _filter,
                      onSelected: (f) => setState(() => _filter = f),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Callout(
                      tone: CalloutTone.info,
                      icon: Icons.info_outline_rounded,
                      message:
                          'Offers are sent automatically when a copy or seat frees up.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (entries.isEmpty)
                      EmptyState(
                        icon: Icons.hourglass_top_outlined,
                        title: all.isEmpty ? 'Queue is empty' : 'Nothing here',
                        message: all.isEmpty
                            ? 'No students are waiting for books or seats right now.'
                            : 'No waitlist entries match this filter.',
                      )
                    else
                      for (var i = 0; i < entries.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.md),
                        _WaitlistCard(
                            item: entries[i], index: i, now: now),
                      ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppText.display(26, w: FontWeight.w800,
                  color: AppColors.primary)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center, style: AppText.overline(10.5)),
        ],
      ),
    );
  }
}

class _WaitlistCard extends StatelessWidget {
  const _WaitlistCard(
      {required this.item, required this.index, required this.now});

  final AdminWaitlistItem item;
  final int index;
  final DateTime now;

  WaitlistEntry get _entry => item.entry;

  StaffBadgeTone get _tone => switch (_entry.status) {
        WaitlistStatus.waiting => StaffBadgeTone.neutral,
        WaitlistStatus.offered => StaffBadgeTone.info,
        WaitlistStatus.accepted => StaffBadgeTone.success,
        WaitlistStatus.declined => StaffBadgeTone.warning,
        WaitlistStatus.expired => StaffBadgeTone.danger,
      };

  void _notify(BuildContext context) {
    final e = _entry;
    final noun = e.type == WaitlistType.book ? 'book' : 'seat';
    showStaffNotifySheet(
      context,
      ownerUid: item.ownerUid,
      studentName: item.studentName,
      title: 'Waitlist update',
      initialMessage:
          'A $noun may be available soon for your waitlist request: ${e.title}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    final waited = now.difference(entry.joinedAt);
    final long = waited > _longWait;
    return SurfaceCard(
      onTap: () => _showDetails(context, item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
                child: Text(staffIndexLabel(index),
                    style: AppText.title(13, w: FontWeight.w800,
                        color: AppColors.primary)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title(15.5, w: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _ago(waited),
                      style: AppText.label(12.5,
                          w: long ? FontWeight.w700 : FontWeight.w600,
                          color:
                              long ? AppColors.warning : AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StaffStatusBadge(
                  label: _statusLabel(entry.status),
                  tone: _tone,
                  compact: true),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${entry.title} · ${entry.subtitle}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(13.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                    label: 'Notify', onPressed: () => _notify(context)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PrimaryButton(
                  label: 'Details',
                  tone: ButtonTone.secondary,
                  onPressed: () => _showDetails(context, item),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _showDetails(BuildContext context, AdminWaitlistItem item) {
  final e = item.entry;
  String stamp(DateTime d) => DateFormat('EEE, MMM d · h:mm a').format(d);
  showGlassSheet<void>(
    context,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Waitlist entry',
                style: AppText.title(20, w: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            StaffKVRow(label: 'Student', value: item.studentName),
            StaffKVRow(label: 'Student ID', value: item.studentId),
            StaffKVRow(
                label: 'Type',
                value: e.type == WaitlistType.book ? 'Book' : 'Seat'),
            StaffKVRow(label: 'Waiting for', value: e.title),
            StaffKVRow(label: 'Detail', value: e.subtitle),
            StaffKVRow(label: 'Status', value: _statusLabel(e.status)),
            StaffKVRow(label: 'Position', value: '#${e.position}'),
            StaffKVRow(label: 'Joined', value: stamp(e.joinedAt)),
            if ((e.seatPreference ?? '').isNotEmpty)
              StaffKVRow(label: 'Preference', value: e.seatPreference!),
            if (e.offerExpiresAt != null)
              StaffKVRow(
                  label: 'Offer expires', value: stamp(e.offerExpiresAt!)),
            const SizedBox(height: AppSpacing.base),
            PrimaryButton(
              label: 'Copy student ID',
              icon: Icons.copy_rounded,
              tone: ButtonTone.secondary,
              onPressed: item.studentId.isEmpty
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await Clipboard.setData(
                          ClipboardData(text: item.studentId));
                      AppFeedback.tap();
                      messenger.showSnackBar(
                          const SnackBar(content: Text('Student ID copied')));
                    },
            ),
          ],
        ),
      ),
    ),
  );
}
