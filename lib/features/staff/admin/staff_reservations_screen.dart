import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart' show AppNavInset;
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/shared_widgets.dart';
import 'staff_mock_data.dart';
import 'widgets/staff_status_badge.dart';

String _reservationStatusLabel(StaffReservationStatus status) =>
    switch (status) {
      StaffReservationStatus.active => 'Active',
      StaffReservationStatus.pickedUp => 'Picked up',
      StaffReservationStatus.expired => 'Expired',
      StaffReservationStatus.cancelled => 'Cancelled',
    };

/// Staff-side monitor of student reservations, with status filters and a
/// detail sheet per reservation.
class StaffReservationsScreen extends StatefulWidget {
  const StaffReservationsScreen({super.key, this.initialFilter = 'All'});

  final String initialFilter;

  @override
  State<StaffReservationsScreen> createState() =>
      _StaffReservationsScreenState();
}

class _StaffReservationsScreenState extends State<StaffReservationsScreen> {
  static const _filters = ['All', 'Active', 'Expired', 'Picked up', 'Cancelled'];

  late String _filter = _filters.contains(widget.initialFilter)
      ? widget.initialFilter
      : 'All';

  @override
  Widget build(BuildContext context) {
    final visible = StaffMockData.reservations
        .where((r) =>
            _filter == 'All' || _reservationStatusLabel(r.status) == _filter)
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
            child: visible.isEmpty
                ? const EmptyState(
                    icon: Icons.bookmark_border_rounded,
                    title: 'Nothing here',
                    message: 'No reservations match this filter.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.base,
                        AppSpacing.sm, AppSpacing.base, AppNavInset.bottom),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) =>
                        _ReservationCard(reservation: visible[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({required this.reservation});

  final StaffReservation reservation;

  bool get _isExpired => reservation.status == StaffReservationStatus.expired;

  IconData get _typeIcon => reservation.type == StaffReservationType.book
      ? Icons.menu_book_rounded
      : Icons.event_seat_rounded;

  StaffBadgeTone get _tone => switch (reservation.status) {
        StaffReservationStatus.active => StaffBadgeTone.success,
        StaffReservationStatus.pickedUp => StaffBadgeTone.info,
        StaffReservationStatus.expired => StaffBadgeTone.danger,
        StaffReservationStatus.cancelled => StaffBadgeTone.neutral,
      };

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final isBook = r.type == StaffReservationType.book;

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
                label: _reservationStatusLabel(r.status),
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
    final isBook = r.type == StaffReservationType.book;

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
                      'Reservation ${r.id}',
                      style: AppText.title(20, w: FontWeight.w800),
                    ),
                  ),
                  StaffStatusBadge(
                      label: _reservationStatusLabel(r.status), tone: _tone),
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
