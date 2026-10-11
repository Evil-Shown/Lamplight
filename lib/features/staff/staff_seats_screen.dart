import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import 'staff_mock_data.dart';
import 'widgets/staff_status_badge.dart';

/// Staff-side seat availability: floor filter, live status grid and a
/// status editor per seat on local mock state.
class StaffSeatsScreen extends StatefulWidget {
  const StaffSeatsScreen({super.key});

  @override
  State<StaffSeatsScreen> createState() => _StaffSeatsScreenState();
}

class _StaffSeatsScreenState extends State<StaffSeatsScreen> {
  String _floorFilter = 'All';

  late final List<Seat> _seats = List<Seat>.from(StaffMockData.seats);

  @override
  Widget build(BuildContext context) {
    final visible = _seats
        .where((s) => _floorFilter == 'All' || 'Floor ${s.floor}' == _floorFilter)
        .toList();
    final available =
        _seats.where((s) => s.status == SeatStatus.available).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seat Availability'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: StaffStatusBadge(
                label: '$available of ${_seats.length} free',
                tone: available > 0
                    ? StaffBadgeTone.success
                    : StaffBadgeTone.danger,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          FilterChipBar(
            options: const ['All', 'Floor 1', 'Floor 2'],
            selected: _floorFilter,
            onSelected: (f) => setState(() => _floorFilter = f),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _SeatLegend(),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: visible.isEmpty
                ? const EmptyState(
                    icon: Icons.event_seat_rounded,
                    title: 'No seats',
                    message: 'No seats match this floor filter.',
                  )
                : LayoutBuilder(builder: (context, constraints) {
                    final columns =
                        (constraints.maxWidth / 104).clamp(3, 8).round();
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                          AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: AppSpacing.sm,
                        crossAxisSpacing: AppSpacing.sm,
                        childAspectRatio: 1.18,
                      ),
                      itemCount: visible.length,
                      itemBuilder: (context, index) => _SeatTile(
                        seat: visible[index],
                        onTap: () => _editStatus(visible[index]),
                      ),
                    );
                  }),
          ),
        ],
      ),
    );
  }

  void _editStatus(Seat seat) {
    SeatStatus chosen = seat.status;

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
                      'Seat ${seat.label}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  _statusBadge(seat.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              InfoRow(
                  icon: Icons.layers_rounded,
                  label: 'Floor',
                  value: 'Floor ${seat.floor} · ${seat.section}'),
              InfoRow(
                  icon: Icons.category_rounded,
                  label: 'Seat type',
                  value: _seatTypeLabel(seat.type)),
              InfoRow(
                  icon: Icons.power_rounded,
                  label: 'Power outlet',
                  value: seat.hasPowerOutlet ? 'Available' : 'Not available'),
              const Divider(height: AppSpacing.lg),
              Text(
                'Change status',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.sm),
              StatefulBuilder(
                builder: (context, setSheetState) => RadioGroup<SeatStatus>(
                  groupValue: chosen,
                  onChanged: (v) => setSheetState(() => chosen = v ?? chosen),
                  child: Column(
                    children: [
                      for (final status in SeatStatus.values)
                        RadioListTile<SeatStatus>(
                          value: status,
                          title: Text(_statusLabel(status)),
                          secondary: _statusBadge(status),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: chosen == seat.status
                      ? null
                      : () {
                          _applyStatus(seat, chosen);
                          Navigator.pop(context);
                        },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Update status'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyStatus(Seat seat, SeatStatus status) {
    final index = _seats.indexOf(seat);
    if (index == -1) return;

    final updated = StaffMockData.cloneSeatWithStatus(seat, status);
    setState(() => _seats[index] = updated);
    // Mirror into the shared mock so dashboard counters stay accurate.
    final mockIndex = StaffMockData.seats.indexOf(seat);
    if (mockIndex != -1) StaffMockData.seats[mockIndex] = updated;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Seat ${seat.label} is now ${_statusLabel(status).toLowerCase()}')),
    );
  }

  static String _statusLabel(SeatStatus status) => switch (status) {
        SeatStatus.available => 'Available',
        SeatStatus.occupied => 'Occupied',
        SeatStatus.reserved => 'Reserved',
      };

  static StaffBadgeTone _statusTone(SeatStatus status) => switch (status) {
        SeatStatus.available => StaffBadgeTone.success,
        SeatStatus.occupied => StaffBadgeTone.danger,
        SeatStatus.reserved => StaffBadgeTone.warning,
      };

  static Widget _statusBadge(SeatStatus status) => StaffStatusBadge(
        label: _statusLabel(status),
        tone: _statusTone(status),
        compact: true,
      );

  static String _seatTypeLabel(SeatType type) => switch (type) {
        SeatType.quiet => 'Quiet study',
        SeatType.group => 'Group study',
        SeatType.computer => 'Computer station',
      };
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendDot(AppColors.seatAvailable, 'Available'),
          const SizedBox(width: AppSpacing.md),
          _legendDot(AppColors.seatReserved, 'Reserved'),
          const SizedBox(width: AppSpacing.md),
          _legendDot(AppColors.seatOccupied, 'Occupied'),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SeatTile extends StatelessWidget {
  const _SeatTile({required this.seat, required this.onTap});

  final Seat seat;
  final VoidCallback onTap;

  Color get _color => switch (seat.status) {
        SeatStatus.available => AppColors.seatAvailable,
        SeatStatus.reserved => AppColors.seatReserved,
        SeatStatus.occupied => AppColors.seatOccupied,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: _color.withValues(alpha: 0.55)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chair_rounded,
                size: 22,
                color: _color,
              ),
              const SizedBox(height: 6),
              Text(
                seat.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'F${seat.floor}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
