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
    if (booking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seat ${seat.label} was just taken — '
              'pick another seat.'),
        ),
      );
      return;
    }
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
                    'FLOOR ${seat.floor} · ${seat.zoneLabel.toUpperCase()}',
                    style: AppText.overline(
                      10.5,
                      ls: 1.8,
                      color: AppColors.textInverse.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seat ${seat.label}',
                    style: AppText.display(AppText.displayMd, w: FontWeight.w800,
                        ls: -1.0,
                        color: AppColors.textInverse),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Single desk · ${_categoryLabel(seat.category)} zone',
                    style: AppText.body(
                      13,
                      color: AppColors.textInverse.withValues(alpha: 0.80),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
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
                      if (seat.hasMonitor)
                        StatusPill(
                          color: AppColors.textInverse,
                          background: Colors.white.withValues(alpha: 0.14),
                          label: 'Dual 4K monitors',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          StaggeredEntrance(
            index: 1,
            child: _ZoneStrip(seat: seat),
          ),
          const SizedBox(height: 22),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: SectionLabel('Session date'),
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
                          Icon(Icons.calendar_today_rounded,
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                const Expanded(
                  child: SectionLabel('Select available time slot'),
                ),
                Text(
                  'Local timezone',
                  style: AppText.body(11, color: AppColors.textFaint),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          StaggeredEntrance(
            index: 3,
            child: Column(
              children: [
                for (var i = 0; i < _slots.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _SlotRow(
                    label: _slots[i].label,
                    badge: _slotBadge(i),
                    availability: _slotAvailability(i),
                    selected: _slot == _slots[i],
                    enabled: !_slots[i].isPastOn(_day),
                    onTap: () {
                      Haptics.selection();
                      setState(() => _slot = _slots[i]);
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: SectionLabel('Included seat amenities'),
          ),
          const SizedBox(height: 10),
          StaggeredEntrance(
            index: 4,
            child: SurfaceCard(
              child: Column(
                children: [
                  const _AmenityRow(
                      label: 'Desk lamp with warm brightness setting'),
                  const SizedBox(height: 10),
                  const _AmenityRow(
                      label: 'Ergonomic lumbar-support mesh chair'),
                  const SizedBox(height: 10),
                  const _AmenityRow(
                      label: 'Acoustic noise-dampening partition shield'),
                  if (seat.hasMonitor) ...[
                    const SizedBox(height: 10),
                    const _AmenityRow(
                        label: 'Dual 4K monitors with USB-C hub'),
                  ],
                  if (seat.standingDesk) ...[
                    const SizedBox(height: 10),
                    const _AmenityRow(
                        label: 'Height-adjustable standing desk'),
                  ],
                  if (seat.hasPowerOutlet) ...[
                    const SizedBox(height: 10),
                    const _AmenityRow(
                        label: '65W AC power + fast USB-C charging'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const StaggeredEntrance(
            index: 5,
            child: Callout(
              tone: CalloutTone.info,
              icon: Icons.auto_awesome_rounded,
              title: 'Freshly serviced in 5 min',
              message:
                  'A cleaning pass runs before your slot — the desk is '
                  'sanitised and reset for you.',
            ),
          ),
        ],
      ),
      bottomBar: BottomActionBar(
        child: _canBook
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_slot != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              'Selected ${_slot!.label}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.label(
                                12,
                                w: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  PrimaryButton(
                    label: _slot == null
                        ? 'Choose a time slot'
                        : 'Reserve Seat ${seat.label}',
                    onPressed: _slot == null ? null : _reserve,
                  ),
                ],
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

  String _categoryLabel(SeatCategory category) => switch (category) {
        SeatCategory.quietZone => 'quiet',
        SeatCategory.collaborative => 'collaborative',
        SeatCategory.individualPod => 'focus pod',
      };

  /// Popularity badges per slot, matching the Stitch design.
  String? _slotBadge(int index) => switch (index) {
        1 => 'Most popular',
        3 => 'Popular',
        _ => null,
      };

  /// Live floor occupancy from Firestore — the same honest number every
  /// slot shows, since desks are shared across the day's slots.
  String _slotAvailability(int index) {
    final floorSeats = AppScope.of(context)
        .seats
        .where((s) => s.floor == seat.floor)
        .toList();
    final total = floorSeats.length;
    if (total == 0) return 'Availability unavailable';
    final free =
        floorSeats.where((s) => s.status == SeatStatus.available).length;
    return '$free of $total desks left';
  }
}

/// The three-zone strip from the Stitch design; the seat's own zone is
/// highlighted while the others stay muted.
class _ZoneStrip extends StatelessWidget {
  const _ZoneStrip({required this.seat});

  final Seat seat;

  @override
  Widget build(BuildContext context) {
    final zones = [
      (
        Icons.volume_off_rounded,
        'Quiet Wing',
        seat.category == SeatCategory.quietZone,
      ),
      (
        Icons.power_rounded,
        'Power Wing',
        seat.hasPowerOutlet,
      ),
      (
        Icons.monitor_rounded,
        'Panel Hub',
        seat.hasMonitor,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < zones.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _ZoneCard(
              icon: zones[i].$1,
              label: zones[i].$2,
              active: zones[i].$3,
            ),
          ),
        ],
      ],
    );
  }
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final tint = active ? AppColors.primary : AppColors.textFaint;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: active ? AppColors.primarySoft : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(
          color: active ? AppColors.primary.withValues(alpha: 0.45) : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 19, color: tint),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppText.label(
              11,
              w: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A full-width time-slot row with a popularity badge and availability
/// note, matching the Stitch slot list.
class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.label,
    required this.badge,
    required this.availability,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String? badge;
  final String availability;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: PressScale(
        onTap: enabled ? onTap : () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primarySoft : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.border,
              width: selected ? 1.4 : 1,
            ),
            boxShadow:
                selected ? AppShadows.glow(AppColors.primary) : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.borderStrong,
                    width: 1.6,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check_rounded,
                        size: 13, color: AppColors.textInverse)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: AppText.label(
                              13.5,
                              w: FontWeight.w700,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.goldSoft,
                              borderRadius:
                                  BorderRadius.circular(AppRadii.full),
                            ),
                            child: Text(
                              badge!.toUpperCase(),
                              style: AppText.overline(
                                9,
                                ls: 0.8,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      availability,
                      style: AppText.body(
                        11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        Icon(Icons.check_circle_rounded, size: 17,
            color: AppColors.success),
        const SizedBox(width: 11),
        Expanded(
          child: Text(label, style: AppText.body(13.5)),
        ),
      ],
    );
  }
}