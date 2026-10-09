import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart' show AppNavInset;
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/state/app_state.dart';
import '../../../models/models.dart';
import 'widgets/staff_live_states.dart';
import 'widgets/staff_status_badge.dart';

/// The filter bucket a reservation falls in: 'Active', 'Expired',
/// 'Completed' or 'Cancelled'. A reservation still open past its deadline
/// counts as expired even before the server flips its status.
String staffReservationStatusLabel(AdminReservation r, [DateTime? now]) {
  switch (r.status) {
    case ReservationStatus.completed:
      return 'Completed';
    case ReservationStatus.cancelled:
      return 'Cancelled';
    case ReservationStatus.ready:
    case ReservationStatus.active:
    case ReservationStatus.expiringSoon:
      final due = r.dueAt;
      return due != null && due.isBefore(now ?? DateTime.now())
          ? 'Expired'
          : 'Active';
  }
}

/// Staff-side monitor of student reservations (live), with status filters,
/// pull-to-refresh and a detail sheet per reservation.
class StaffReservationsScreen extends StatefulWidget {
  const StaffReservationsScreen({super.key, this.initialFilter = 'All'});

  final String initialFilter;

  @override
  State<StaffReservationsScreen> createState() =>
      _StaffReservationsScreenState();
}

class _StaffReservationsScreenState extends State<StaffReservationsScreen> {
  static const _filters = ['All', 'Active', 'Expired', 'Completed', 'Cancelled'];

  late String _filter = _filters.contains(widget.initialFilter)
      ? widget.initialFilter
      : 'All';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final all = state.adminReservations;
    final now = DateTime.now();
    final visible = all
        .where((r) =>
            _filter == 'All' || staffReservationStatusLabel(r, now) == _filter)
        .toList();

    return AppScaffold(
      title: 'Reservations',
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
                            AppSpacing.sm, AppSpacing.base, AppNavInset.bottom),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) =>
                            _ReservationCard(reservation: visible[index]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({required this.reservation});

  final AdminReservation reservation;

  String get _label => staffReservationStatusLabel(reservation);

  bool get _isExpired => _label == 'Expired';

  IconData get _typeIcon =>
      reservation.isSeat ? Icons.event_seat_rounded : Icons.menu_book_rounded;

  StaffBadgeTone get _tone => switch (_label) {
        'Active' => StaffBadgeTone.success,
        'Completed' => StaffBadgeTone.info,
        'Expired' => StaffBadgeTone.danger,
        _ => StaffBadgeTone.neutral,
      };

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final isBook = !r.isSeat;

    return SurfaceCard(
      tint: _isExpired ? AppColors.error.withValues(alpha: 0.14) : null,
      onTap: () => _showDetails(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: _typeIcon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.studentName,
                      style: AppText.title(15, w: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      r.studentId,
                      style: AppText.body(13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              StaffStatusBadge(
                label: _label,
                tone: _tone,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _KVRow(
                    label: isBook ? 'Book' : 'Seat', value: r.itemTitle),
                _KVRow(label: 'Location / detail', value: r.itemSubtitle),
                _KVRow(
                  label: 'Reserved',
                  value: DateFormat('MMM d · h:mm a').format(r.reservedAt),
                ),
                if (r.dueAt != null)
                  _KVRow(
                    label: isBook ? 'Pickup deadline' : 'Booking ends',
                    value: DateFormat('MMM d · h:mm a').format(r.dueAt!),
                    valueColor: _isExpired ? AppColors.error : null,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final r = reservation;
    final isBook = !r.isSeat;

    showGlassSheet<void>(
      context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Reservation details',
                      style: AppText.title(20, w: FontWeight.w800),
                    ),
                  ),
                  StaffStatusBadge(
                      label: _label, tone: _tone),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _KVRow(label: 'Student', value: r.studentName),
              _KVRow(label: 'Student ID', value: r.studentId),
              _KVRow(label: 'Type', value: isBook ? 'Book' : 'Seat'),
              _KVRow(
                  label: isBook ? 'Book reserved' : 'Seat reserved',
                  value: r.itemTitle),
              _KVRow(label: 'Detail', value: r.itemSubtitle),
              _KVRow(
                  label: 'Reserved at',
                  value:
                      DateFormat('EEE, MMM d · h:mm a').format(r.reservedAt)),
              if (r.dueAt != null)
                _KVRow(
                  label: isBook ? 'Pickup deadline' : 'Booking ends',
                  value: DateFormat('EEE, MMM d · h:mm a').format(r.dueAt!),
                  valueColor: _isExpired ? AppColors.error : null,
                ),
              const SizedBox(height: AppSpacing.base),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: r.studentId.isEmpty
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await Clipboard.setData(
                              ClipboardData(text: r.studentId));
                          AppFeedback.tap();
                          messenger.showSnackBar(const SnackBar(
                              content: Text('Student ID copied')));
                        },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy student ID'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Label/value row used in reservation cards and the detail sheet.
class _KVRow extends StatelessWidget {
  const _KVRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: AppText.label(12, w: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppText.label(13,
                  w: FontWeight.w700,
                  color: valueColor ?? AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
