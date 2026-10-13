import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../core/navigation/app_route.dart';
import '../../../core/state/app_state.dart';
import '../../../core/state/staff_logic.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../models/models.dart';
import '../extend_time_screen.dart';
import '../staff_actions.dart';
import 'widgets/staff_live_states.dart';
import 'widgets/staff_status_badge.dart';

export '../../../core/state/staff_logic.dart' show staffReservationStatusLabel;

/// Staff-side monitor of student reservations (live): search, state filters
/// with counts, per-state actions and a CSV export. Works as a shell tab
/// ([embedded]) or pushed.
class StaffReservationsScreen extends StatefulWidget {
  const StaffReservationsScreen(
      {super.key, this.initialFilter = 'All', this.embedded = false});

  final String initialFilter;

  /// True when shown as a shell tab (no back button); false when pushed.
  final bool embedded;

  @override
  State<StaffReservationsScreen> createState() =>
      _StaffReservationsScreenState();
}

class _StaffReservationsScreenState extends State<StaffReservationsScreen>
    with StaffClockMixin {
  static const _filters = [
    'All',
    'Active',
    'Pending',
    'Expired',
    'Completed',
    'Cancelled'
  ];

  /// Filters that show a count in their chip.
  static const _counted = {'All', 'Active', 'Pending', 'Expired'};

  final _search = TextEditingController();
  late String _filter =
      _filters.contains(widget.initialFilter) ? widget.initialFilter : 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(AdminReservation r) {
    final q = _search.text.trim().toLowerCase();
    return q.isEmpty ||
        r.studentName.toLowerCase().contains(q) ||
        r.studentId.toLowerCase().contains(q) ||
        r.itemTitle.toLowerCase().contains(q) ||
        r.itemSubtitle.toLowerCase().contains(q);
  }

  Future<void> _export(List<AdminReservation> rows) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(
        ClipboardData(text: buildReservationsCsv(rows, DateTime.now())));
    AppFeedback.success();
    messenger.showSnackBar(
        SnackBar(content: Text('Copied ${rows.length} rows as CSV')));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final all = state.adminReservations;
    final searched = all.where(_matches).toList();
    final counts = <String, int>{
      for (final f in _filters)
        f: searched
            .where(
                (r) => f == 'All' || staffReservationStatusLabel(r, now) == f)
            .length,
    };
    final visible = searched
        .where((r) =>
            _filter == 'All' || staffReservationStatusLabel(r, now) == _filter)
        .toList();
    needsSecondTicks = visible.any((r) => staffShowsGrace(r, now));

    String labelOf(String f) => _counted.contains(f) ? '$f (${counts[f]})' : f;
    final bottomInset =
        widget.embedded ? 0.0 : MediaQuery.paddingOf(context).bottom;

    return AppScaffold(
      title: 'Reservations',
      showBack: !widget.embedded,
      contentUnderBar: true,
      actions: [
        if (all.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.base),
            child: Center(
              child: StatusPill(
                  label: '${all.length} total',
                  color: AppColors.primary,
                  compact: true),
            ),
          ),
      ],
      body: Column(
        children: [
          SizedBox(height: GlassAppBar.contentTopPadding(context)),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.base, AppSpacing.sm, AppSpacing.base, 0),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search name, seat or ID',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(_search.clear),
                      ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ReservationFilters(
            filters: _filters,
            selected: _filter,
            labelOf: labelOf,
            onSelected: (filter) => setState(() => _filter = filter),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: StaffLiveGate(
              state: state,
              hasData: all.isNotEmpty,
              builder: (context) => visible.isEmpty
                  ? StaffScrollable(
                      state: state,
                      child: EmptyState(
                        icon: Icons.bookmark_border_rounded,
                        title: 'Nothing here',
                        message: all.isEmpty
                            ? 'No students have reserved a book or seat yet.'
                            : 'No reservations match this filter.',
                      ),
                    )
                  : StaffRefreshable(
                      state: state,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(AppSpacing.base,
                            AppSpacing.sm, AppSpacing.base, AppSpacing.base),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) => _ReservationCard(
                          reservation: visible[index],
                          index: index,
                          now: now,
                        ),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.sm,
                AppSpacing.base, AppSpacing.base + bottomInset),
            child: PrimaryButton(
              label: 'Export Log',
              icon: Icons.file_download_outlined,
              tone: ButtonTone.secondary,
              onPressed: visible.isEmpty ? null : () => _export(visible),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservationFilters extends StatelessWidget {
  const _ReservationFilters({
    required this.filters,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<String> filters;
  final String selected;
  final String Function(String) labelOf;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => FilterChipRow(
        options: filters.map(labelOf).toList(),
        selected: labelOf(selected),
        isSelectedOf: (optionLabel) =>
            filters.any((f) => f == selected && labelOf(f) == optionLabel),
        onSelected: (optionLabel) {
          final match = filters.firstWhere(
            (f) => labelOf(f) == optionLabel,
            orElse: () => selected,
          );
          if (match != selected) onSelected(match);
        },
      );
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({
    required this.reservation,
    required this.index,
    required this.now,
  });

  final AdminReservation reservation;
  final int index;
  final DateTime now;

  Widget _buttons(BuildContext context, StaffResState s) {
    final r = reservation;
    Widget pair(String a, VoidCallback onA, ButtonTone toneA, String b,
        VoidCallback onB,
        [ButtonTone toneB = ButtonTone.secondary]) {
      return Row(
        children: [
          Expanded(child: PrimaryButton(label: a, tone: toneA, onPressed: onA)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: PrimaryButton(label: b, tone: toneB, onPressed: onB)),
        ],
      );
    }

    void details() => showStaffReservationDetails(context, r, now: now);
    void alert() => staffNotifyReservation(context, r, now: now);
    const primary = ButtonTone.primary;

    switch (s) {
      case StaffResState.completed:
      case StaffResState.cancelled:
        return PrimaryButton(
            label: 'Details', tone: ButtonTone.secondary, onPressed: details);
      case StaffResState.active:
        return pair(
            'Extend',
            () => AppRoute.push(context, ExtendTimeScreen(reservation: r)),
            primary,
            'Monitor',
            details);
      case StaffResState.pending:
        return r.isSeat
            ? pair('Check In', () => staffCheckInAction(context, r), primary,
                'Cancel', () => staffCancelAction(context, r))
            : pair('Details', details, primary, 'Cancel',
                () => staffCancelAction(context, r));
      case StaffResState.expired:
        return r.isSeat
            ? pair('Release Seat', () => staffReleaseAction(context, r),
                ButtonTone.danger, 'Alert', alert)
            : pair('Details', details, primary, 'Alert', alert);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final s = staffReservationState(r, now);
    final color = staffStateColor(s);
    final since = staffContextNote(r, now);

    return SurfaceCard(
      color: AppColors.surface,
      borderColor: s == StaffResState.expired
          ? AppColors.error.withValues(alpha: 0.32)
          : AppColors.border,
      onTap: () => showStaffReservationDetails(context, r, now: now),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StaffIndexChip(staffIndexLabel(index)),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            r.studentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.title(15.5, w: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${r.itemTitle} · ${r.itemSubtitle}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                flex: 2,
                child: StaffStatusBadge(
                  label: staffStateLabel(r, s),
                  tone: staffStateTone(s),
                  compact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: AppColors.isDark ? 0.16 : 0.10),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded, size: 17, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    staffTimeNote(r, now),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(13, w: FontWeight.w700, color: color),
                  ),
                ),
                if (since.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      since,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: AppText.label(12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buttons(context, s),
        ],
      ),
    );
  }
}
