import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import 'staff_mock_data.dart';
import 'widgets/staff_status_badge.dart';

String _reservationStatusLabel(StaffReservationStatus status) => switch (
    status) {
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

    return Scaffold(
      appBar: AppBar(title: const Text('Reservations')),
      body: Column(
        children: [
          FilterChipBar(
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
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
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

  String _statusLabel(StaffReservationStatus status) =>
      _reservationStatusLabel(status);

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

    return SoftCard(
      elevated: true,
      color: _isExpired ? AppColors.errorSoft : null,
      onTap: () => _showDetails(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: _typeIcon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.studentName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      r.studentId,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              StaffStatusBadge(
                label: _statusLabel(r.status),
                tone: _tone,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: _isExpired
                  ? Colors.white.withValues(alpha: 0.6)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                SummaryRow(
                  label: isBook ? 'Book' : 'Seat',
                  value: r.itemTitle,
                ),
                SummaryRow(
                  label: 'Location / detail',
                  value: r.itemSubtitle,
                ),
                SummaryRow(
                  label: 'Reserved',
                  value: DateFormat('MMM d · h:mm a').format(r.reservedAt),
                ),
                if (r.dueAt != null)
                  SummaryRow(
                    label: isBook ? 'Pickup deadline' : 'Booking ends',
                    value:
                        DateFormat('MMM d · h:mm a').format(r.dueAt!),
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

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Reservation ${r.id}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  StaffStatusBadge(
                      label: _statusLabel(r.status), tone: _tone),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              InfoRow(
                  icon: Icons.person_rounded,
                  label: 'Student',
                  value: '${r.studentName} · ${r.studentId}'),
              InfoRow(
                  icon: _typeIcon,
                  label: isBook ? 'Book reserved' : 'Seat reserved',
                  value: r.itemTitle),
              InfoRow(
                  icon: Icons.place_rounded,
                  label: 'Detail',
                  value: r.itemSubtitle),
              InfoRow(
                  icon: Icons.schedule_rounded,
                  label: 'Reserved at',
                  value: DateFormat('EEE, MMM d · h:mm a').format(r.reservedAt)),
              if (r.dueAt != null)
                InfoRow(
                  icon: Icons.alarm_rounded,
                  label: isBook ? 'Pickup deadline' : 'Booking ends',
                  value: DateFormat('EEE, MMM d · h:mm a').format(r.dueAt!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
