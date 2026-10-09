import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import 'seat_detail_screen.dart';
import 'seat_filter_sheet.dart';

/// P-06 Seat Map.
///
/// A data-driven grid of circular seat badges laid out from each seat's
/// `row`/`col` (never a hardcoded size), a floor picker, filter chips
/// that open the filter sheet, a two-row legend separating availability
/// from ownership, and a recommendation card for the best free seat.
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

  /// Every seat in the current floor's inventory — the grid's shape is
  /// derived from this, so filtering dims cells instead of collapsing
  /// the layout (D-02).
  List<Seat> get _floorSeats {
    final floor = _currentFloorNumber;
    return AppScope.of(context)
        .seats
        .where((seat) => seat.floor == floor)
        .toList();
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
      // Prefer the floor the student is already browsing.
      if (seat.floor == _currentFloorNumber) score += 2;
      if (score > bestScore) {
        best = seat;
        bestScore = score;
      }
    }
    if (best == null) return null;
    return (seat: best, reasons: best.matchReasons);
  }

  int get _currentFloorNumber =>
      int.tryParse(_filters.floor.replaceAll(RegExp(r'[^0-9]'), '')) ?? 2;

  /// Seats held by an active booking of the signed-in user.
  Set<String> get _myBookingSeatIds => AppScope.of(context)
      .bookings
      .where((b) => b.status == ReservationStatus.active)
      .map((b) => b.seat.id)
      .toSet();

  bool get _canPop => ModalRoute.of(context)?.canPop ?? false;

  Future<void> _openFilters() async {
    final result = await SeatFilterSheet.show(context, _filters);
    if (result != null) setState(() => _filters = result);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final canPop = _canPop;
    final state = AppScope.of(context);
    final mySeatIds = _myBookingSeatIds;

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
          // App-level cached-data banner (D-14).
          ConnectivityBanner(lastSyncedAt: state.lastSyncedAt),
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
                  const SizedBox(height: 8),
                  StaggeredEntrance(
                    index: 1,
                    // Driven by the real last-synced timestamp (D-06).
                    child: LiveFreshness(
                        lastSyncedAt: state.lastSyncedAt),
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
                    EmptyState(
                      icon: Icons.event_seat_outlined,
                      title: _floorSeats.isEmpty
                          ? 'No seats on this floor'
                          : 'No seats match these filters',
                      message: _floorSeats.isEmpty
                          ? 'Try another floor, or clear the area and facility filters.'
                          : 'Every desk on this floor is hidden by the '
                              'active filters. Clear them to see the full map.',
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
                          visible: visible,
                          floorSeats: _floorSeats,
                          selected: _selected,
                          mySeatIds: mySeatIds,
                          onSelect: (seat) => setState(() => _selected = seat),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _Legend(visible: visible, mySeatIds: mySeatIds),
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
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          IconBadge(
            icon: Icons.layers_outlined,
            color: AppColors.primary,
            background: AppColors.primarySoft,
            size: 40,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CURRENT FLOOR',
                    style: AppText.overline(9.5, ls: 1.3)),
                const SizedBox(height: 2),
                Text(
                  '$value · $seatCount desks',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title(14, w: FontWeight.w700),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadii.full),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isDense: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: AppColors.primary),
                borderRadius: BorderRadius.circular(AppRadii.md),
                style: AppText.label(13, w: FontWeight.w600, color: AppColors.textPrimary),
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
          ),
        ],
      ),
    );
  }
}

/// The seat grid, laid out from live data (D-02).
///
/// Dimensions come from `max(row) × max(col)` of the floor's inventory —
/// never a hardcoded size. Seats hidden by filters render as dimmed
/// placeholders so the map's shape stays stable, and floors wider than
/// six columns scroll horizontally.
class _SeatGridCard extends StatelessWidget {
  const _SeatGridCard({
    required this.visible,
    required this.floorSeats,
    required this.selected,
    required this.mySeatIds,
    required this.onSelect,
  });

  final List<Seat> visible;
  final List<Seat> floorSeats;
  final Seat? selected;
  final Set<String> mySeatIds;
  final ValueChanged<Seat> onSelect;

  @override
  Widget build(BuildContext context) {
    final visibleIds = visible.map((s) => s.id).toSet();
    final rows =
        floorSeats.map((s) => s.row).fold(0, math.max) + 1;
    final cols =
        floorSeats.map((s) => s.col).fold(0, math.max) + 1;

    final grid = List<Seat?>.filled(rows * cols, null);
    for (final seat in floorSeats) {
      grid[seat.row * cols + seat.col] = seat;
    }

    Widget buildGrid() => Column(
          children: [
            for (var row = 0; row < rows; row++) ...[
              if (row > 0) const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var col = 0; col < cols; col++) ...[
                    if (col > 0) const SizedBox(width: 12),
                    _gridCell(grid[row * cols + col], visibleIds),
                  ],
                ],
              ),
            ],
          ],
        );

    return SurfaceCard(
      elevated: true,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      // A cool tint lifts the map off the page without shouting.
      tint: AppColors.primary.withValues(alpha: 0.20),
      child: Column(
        children: [
          // Wide floors pan; narrow ones centre as before.
          cols > 6
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: buildGrid(),
                )
              : buildGrid(),
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

  Widget _gridCell(Seat? seat, Set<String> visibleIds) {
    if (seat == null) return const SizedBox(width: 52, height: 52);
    final isVisible = visibleIds.contains(seat.id);
    return _SeatBadge(
      seat: seat,
      dimmed: !isVisible,
      isSelected: selected?.id == seat.id,
      isMine: mySeatIds.contains(seat.id),
      onTap: isVisible ? () => onSelect(seat) : null,
    );
  }
}

/// The signature seat node (spec §3.10): a 52 dp circle with flat
/// container fills and a status ring — never a gradient or a glow.
/// Status is a language, so every state also carries a glyph or shape
/// cue: bolt (power), half clock (limited), diagonal slash (occupied),
/// check badge (yours). Precedence: yours > selected > status.
class _SeatBadge extends StatelessWidget {
  const _SeatBadge({
    required this.seat,
    required this.isSelected,
    required this.isMine,
    required this.onTap,
    this.dimmed = false,
  });

  final Seat seat;
  final bool isSelected;
  final bool isMine;
  final VoidCallback? onTap;

  /// A seat hidden by the active filters: greyed out and non-tappable so
  /// the grid keeps its shape (semantic state `seatFilteredOut`).
  final bool dimmed;

  /// A seat held by the signed-in user wins over the shared status.
  bool get _renderMine => isMine && !isSelected;

  @override
  Widget build(BuildContext context) {
    final statusLabel = dimmed
        ? 'hidden by filters'
        : _renderMine
            ? 'reserved by you'
            : _statusLabel(seat.status);
    final showPower = seat.hasPowerOutlet &&
        !dimmed &&
        !_renderMine &&
        seat.status != SeatStatus.occupied;

    final node = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: 52,
      height: 52,
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _ringColor,
          width: _ringWidth,
        ),
      ),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _fillColor,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            seat.label,
            style: AppText.title(
              12.5,
              w: FontWeight.w700,
              color: dimmed
                  ? AppColors.scheme.onSurfaceVariant
                  : _labelColor,
            ),
          ),
          // Shape cues — status is never colour alone.
          if (seat.status == SeatStatus.occupied && !dimmed && !_renderMine)
            // Diagonal slash across the node.
            SizedBox(
              width: 52,
              height: 52,
              child: Center(
                child: Transform.rotate(
                  angle: -math.pi / 4,
                  child: Container(
                    width: 34,
                    height: 1.8,
                    color: AppColors.seatOccupied
                        .withValues(alpha: 0.75),
                  ),
                ),
              ),
            ),
          if (seat.status == SeatStatus.limited &&
              !dimmed &&
              !_renderMine &&
              !isSelected)
            Positioned(
              top: 5,
              right: 5,
              child: Icon(Icons.timelapse_rounded,
                  size: 12, color: AppColors.seatLimited),
            ),
          if (_renderMine)
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(Icons.check_rounded,
                    size: 10, color: AppColors.seatYours),
              ),
            )
          else if (showPower)
            Positioned(
              right: 5,
              bottom: 5,
              child: Icon(Icons.bolt_rounded,
                  size: 12, color: AppColors.seatAvailable),
            ),
        ],
      ),
    );

    return Semantics(
      label: 'Seat ${seat.label}, $statusLabel',
      button: onTap != null,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: dimmed ? 0.45 : 1,
          child: isSelected
              ? AnimatedScale(
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutBack,
                  scale: 1.08,
                  child: node,
                )
              : node,
        ),
      ),
    );
  }

  /// Fill: solid tertiary when selected, primary when yours, otherwise
  /// the status container colour — always flat.
  Color get _fillColor => dimmed
      ? AppColors.scheme.outlineVariant
      : isSelected
          ? AppColors.seatSelected
          : _renderMine
              ? AppColors.seatYours
              : switch (seat.status) {
                  SeatStatus.available => AppColors.successContainer,
                  SeatStatus.limited => AppColors.warningContainer,
                  SeatStatus.occupied => AppColors.errorContainer,
                };

  /// Ring: 3 px tertiaryContainer halo when selected, 2 px status ring
  /// otherwise, 1.5 px when occupied. Selection is a ring, not a glow.
  Color get _ringColor => dimmed
      ? Colors.transparent
      : isSelected
          ? AppColors.scheme.tertiaryContainer
          : _renderMine
              ? AppColors.seatYours
              : switch (seat.status) {
                  SeatStatus.available => AppColors.seatAvailable,
                  SeatStatus.limited => AppColors.seatLimited,
                  SeatStatus.occupied => AppColors.seatOccupied,
                };

  double get _ringWidth => dimmed
      ? 0
      : isSelected
          ? 3
          : _renderMine
              ? 0
              : seat.status == SeatStatus.occupied
                  ? 1.5
                  : 2;

  Color get _labelColor => isSelected
      ? AppColors.scheme.onTertiary
      : _renderMine
          ? AppColors.scheme.onPrimary
          : switch (seat.status) {
              SeatStatus.available => AppColors.onSuccessContainer,
              SeatStatus.limited => AppColors.onWarningContainer,
              SeatStatus.occupied =>
                AppColors.onErrorContainer.withValues(alpha: 0.70),
            };

  String _statusLabel(SeatStatus status) => switch (status) {
        SeatStatus.available => 'available',
        SeatStatus.limited => 'limited',
        SeatStatus.occupied => 'full',
      };
}

/// The map legend, split into its two semantic rows (D-03): what the
/// seats *are* (availability) versus whose they are (ownership). Never
/// the two mixed on one line.
class _Legend extends StatelessWidget {
  const _Legend({required this.visible, required this.mySeatIds});

  final List<Seat> visible;
  final Set<String> mySeatIds;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _LegendRow(
          label: 'AVAILABILITY',
          items: [
            (
              AppColors.successContainer,
              AppColors.seatAvailable,
              null,
              'Available (${visible.where((s) => s.status == SeatStatus.available).length})'
            ),
            (
              AppColors.warningContainer,
              AppColors.seatLimited,
              Icons.timelapse_rounded,
              'Limited (${visible.where((s) => s.status == SeatStatus.limited).length})'
            ),
            (
              AppColors.errorContainer,
              AppColors.seatOccupied,
              Icons.close_rounded,
              'Full (${visible.where((s) => s.status == SeatStatus.occupied).length})'
            ),
          ],
        ),
        const SizedBox(height: 8),
        _LegendRow(
          label: 'OWNERSHIP',
          items: [
            (
              AppColors.seatSelected,
              AppColors.scheme.tertiaryContainer,
              null,
              'Selected'
            ),
            if (mySeatIds.isNotEmpty)
              (
                AppColors.seatYours,
                AppColors.seatYours,
                Icons.check_rounded,
                'Yours${mySeatIds.length > 1 ? ' ×${mySeatIds.length}' : ''}'
              ),
          ],
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.label, required this.items});

  final String label;

  /// (fill, ring, glyph, text) — the same visual language as the seat
  /// nodes, so the legend teaches the map (spec §3.10).
  final List<(Color, Color, IconData?, String)> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        Text(
          label,
          style: AppText.overline(9, ls: 1.1, color: AppColors.textFaint),
        ),
        for (final (fill, ring, glyph, text) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fill,
                  border: Border.all(color: ring, width: 1.6),
                ),
                child: glyph == null
                    ? null
                    : Icon(glyph, size: 8, color: ring),
              ),
              const SizedBox(width: 6),
              Text(text,
                  style: AppText.body(11.5, color: AppColors.textSecondary)),
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
      tint: AppColors.primary,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'TOP PICK',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.overline(9,
                              ls: 0.8, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(
                  'Available',
                  style: AppText.label(11,
                      w: FontWeight.w600, color: AppColors.success),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seat ${seat.label}',
                      style: AppText.title(18, w: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      why,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textInverse,
                  shape: const StadiumBorder(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  minimumSize: const Size(0, 38),
                ),
                child: Text(
                  'Select Spot',
                  style: AppText.label(12.5,
                      w: FontWeight.w700, color: AppColors.textInverse),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
