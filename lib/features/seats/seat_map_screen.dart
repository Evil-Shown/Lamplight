import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import 'seat_detail_screen.dart';
import 'seat_filter_sheet.dart';

/// P-06 Seat Map.
///
/// A 4x4 grid of circular seat badges over a white card, a floor picker,
/// two filter chips that open the filter sheet, the status legend, and a
/// recommendation card for the best free seat.
class SeatMapScreen extends StatefulWidget {
  const SeatMapScreen({super.key});

  @override
  State<SeatMapScreen> createState() => _SeatMapScreenState();
}

class _SeatMapScreenState extends State<SeatMapScreen> {
  SeatFilters _filters = const SeatFilters();
  Seat? _selected;
  String _view = 'Map';

  List<Seat> get _visible {
    final seats = AppScope.of(context).seats;
    return seats.where(_filters.matches).toList();
  }

  /// Highest-scoring free seat, with the reasons shown on the card.
  ({Seat seat, List<String> reasons})? get _recommended {
    final available =
        _visible.where((seat) => seat.status == SeatStatus.available);
    Seat? best;
    var bestScore = -1;
    for (final seat in available) {
      var score = 0;
      if (seat.category == SeatCategory.quietZone) score += 3;
      if (seat.hasPowerOutlet) score += 3;
      if (seat.nearWindow) score += 2;
      if (seat.hasMonitor) score += 1;
      if (seat.standingDesk) score += 1;
      if (score > bestScore) {
        best = seat;
        bestScore = score;
      }
    }
    if (best == null) return null;
    return (seat: best, reasons: best.matchReasons);
  }

  bool get _canPop => ModalRoute.of(context)?.canPop ?? false;

  Future<void> _openFilters() async {
    final result = await SeatFilterSheet.show(context, _filters);
    if (result != null) setState(() => _filters = result);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final canPop = _canPop;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : const SizedBox(width: 48),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CAMPUS COMMONS',
                style: AppText.overline(9.5, ls: 1.4)),
            const SizedBox(height: 1),
            Text('Seat Reservation',
                style: AppText.title(17, w: FontWeight.w700)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StaggeredEntrance(
                    child: Text(
                      'Find and reserve your ideal study spot',
                      style:
                          AppText.title(19, w: FontWeight.w700, ls: -0.4),
                    ),
                  ),
                  const SizedBox(height: 14),
                  StaggeredEntrance(
                    index: 1,
                    child: _ZonePicker(
                      value: _filters.floor,
                      seatCount: visible.length,
                      onChanged: (value) => setState(
                          () => _filters = _filters.copyWith(floor: value)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilterChipRow(
                    options: const ['Quiet Area', 'Power Outlets', 'Dual Monitors'],
                    selected: '',
                    isSelectedOf: (option) => switch (option) {
                      'Quiet Area' =>
                        _filters.categories.contains(SeatCategory.quietZone),
                      'Power Outlets' => _filters.powerOutlet,
                      _ => _filters.monitor,
                    },
                    onSelected: (option) => setState(() {
                      switch (option) {
                        case 'Quiet Area':
                          final next =
                              Set<SeatCategory>.from(_filters.categories);
                          if (!next.remove(SeatCategory.quietZone)) {
                            next.add(SeatCategory.quietZone);
                          }
                          _filters = _filters.copyWith(categories: next);
                        case 'Power Outlets':
                          _filters = _filters.copyWith(
                              powerOutlet: !_filters.powerOutlet);
                        default:
                          _filters =
                              _filters.copyWith(monitor: !_filters.monitor);
                      }
                    }),
                    iconBuilder: (option) => switch (option) {
                      'Quiet Area' => Icons.volume_off_rounded,
                      'Power Outlets' => Icons.power_rounded,
                      _ => Icons.monitor_rounded,
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${visible.where((s) => s.status == SeatStatus.available).length} '
                          'of ${visible.length} seats available',
                          style: AppText.body(
                              12.5, color: AppColors.textSecondary),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _openFilters,
                        icon: const Icon(Icons.tune_rounded, size: 17),
                        label: const Text('Filters'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 34),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: AppText.label(13, w: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SegmentedTabs(
                    options: const ['Map', 'List'],
                    selected: _view,
                    onSelected: (value) => setState(() => _view = value),
                  ),
                  const SizedBox(height: 16),
                  if (_recommended == null)
                    const SurfaceCard(
                      child: Text(
                        'No free seat matches these filters. Reset them to see the full floor.',
                      ),
                    )
                  else
                    StaggeredEntrance(
                      child: _RecommendedCard(
                        seat: _recommended!.seat,
                        reasons: _recommended!.reasons,
                        onTap: () => _openDetail(_recommended!.seat),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (visible.isEmpty)
                    const EmptyState(
                      icon: Icons.event_seat_outlined,
                      title: 'No seats on this floor',
                      message:
                          'Try another floor, or clear the area and facility filters.',
                    )
                  else if (_view == 'List')
                    _SeatList(
                      seats: visible,
                      selected: _selected,
                      onSelect: (seat) => setState(() => _selected = seat),
                      onOpen: _openDetail,
                    )
                  else ...[
                    StaggeredEntrance(
                      child: _SeatGridCard(
                        seats: visible,
                        selected: _selected,
                        onSelect: (seat) => setState(() => _selected = seat),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Legend(visible: visible),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selected == null
          ? null
          : BottomActionBar(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Seat ${_selected!.label}',
                          style: AppText.title(14.5, w: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Selected · today',
                          style: AppText.body(
                              11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  PrimaryButton(
                    label: 'Continue',
                    trailingIcon: Icons.arrow_forward_rounded,
                    onPressed: () => _openDetail(_selected!),
                  ),
                ],
              ),
            ),
    );
  }

  void _openDetail(Seat seat) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SeatDetailScreen(seat: seat)),
    );
  }
}

/// The zone selection card — floor plus live desk count, styled as the
/// Stitch design's "ZONE SELECTION" surface.
class _ZonePicker extends StatelessWidget {
  const _ZonePicker({
    required this.value,
    required this.seatCount,
    required this.onChanged,
  });

  final String value;
  final int seatCount;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
            child: Icon(Icons.apartment_rounded,
                size: 19, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ZONE SELECTION',
                    style: AppText.overline(9.5, ls: 1.3)),
                const SizedBox(height: 2),
                Text('$value · $seatCount desks',
                    style: AppText.title(13.5, w: FontWeight.w600)),
              ],
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              icon: Icon(Icons.expand_more_rounded,
                  size: 20, color: AppColors.textFaint),
              borderRadius: BorderRadius.circular(AppRadii.sm),
              style: AppText.body(14),
              items: const [
                DropdownMenuItem(value: 'Floor 1', child: Text('Floor 1')),
                DropdownMenuItem(value: 'Floor 2', child: Text('Floor 2')),
                DropdownMenuItem(value: 'Floor 3', child: Text('Floor 3')),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The 4x4 grid of circular seat badges.
class _SeatGridCard extends StatelessWidget {
  const _SeatGridCard({
    required this.seats,
    required this.selected,
    required this.onSelect,
  });

  final List<Seat> seats;
  final Seat? selected;
  final ValueChanged<Seat> onSelect;

  @override
  Widget build(BuildContext context) {
    // Preserve the 4-column grid even when filters hide some seats.
    final grid = List<Seat?>.filled(16, null);
    for (final seat in seats) {
      final index = seat.row * 4 + seat.col;
      if (index >= 0 && index < 16) grid[index] = seat;
    }

    return SurfaceCard(
      elevated: true,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      // A cool tint lifts the map off the page without shouting.
      tint: AppColors.primary.withValues(alpha: 0.20),
      child: Column(
        children: [
          for (var row = 0; row < 4; row++) ...[
            if (row > 0) const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var col = 0; col < 4; col++) ...[
                  if (col > 0) const SizedBox(width: 12),
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: grid[row * 4 + col] == null
                        ? const SizedBox.shrink()
                        : _SeatBadge(
                            seat: grid[row * 4 + col]!,
                            isSelected: selected?.id == grid[row * 4 + col]!.id,
                            onTap: onSelect,
                          ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stairs_rounded, size: 15,
                  color: AppColors.textFaint),
              const SizedBox(width: 6),
              Flexible(
                child: Text('ENTRANCE · STAIRWELL A',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.overline(9.5, ls: 1.2,
                        color: AppColors.textFaint)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeatBadge extends StatelessWidget {
  const _SeatBadge({
    required this.seat,
    required this.isSelected,
    required this.onTap,
  });

  final Seat seat;
  final bool isSelected;
  final ValueChanged<Seat> onTap;

  Color get _color => isSelected
      ? AppColors.seatSelected
      : switch (seat.status) {
          SeatStatus.available => AppColors.seatAvailable,
          SeatStatus.limited => AppColors.seatLimited,
          SeatStatus.occupied => AppColors.seatOccupied,
        };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Seat ${seat.label}, ${_statusLabel(seat.status)}',
      button: true,
      child: GestureDetector(
        onTap: () => onTap(seat),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                    Colors.white.withValues(alpha: 0.22), _color),
                _color,
              ],
            ),
            boxShadow: isSelected
                ? AppShadows.glow(_color)
                : [
                    BoxShadow(
                      color: _color.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                seat.label,
                style: AppText.title(
                  13,
                  w: FontWeight.w700,
                  color: AppColors.textInverse,
                ),
              ),
              if (seat.hasPowerOutlet && seat.status != SeatStatus.occupied)
                Positioned(
                  right: 7,
                  bottom: 9,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(SeatStatus status) => switch (status) {
        SeatStatus.available => 'available',
        SeatStatus.limited => 'limited',
        SeatStatus.occupied => 'full',
      };
}

class _Legend extends StatelessWidget {
  const _Legend({required this.visible});

  final List<Seat> visible;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        AppColors.seatAvailable,
        'Available (${visible.where((s) => s.status == SeatStatus.available).length})'
      ),
      (
        AppColors.seatLimited,
        'Limited (${visible.where((s) => s.status == SeatStatus.limited).length})'
      ),
      (
        AppColors.seatOccupied,
        'Full (${visible.where((s) => s.status == SeatStatus.occupied).length})'
      ),
      (AppColors.seatSelected, 'Selected'),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final (color, label) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 6),
              Text(label, style: AppText.body(11.5, color: AppColors.textSecondary)),
            ],
          ),
      ],
    );
  }
}

class _SeatList extends StatelessWidget {
  const _SeatList({
    required this.seats,
    required this.selected,
    required this.onSelect,
    required this.onOpen,
  });

  final List<Seat> seats;
  final Seat? selected;
  final ValueChanged<Seat> onSelect;
  final ValueChanged<Seat> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final seat in seats) ...[
          SurfaceCard(
            onTap: () {
              onSelect(seat);
              onOpen(seat);
            },
            borderColor: selected?.id == seat.id ? AppColors.primary : null,
            child: Row(
              children: [
                Text(seat.label,
                    style: AppText.title(16, w: FontWeight.w700)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${seat.zoneLabel} · Floor ${seat.floor}',
                    style: AppText.body(13, color: AppColors.textSecondary),
                  ),
                ),
                StatusPill(
                  label: switch (seat.status) {
                    SeatStatus.available => 'Available',
                    SeatStatus.limited => 'Limited',
                    SeatStatus.occupied => 'Full',
                  },
                  color: switch (seat.status) {
                    SeatStatus.available => AppColors.success,
                    SeatStatus.limited => AppColors.warning,
                    SeatStatus.occupied => AppColors.error,
                  },
                  compact: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({
    required this.seat,
    required this.reasons,
    required this.onTap,
  });

  final Seat seat;
  final List<String> reasons;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final why = reasons.isEmpty ? seat.zoneLabel : reasons.join(' · ');
    return SurfaceCard(
      onTap: onTap,
      gradient: AppGradients.auroraSoft,
      borderColor: AppColors.primary.withValues(alpha: 0.28),
      tint: AppColors.primary,
      child: Row(
        children: [
          IconBadge(
              icon: Icons.auto_awesome_rounded,
              size: 40,
              color: AppColors.success),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Recommended for most students'),
                const SizedBox(height: 5),
                Text('Seat ${seat.label}',
                    style: AppText.title(15.5, w: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  why,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(12.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadii.full),
              boxShadow: AppShadows.glow(AppColors.primary),
            ),
            child: Text(
              'Select',
              style: AppText.label(
                12.5,
                w: FontWeight.w700,
                color: AppColors.textInverse,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
