import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../waitlist/waitlist_screen.dart';
import 'booking_confirmation_screen.dart';

/// P-07 Seat Details.
///
/// Identity, amenities, a real date and time-slot picker, then reserve or
/// join the waiting list.
class SeatDetailScreen extends StatefulWidget {
  const SeatDetailScreen({super.key, required this.seat});

  final Seat seat;

  @override
  State<SeatDetailScreen> createState() => _SeatDetailScreenState();
}

class _SlotChoice {
  const _SlotChoice(this.startHour, this.endHour, this.label);

  final int startHour;
  final int endHour;
  final String label;

  bool isPastOn(DateTime day) {
    final end = DateTime(day.year, day.month, day.day, endHour);
    return !end.isAfter(DateTime.now());
  }
}

class _SeatDetailScreenState extends State<SeatDetailScreen> {
  static const _slots = [
    _SlotChoice(8, 10, '8:00 AM – 10:00 AM'),
    _SlotChoice(10, 12, '10:00 AM – 12:00 PM'),
    _SlotChoice(12, 14, '12:00 PM – 2:00 PM'),
    _SlotChoice(14, 17, '2:00 PM – 5:00 PM'),
    _SlotChoice(17, 19, '5:00 PM – 7:00 PM'),
  ];

  late DateTime _day;
  _SlotChoice? _slot;

  Seat get seat => widget.seat;
  bool get _canBook => seat.status == SeatStatus.available;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _day = DateTime(now.year, now.month, now.day);
    _slot = _slots.cast<_SlotChoice?>().firstWhere(
          (slot) => !slot!.isPastOn(_day),
          orElse: () => null,
        );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 14)),
    );
    if (picked == null) return;
    setState(() {
      _day = DateTime(picked.year, picked.month, picked.day);
      if (_slot != null && _slot!.isPastOn(_day)) _slot = null;
    });
  }

  void _reserve() {
    final slot = _slot;
    if (slot == null) return;
    final start = DateTime(_day.year, _day.month, _day.day, slot.startHour);
    final end = DateTime(_day.year, _day.month, _day.day, slot.endHour);
    final booking = AppScope.read(context).reserveSeat(
      seat,
      start: start,
      end: end,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingConfirmationScreen(booking: booking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isToday = _day.year == today.year &&
        _day.month == today.month &&
        _day.day == today.day;
    final dateLabel = isToday
        ? 'Today, ${DateFormat('d MMM yyyy').format(_day)}'
        : DateFormat('EEE, d MMM yyyy').format(_day);

    return AppScaffold(
      title: 'Seat Details',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          StaggeredEntrance(
            child: GradientHero(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FLOOR ${seat.floor}',
                    style: AppText.overline(
                      10.5,
                      ls: 1.8,
                      color: AppColors.textInverse.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seat ${seat.label}',
                    style: AppText.display(30, w: FontWeight.w800, ls: -0.9,
                        color: AppColors.textInverse),
                  ),
                  const SizedBox(height: 10),
                  StatusPill(
                    color: AppColors.textInverse,
                    background: Colors.white.withValues(alpha: 0.20),
                    label: switch (seat.status) {
                      SeatStatus.available => 'Available Now',
                      SeatStatus.limited => 'Limited availability',
                      SeatStatus.occupied => 'Currently occupied',
                    },
                    pulse: _canBook,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: SectionLabel('Features'),
          ),
          const SizedBox(height: 10),
          StaggeredEntrance(
            index: 1,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FeatureChip(
                  icon: Icons.volume_off_rounded,
                  label: seat.zoneLabel,
                ),
                if (seat.hasPowerOutlet)
                  const _FeatureChip(
                      icon: Icons.power_rounded, label: 'Power Outlet'),
                if (seat.nearWindow)
                  const _FeatureChip(
                      icon: Icons.wb_sunny_outlined, label: 'Near Window'),
                if (seat.hasMonitor)
                  const _FeatureChip(
                      icon: Icons.monitor_rounded, label: 'Monitor'),
                if (seat.standingDesk)
                  const _FeatureChip(
                      icon: Icons.accessibility_new_rounded,
                      label: 'Standing desk'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: SectionLabel('Reservation period'),
          ),
          const SizedBox(height: 10),
          StaggeredEntrance(
            index: 2,
            child: SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  InkWell(
                    onTap: _pickDate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 15),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 17, color: AppColors.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(dateLabel, style: AppText.body(14)),
                          ),
                          Text('Change',
                              style: AppText.label(13,
                                  w: FontWeight.w600,
                                  color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final slot in _slots)
                          _SlotChip(
                            label: slot.label,
                            selected: _slot == slot,
                            enabled: !slot.isPastOn(_day),
                            onTap: () => setState(() => _slot = slot),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: SectionLabel('Included amenities'),
          ),
          const SizedBox(height: 10),
          const StaggeredEntrance(
            index: 3,
            child: SurfaceCard(
              child: Column(
                children: [
                  _AmenityRow(label: 'Desk lamp with brightness control'),
                  SizedBox(height: 10),
                  _AmenityRow(label: 'Ergonomic adjustable task chair'),
                  SizedBox(height: 10),
                  _AmenityRow(label: 'Noise-cancelling partition shield'),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomBar: BottomActionBar(
        child: _canBook
            ? PrimaryButton(
                label: _slot == null
                    ? 'Choose a time slot'
                    : 'Reserve Seat ${seat.label}',
                onPressed: _slot == null ? null : _reserve,
              )
            : PrimaryButton(
                label: 'Join waiting list',
                icon: Icons.hourglass_bottom_rounded,
                tone: ButtonTone.secondary,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WaitlistScreen(seat: seat),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: selected ? AppColors.primarySoft : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.full),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadii.full),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.full),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: AppText.label(
                12.5,
                w: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 7),
          Text(label, style: AppText.label(12.5, w: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AmenityRow extends StatelessWidget {
  const _AmenityRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, size: 17,
            color: AppColors.success),
        const SizedBox(width: 11),
        Expanded(
          child: Text(label, style: AppText.body(13.5)),
        ),
      ],
    );
  }
}
