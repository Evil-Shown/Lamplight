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

  List<Seat> get _visible {
    final seats = AppScope.of(context).seats;
    return seats.where(_filters.matches).toList();
  }

  Seat? get _recommended {
    final available = _visible.where((s) => s.status == SeatStatus.available);
    final withPower = available.where((s) => s.hasPowerOutlet);
    return withPower.isNotEmpty ? withPower.first : null;
  }

  Future<void> _openFilters() async {
    final result = await SeatFilterSheet.show(context, _filters);
    if (result != null) setState(() => _filters = result);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Seat Map', style: AppText.title(17, w: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: _FloorPicker(
              value: _filters.floor,
              onChanged: (value) =>
                  setState(() => _filters = _filters.copyWith(floor: value)),
            ),
          ),
          FilterChipRow(
            options: const ['Quiet Area', 'Power Outlet'],
            selected: _filters.categories.contains(SeatCategory.quietZone)
                ? 'Quiet Area'
                : (_filters.powerOutlet ? 'Power Outlet' : ''),
            onSelected: (option) => setState(() {
              if (option == 'Quiet Area') {
                final next = Set<SeatCategory>.from(_filters.categories);
                if (!next.remove(SeatCategory.quietZone)) {
                  next.add(SeatCategory.quietZone);
                }
                _filters = _filters.copyWith(categories: next);
              } else {
                _filters = _filters.copyWith(powerOutlet: !_filters.powerOutlet);
              }
            }),
            iconBuilder: (option) => option == 'Quiet Area'
                ? Icons.volume_off_rounded
                : Icons.power_rounded,
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${visible.where((s) => s.status == SeatStatus.available).length} '
                    'of ${visible.length} seats available',
                    style: AppText.body(12.5, color: AppColors.textSecondary),
                  ),
                ),
                TextButton.icon(
                  onPressed: _openFilters,
                  icon: const Icon(Icons.tune_rounded, size: 17),
                  label: const Text('Filters'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: AppText.label(13, w: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: Column(
                children: [
                  StaggeredEntrance(child: _SeatGridCard(
                    seats: visible,
                    selected: _selected,
                    onSelect: (seat) => setState(() => _selected = seat),
                  )),
                  const SizedBox(height: 16),
                  const _Legend(),
                  if (_recommended != null) ...[
                    const SizedBox(height: 18),
                    StaggeredEntrance(
                      index: 1,
                      child: _RecommendedCard(
                        seat: _recommended!,
                        onTap: () => _openDetail(_recommended!),
                      ),
                    ),
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
              child: PrimaryButton(
                label: 'Select Seat ${_selected!.label}',
                onPressed: () => _openDetail(_selected!),
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

class _FloorPicker extends StatelessWidget {
  const _FloorPicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.apartment_rounded, size: 18,
              color: AppColors.textSecondary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Floor',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              icon: const Icon(Icons.expand_more_rounded,
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
              const Icon(Icons.south_rounded, size: 15,
                  color: AppColors.textFaint),
              const SizedBox(width: 6),
              Text('ENTRANCE',
                  style: AppText.overline(10, color: AppColors.textFaint)),
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
    final selectable = seat.status != SeatStatus.occupied;

    return Semantics(
      label: 'Seat ${seat.label}, ${_statusLabel(seat.status)}',
      button: true,
      child: GestureDetector(
        onTap: selectable ? () => onTap(seat) : null,
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
  const _Legend();

  @override
  Widget build(BuildContext context) {
    const items = [
      (AppColors.seatAvailable, 'Available'),
      (AppColors.seatLimited, 'Limited'),
      (AppColors.seatOccupied, 'Full'),
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

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({required this.seat, required this.onTap});

  final Seat seat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      gradient: AppGradients.auroraSoft,
      borderColor: AppColors.primary.withValues(alpha: 0.28),
      tint: AppColors.primary,
      child: Row(
        children: [
          const IconBadge(
              icon: Icons.auto_awesome_rounded, size: 40, color: AppColors.success),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Recommended for you'),
                const SizedBox(height: 5),
                Text('Seat ${seat.label}',
                    style: AppText.title(15.5, w: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${seat.zoneLabel} · ${seat.hasPowerOutlet ? 'Power Outlet' : 'Standard desk'}',
                  style: AppText.body(12.5, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const StatusPill(label: 'Recommended', color: AppColors.success, compact: true),
        ],
      ),
    );
  }
}
