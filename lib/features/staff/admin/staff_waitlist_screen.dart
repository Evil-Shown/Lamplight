import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart' show AppNavInset;
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../models/models.dart';
import 'widgets/staff_live_states.dart';
import 'widgets/staff_status_badge.dart';

String _statusLabel(WaitlistStatus s) => switch (s) {
      WaitlistStatus.waiting => 'Waiting',
      WaitlistStatus.offered => 'Offered',
      WaitlistStatus.accepted => 'Accepted',
      WaitlistStatus.declined => 'Declined',
      WaitlistStatus.expired => 'Expired',
    };

/// Staff-side view of the shared book/seat waitlist (live, read-only).
///
/// The server promotes the queue and sends offers on its own, and AppState
/// has no staff method for notify / mark ready / remove, so those desk
/// actions are not offered rather than faked.
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
    final entries = all
        .where((w) =>
            _filter == 'All' || _statusLabel(w.entry.status) == _filter)
        .toList();

    return AppScaffold(
      title: 'Waiting List',
      contentUnderBar: true,
      body: Column(
        children: [
          SizedBox(height: GlassAppBar.contentTopPadding(context)),
          FilterChipRow(
            options: _filters,
            selected: _filter,
            onSelected: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: StaffLiveGate(
              state: state,
              hasData: all.isNotEmpty,
              builder: (context) => entries.isEmpty
                  ? StaffScrollable(
                      state: state,
                      child: EmptyState(
                        icon: Icons.hourglass_top_outlined,
                        title: all.isEmpty ? 'Queue is empty' : 'Nothing here',
                        message: all.isEmpty
                            ? 'No students are waiting for books or seats right now.'
                            : 'No waitlist entries match this filter.',
                      ),
                    )
                  : StaffRefreshable(
                      state: state,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(AppSpacing.base,
                            AppSpacing.sm, AppSpacing.base, AppNavInset.bottom),
                        itemCount: entries.length + 1,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) => index == 0
                            ? const Callout(
                                tone: CalloutTone.info,
                                icon: Icons.info_outline_rounded,
                                message:
                                    'Offers are sent automatically when a copy or seat frees up. '
                                    'Manual notify, mark ready and remove are not available yet.',
                              )
                            : _WaitlistCard(item: entries[index - 1]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitlistCard extends StatelessWidget {
  const _WaitlistCard({required this.item});

  final AdminWaitlistItem item;

  WaitlistEntry get _entry => item.entry;

  StaffBadgeTone get _tone => switch (_entry.status) {
        WaitlistStatus.waiting => StaffBadgeTone.neutral,
        WaitlistStatus.offered => StaffBadgeTone.info,
        WaitlistStatus.accepted => StaffBadgeTone.success,
        WaitlistStatus.declined => StaffBadgeTone.warning,
        WaitlistStatus.expired => StaffBadgeTone.danger,
      };

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    return SurfaceCard(
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
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.studentName,
                        style: AppText.title(15, w: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    StaffStatusBadge(
                        label: _statusLabel(entry.status),
                        tone: _tone,
                        compact: true),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.studentId,
                  style: AppText.body(13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  '${entry.title} · Position #${entry.position}',
                  style: AppText.label(13,
                      w: FontWeight.w700, color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Joined ${DateFormat('MMM d · h:mm a').format(entry.joinedAt)}',
                  style: AppText.body(12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
