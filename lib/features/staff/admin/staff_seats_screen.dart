import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart' show AppNavInset;
import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../models/models.dart';
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

  List<String> get _floorOptions => [
        'All',
        ...(_seats.map((s) => 'Floor ${s.floor}').toSet().toList()..sort()),
      ];

  @override
  Widget build(BuildContext context) {
    final visible = _seats
        .where(
            (s) => _floorFilter == 'All' || 'Floor ${s.floor}' == _floorFilter)
        .toList();
    final available =
        _seats.where((s) => s.status == SeatStatus.available).length;

    return AppScaffold(
      title: 'Seat Availability',
      contentUnderBar: true,
      actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.base),
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
      body: Column(
        children: [
          SizedBox(height: GlassAppBar.contentTopPadding(context)),
          FilterChipRow(
            options: _floorOptions,
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
                      padding: const EdgeInsets.fromLTRB(AppSpacing.base,
                          AppSpacing.sm, AppSpacing.base, AppNavInset.bottom),
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
                      'Seat ${seat.label}',
                      style: AppText.title(20, w: FontWeight.w800),
                    ),
                  ),
                  _statusBadge(seat.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _SheetRow(label: 'Location', value: 'Floor ${seat.floor} · ${seat.section}'),
              _SheetRow(label: 'Seat type', value: seat.zoneLabel),
              _SheetRow(
                  label: 'Power outlet',
                  value: seat.hasPowerOutlet ? 'Available' : 'Not available'),
              const Divider(height: AppSpacing.xl),
              Text(
                'Change status',
                style: AppText.title(15, w: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.sm),
              StatefulBuilder(
                builder: (context, setSheetState) => RadioGroup<SeatStatus>(
                  groupValue: chosen,
                  onChanged: (v) {
                    AppFeedback.select();
                    setSheetState(() => chosen = v ?? chosen);
                  },
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
                          AppFeedback.success();
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

    final updated = seat.copyWith(status: status);
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
        SeatStatus.limited => 'Limited',
        SeatStatus.occupied => 'Occupied',
      };

  static StaffBadgeTone _statusTone(SeatStatus status) => switch (status) {
        SeatStatus.available => StaffBadgeTone.success,
        SeatStatus.limited => StaffBadgeTone.warning,
        SeatStatus.occupied => StaffBadgeTone.danger,
      };

  static Widget _statusBadge(SeatStatus status) => StaffStatusBadge(
        label: _statusLabel(status),
        tone: _statusTone(status),
        compact: true,
      );
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
                  w: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendDot(AppColors.seatAvailable, 'Available'),
          const SizedBox(width: AppSpacing.base),
          _legendDot(AppColors.seatLimited, 'Limited'),
          const SizedBox(width: AppSpacing.base),
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
          style: AppText.label(12, w: FontWeight.w600),
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
        SeatStatus.limited => AppColors.seatLimited,
        SeatStatus.occupied => AppColors.seatOccupied,
      };

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      feedback: PressFeedback.select,
      child: FrostedCard(
        radius: AppRadii.md,
        tint: _color.withValues(alpha: AppColors.isDark ? 0.2 : 0.12),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chair_rounded, size: 22, color: _color),
            const SizedBox(height: 4),
            Text(seat.label, style: AppText.title(14, w: FontWeight.w800)),
            Text(
              'F${seat.floor} · ${_word(seat.status)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label(11, w: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  /// Text companion so status never relies on colour alone.
  static String _word(SeatStatus s) => switch (s) {
        SeatStatus.available => 'Free',
        SeatStatus.limited => 'Few',
        SeatStatus.occupied => 'Taken',
      };
}
