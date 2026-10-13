import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart' show AppNavInset;
import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../models/models.dart';
import '../../../core/state/app_state.dart';
import 'widgets/staff_live_states.dart';
import 'widgets/staff_status_badge.dart';

/// Staff-side seat availability: floor filter, live status grid and a
/// status editor per seat that writes through [AppState.setSeatStatus].
class StaffSeatsScreen extends StatefulWidget {
  const StaffSeatsScreen({super.key, this.embedded = false});

  /// True when shown as a shell tab (no back button); false when pushed.
  final bool embedded;

  @override
  State<StaffSeatsScreen> createState() => _StaffSeatsScreenState();
}

class _StaffSeatsScreenState extends State<StaffSeatsScreen> {
  String _floorFilter = 'All';

  List<String> _floorOptions(List<Seat> seats) => [
        'All',
        ...(seats.map((s) => 'Floor ${s.floor}').toSet().toList()..sort()),
      ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final seats = state.adminSeats;
    final options = _floorOptions(seats);
    final floor = options.contains(_floorFilter) ? _floorFilter : 'All';
    final visible = seats
        .where((s) => floor == 'All' || 'Floor ${s.floor}' == floor)
        .toList();
    final available =
        seats.where((s) => s.status == SeatStatus.available).length;

    return AppScaffold(
      title: 'Seat Availability',
      showBack: !widget.embedded,
      contentUnderBar: true,
      actions: [
        if (seats.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.base),
            child: Center(
              child: StaffStatusBadge(
                label: '$available of ${seats.length} free',
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
            options: options,
            selected: floor,
            onSelected: (f) => setState(() => _floorFilter = f),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _SeatLegend(),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: StaffLiveGate(
              state: state,
              hasData: seats.isNotEmpty,
              builder: (context) => visible.isEmpty
                  ? StaffScrollable(
                      state: state,
                      child: EmptyState(
                        icon: Icons.event_seat_rounded,
                        title: seats.isEmpty ? 'No seats yet' : 'No seats',
                        message: seats.isEmpty
                            ? 'No seats have been set up in the library.'
                            : 'No seats match this floor filter.',
                      ),
                    )
                  : StaffRefreshable(
                      state: state,
                      child: LayoutBuilder(builder: (context, constraints) {
                        final columns =
                            (constraints.maxWidth / 112).floor().clamp(3, 6);
                        return GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                              AppSpacing.base,
                              AppSpacing.sm,
                              AppSpacing.base,
                              widget.embedded
                                  ? AppSpacing.xl
                                  : AppNavInset.bottom),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: AppSpacing.sm,
                            crossAxisSpacing: AppSpacing.sm,
                            childAspectRatio: 1.04,
                          ),
                          itemCount: visible.length,
                          itemBuilder: (context, index) => _SeatTile(
                            seat: visible[index],
                            onTap: () => _editStatus(visible[index]),
                          ),
                        );
                      }),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _editStatus(Seat seat) {
    SeatStatus chosen = seat.status;

    showGlassSheet<void>(
      context,
      opaque: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 2, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Icon(Icons.event_seat_rounded,
                          color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Seat ${seat.label}',
                              style: AppText.title(21,
                                  w: FontWeight.w800, ls: -0.3)),
                          Text('Update availability and access',
                              style: AppText.body(12.5,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    _statusBadge(seat.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _SheetRow(
                          icon: Icons.place_outlined,
                          label: 'Location',
                          value: 'Floor ${seat.floor} · ${seat.section}'),
                      _SheetRow(
                          icon: Icons.grid_view_rounded,
                          label: 'Seat type',
                          value: seat.zoneLabel),
                      _SheetRow(
                          icon: Icons.power_rounded,
                          label: 'Power',
                          value: seat.hasPowerOutlet ? 'Available' : 'None'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Set status',
                    style: AppText.title(15, w: FontWeight.w800)),
                const SizedBox(height: AppSpacing.sm),
                for (final status in SeatStatus.values) ...[
                  _StatusChoice(
                    status: status,
                    selected: chosen == status,
                    onTap: () {
                      AppFeedback.select();
                      setSheetState(() => chosen = status);
                    },
                  ),
                  if (status != SeatStatus.values.last)
                    const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: chosen == seat.status
                      ? 'Select a different status'
                      : 'Update to ${_statusLabel(chosen)}',
                  icon: Icons.check_rounded,
                  onPressed: chosen == seat.status
                      ? null
                      : () {
                          Navigator.pop(context);
                          if (seat.status == SeatStatus.occupied &&
                              chosen == SeatStatus.available) {
                            _release(seat);
                          } else {
                            AppFeedback.success();
                            _applyStatus(seat, chosen);
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Frees an occupied seat after the staff member confirms which one.
  Future<void> _release(Seat seat) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Release seat ${seat.label}?',
      body: 'Seat ${seat.label} (Floor ${seat.floor}) will be marked '
          'available. Only do this if the student has left.',
      confirmLabel: 'Release seat',
    );
    if (!confirmed || !mounted) return;
    AppFeedback.success();
    await _applyStatus(seat, SeatStatus.available);
  }

  Future<void> _applyStatus(Seat seat, SeatStatus status) async {
    final state = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await state.setSeatStatus(seat.id, status);
      messenger.showSnackBar(SnackBar(
          content: Text(
              'Seat ${seat.label} is now ${_statusLabel(status).toLowerCase()}')));
    } catch (_) {
      AppFeedback.error();
      messenger.showSnackBar(SnackBar(
          content: Text('Could not update seat ${seat.label}. Try again.')));
    }
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
  const _SheetRow(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.textFaint),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 78,
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

class _StatusChoice extends StatelessWidget {
  const _StatusChoice({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final SeatStatus status;
  final bool selected;
  final VoidCallback onTap;

  Color get _color => switch (status) {
        SeatStatus.available => AppColors.success,
        SeatStatus.limited => AppColors.warning,
        SeatStatus.occupied => AppColors.error,
      };

  String get _description => switch (status) {
        SeatStatus.available => 'Ready for a new booking',
        SeatStatus.limited => 'Keep visible with limited access',
        SeatStatus.occupied => 'Currently in use',
      };

  @override
  Widget build(BuildContext context) => PressScale(
        onTap: onTap,
        feedback: selected ? PressFeedback.none : PressFeedback.select,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected
                ? _color.withValues(alpha: AppColors.isDark ? 0.18 : 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: selected ? _color : AppColors.border,
                width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppMotion.fast,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? _color : Colors.transparent,
                  border: Border.all(
                      color: selected ? _color : AppColors.borderStrong),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded,
                        size: 15, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_StaffSeatsScreenState._statusLabel(status),
                        style: AppText.label(13.5, w: FontWeight.w800)),
                    Text(_description,
                        style:
                            AppText.body(11.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              _StaffSeatsScreenState._statusBadge(status),
            ],
          ),
        ),
      );
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.base,
        runSpacing: AppSpacing.xs,
        children: [
          _legendDot(AppColors.seatAvailable, 'Available'),
          _legendDot(AppColors.seatLimited, 'Limited'),
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
    return Tooltip(
      message: 'Floor ${seat.floor} · ${_word(seat.status)}',
      child: Semantics(
        button: true,
        label: 'Seat ${seat.label}, floor ${seat.floor}, ${_word(seat.status)}',
        child: PressScale(
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
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration:
                          BoxDecoration(color: _color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _word(seat.status),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label(10.5,
                            w: FontWeight.w700, color: _color),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The status remains available in the tile tooltip and semantic label.
  static String _word(SeatStatus s) => switch (s) {
        SeatStatus.available => 'Free',
        SeatStatus.limited => 'Few',
        SeatStatus.occupied => 'Taken',
      };
}
