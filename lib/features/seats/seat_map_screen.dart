import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/navigation/app_route.dart';
import '../../core/feedback/app_feedback.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
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
    final noMotion = MediaQuery.disableAnimationsOf(context);
    final selected = _selected;

    // A tab inside the shell paints the aurora already; a pushed copy
    // gets its own (nested instances pass through).
    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: 'Seat map',
          leading: canPop
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
                  color: AppColors.textPrimary,
                  onPressed: () {
                    AppFeedback.tap();
                    Navigator.of(context).maybePop();
                  },
                )
              : const SizedBox(width: 48),
        ),
        body: Column(
          children: [
            // App-level cached-data banner (D-14).
            ConnectivityBanner(lastSyncedAt: state.lastSyncedAt),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screenMargin,
                    AppSpacing.xs, AppSpacing.screenMargin, AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StaggeredEntrance(
                      child: Text(
                        'Find and reserve your ideal study spot',
                        style: AppText.title(19, w: FontWeight.w700, ls: -0.4),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    StaggeredEntrance(
                      index: 1,
                      // Driven by the real last-synced timestamp (D-06).
                      child: LiveFreshness(lastSyncedAt: state.lastSyncedAt),
                    ),
                    const SizedBox(height: AppSpacing.base),
                    // Floor switcher: a segmented control.
                    StaggeredEntrance(
                      index: 1,
                      child: SegmentedTabs(
                        options: const ['Floor 1', 'Floor 2', 'Floor 3'],
                        selected: _filters.floor,
                        padding: EdgeInsets.zero,
                        onSelected: (value) => setState(
                            () => _filters = _filters.copyWith(floor: value)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    StaggeredEntrance(
                      index: 2,
                      child: _AvailabilitySummary(
                        floorSeats: _floorSeats,
                        visible: visible,
                        floorLabel: _filters.floor,
                        onFilters: _openFilters,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilterChipRow(
                      padding: EdgeInsets.zero,
                      options: const [
                        'Quiet Area',
                        'Power Outlets',
                        'Dual Monitors'
                      ],
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
                    const SizedBox(height: AppSpacing.base),
                    SegmentedTabs(
                      options: const ['Map', 'List'],
                      selected: _view,
                      padding: EdgeInsets.zero,
                      onSelected: (value) => setState(() => _view = value),
                    ),
                    const SizedBox(height: AppSpacing.base),
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
                    const SizedBox(height: AppSpacing.base),
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
                        mySeatIds: mySeatIds,
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
                      const SizedBox(height: AppSpacing.base),
                      _Legend(visible: visible, mySeatIds: mySeatIds),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        // Glass bar slides up with the chosen seat and the one action.
        bottomNavigationBar: AnimatedSwitcher(
          duration: noMotion ? Duration.zero : AppMotion.entranceSettle,
          switchInCurve: AppMotion.springEntrance,
          switchOutCurve: AppMotion.exit,
          transitionBuilder: (child, animation) => ClipRect(
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: selected == null
              ? const SizedBox.shrink(key: ValueKey('no-seat'))
              : BottomActionBar(
                  key: ValueKey('seat-${selected.id}'),
                  child: Row(
                    children: [
                      _MiniSeat(
                        label: selected.label,
                        mine: mySeatIds.contains(selected.id),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Seat ${selected.label}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.title(15, w: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_statusText(selected.status)} · '
                              '${selected.zoneLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.body(11.5,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      PrimaryButton(
                        label: 'Continue',
                        trailingIcon: Icons.arrow_forward_rounded,
                        onPressed: () => _openDetail(selected),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  void _openDetail(Seat seat) {
    AppRoute.push(context, SeatDetailScreen(seat: seat));
  }
}

String _statusText(SeatStatus status) => switch (status) {
      SeatStatus.available => 'Available',
      SeatStatus.limited => 'Limited',
      SeatStatus.occupied => 'Full',
    };

/// Amber marks "yours"; the dark ink keeps the label legible on it in
/// both themes.
const Color _onAmber = Color(0xFF3A2600);

/// A small seat chip for the bottom bar, in the same language as the map.
class _MiniSeat extends StatelessWidget {
  const _MiniSeat({required this.label, required this.mine});

  final String label;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final fill = mine ? AppColors.amberHighlight : AppColors.seatSelected;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        color: fill,
        boxShadow: [
          BoxShadow(
            color: fill.withValues(alpha: 0.45),
            blurRadius: 12,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Text(
        label,
        style: AppText.title(13,
            w: FontWeight.w800, color: mine ? _onAmber : AppColors.textInverse),
      ),
    );
  }
}

/// The live availability summary: a glass hero panel with the free count,
/// the floor's occupancy and the Filters entry.
class _AvailabilitySummary extends StatelessWidget {
  const _AvailabilitySummary({
    required this.floorSeats,
    required this.visible,
    required this.floorLabel,
    required this.onFilters,
  });

  final List<Seat> floorSeats;
  final List<Seat> visible;
  final String floorLabel;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) {
    final free = visible.where((s) => s.status == SeatStatus.available).length;
    final occupied =
        floorSeats.where((s) => s.status == SeatStatus.occupied).length;
    final fullness = floorSeats.isEmpty ? 0.0 : occupied / floorSeats.length;
    return GlassSurface(
      radius: AppRadii.xl,
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: '$free of ${visible.length} seats available',
                  excludeSemantics: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CountUp(
                        value: free,
                        style: AppText.display(34,
                            w: FontWeight.w800,
                            ls: -1.0,
                            color: AppColors.success),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            'of ${visible.length} seats available',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(13,
                                color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              PressScale(
                onTap: onFilters,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded,
                          size: 17, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text('Filters',
                          style: AppText.label(13,
                              w: FontWeight.w600, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          MeterBar(value: fullness, color: AppColors.warning),
          const SizedBox(height: 6),
          Text(
            '$floorLabel is ${(fullness * 100).round()}% full',
            style: AppText.body(11.5, color: AppColors.textSecondary),
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
    final rows = floorSeats.map((s) => s.row).fold(0, math.max) + 1;
    final cols = floorSeats.map((s) => s.col).fold(0, math.max) + 1;

    final grid = List<Seat?>.filled(rows * cols, null);
    for (final seat in floorSeats) {
      grid[seat.row * cols + seat.col] = seat;
    }

    Widget buildGrid() => Column(
          children: [
            for (var row = 0; row < rows; row++) ...[
              if (row > 0) const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var col = 0; col < cols; col++) ...[
                    if (col > 0) const SizedBox(width: AppSpacing.md),
                    _gridCell(grid[row * cols + col], visibleIds),
                  ],
                ],
              ),
            ],
          ],
        );

    // One frosted card holds the whole map: a single surface, no blur
    // per seat.
    return FrostedCard(
      radius: AppRadii.xl,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, AppSpacing.lg, AppSpacing.base, AppSpacing.base),
      tint: AppColors.primary.withValues(alpha: 0.06),
      child: Column(
        children: [
          // Wide floors pan; narrow ones centre as before.
          cols > 6
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: buildGrid(),
                )
              : buildGrid(),
          const SizedBox(height: AppSpacing.lg - 2),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stairs_rounded, size: 15, color: AppColors.textFaint),
              const SizedBox(width: 6),
              Flexible(
                child: Text('ENTRANCE · STAIRWELL A',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.overline(9.5,
                        ls: 1.2, color: AppColors.textFaint)),
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

/// The signature seat node: a 52 dp tile that behaves like a physical
/// key. It springs when chosen (with a select cue from [PressScale]), the
/// chosen seat wears a glowing indigo ring, and the user's own seat is
/// amber. Status is never colour alone: bolt (power), half clock
/// (limited), diagonal slash (occupied), check badge (yours or selected).
/// Precedence: selected > yours > status.
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
    final noMotion = MediaQuery.disableAnimationsOf(context);
    final statusLabel = dimmed
        ? 'hidden by filters'
        : _renderMine
            ? 'reserved by you'
            : _statusLabel(seat.status);
    final showPower = seat.hasPowerOutlet &&
        !dimmed &&
        !_renderMine &&
        seat.status != SeatStatus.occupied;

    final glow = dimmed
        ? <BoxShadow>[]
        : [
            BoxShadow(
              color: _glowColor.withValues(alpha: isSelected ? 0.60 : 0.26),
              blurRadius: isSelected ? 18 : 10,
              spreadRadius: isSelected ? 1 : -2,
            ),
          ];

    final node = AnimatedContainer(
      duration: noMotion ? Duration.zero : AppMotion.fast,
      curve: AppMotion.enter,
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.sm + 2),
        color: _fillColor,
        border: Border.all(color: _ringColor, width: _ringWidth),
        boxShadow: glow,
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Text(
            seat.label,
            style: AppText.title(
              12.5,
              w: FontWeight.w700,
              color: dimmed ? AppColors.textSecondary : _labelColor,
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
                    color: AppColors.seatOccupied.withValues(alpha: 0.75),
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
          if (isSelected || _renderMine)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.scheme.surface,
                  border: Border.all(color: _ringColor, width: 1),
                ),
                child: Icon(Icons.check_rounded, size: 10, color: _ringColor),
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

    // The chosen seat springs up; the press spring comes from PressScale.
    final springy = AnimatedScale(
      duration: noMotion ? Duration.zero : AppMotion.pressSettle,
      curve: AppMotion.springPress,
      scale: isSelected ? 1.1 : 1,
      child: node,
    );

    return Semantics(
      label: 'Seat ${seat.label}, $statusLabel',
      button: onTap != null,
      selected: isSelected,
      excludeSemantics: true,
      child: Opacity(
        opacity: dimmed ? 0.45 : 1,
        child: onTap == null
            ? springy
            : PressScale(
                onTap: onTap!,
                scale: 0.92,
                feedback: PressFeedback.select,
                child: springy,
              ),
      ),
    );
  }

  /// Fill: solid indigo when selected, amber when yours, otherwise the
  /// status container colour.
  Color get _fillColor => dimmed
      ? AppColors.scheme.outlineVariant
      : isSelected
          ? AppColors.seatSelected
          : _renderMine
              ? AppColors.amberHighlight
              : switch (seat.status) {
                  SeatStatus.available => AppColors.successContainer,
                  SeatStatus.limited => AppColors.warningContainer,
                  SeatStatus.occupied => AppColors.errorContainer,
                };

  Color get _glowColor => isSelected
      ? AppColors.indigo
      : _renderMine
          ? AppColors.amberHighlight
          : switch (seat.status) {
              SeatStatus.available => AppColors.success,
              SeatStatus.limited => AppColors.warning,
              SeatStatus.occupied => AppColors.textFaint,
            };

  Color get _ringColor => dimmed
      ? Colors.transparent
      : isSelected
          ? AppColors.indigo
          : _renderMine
              ? AppColors.amberHighlight
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
              ? 2.5
              : seat.status == SeatStatus.occupied
                  ? 1.5
                  : 2;

  Color get _labelColor => isSelected
      ? AppColors.textInverse
      : _renderMine
          ? _onAmber
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
    return FrostedCard(
      radius: AppRadii.lg,
      shadows: false,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _LegendRow(
            label: 'AVAILABILITY',
            items: [
              (
                AppColors.successContainer,
                AppColors.seatAvailable,
                Icons.bolt_rounded,
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
          const SizedBox(height: AppSpacing.sm),
          _LegendRow(
            label: 'OWNERSHIP',
            items: [
              (
                AppColors.seatSelected,
                AppColors.seatSelected,
                Icons.check_rounded,
                'Selected'
              ),
              if (mySeatIds.isNotEmpty)
                (
                  AppColors.amberHighlight,
                  AppColors.amberHighlight,
                  Icons.check_rounded,
                  'Yours${mySeatIds.length > 1 ? ' ×${mySeatIds.length}' : ''}'
                ),
            ],
          ),
        ],
      ),
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
      spacing: AppSpacing.base,
      runSpacing: AppSpacing.sm,
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
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fill,
                  border: Border.all(color: ring, width: 1.6),
                ),
                child: glyph == null
                    ? null
                    : Icon(
                        glyph,
                        size: 9,
                        color: fill == ring ? AppColors.textInverse : ring,
                      ),
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
    required this.mySeatIds,
    required this.onSelect,
    required this.onOpen,
  });

  final List<Seat> seats;
  final Seat? selected;
  final Set<String> mySeatIds;
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
            borderColor: selected?.id == seat.id
                ? AppColors.primary
                : mySeatIds.contains(seat.id)
                    ? AppColors.amberHighlight
                    : null,
            child: Row(
              children: [
                Text(seat.label, style: AppText.title(16, w: FontWeight.w700)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    '${seat.zoneLabel} · Floor ${seat.floor}',
                    style: AppText.body(13, color: AppColors.textSecondary),
                  ),
                ),
                if (mySeatIds.contains(seat.id)) ...[
                  StatusPill(
                    label: 'Yours',
                    icon: Icons.check_rounded,
                    color: AppColors.gold,
                    compact: true,
                  ),
                  const SizedBox(width: 6),
                ],
                StatusPill(
                  label: _statusText(seat.status),
                  icon: switch (seat.status) {
                    SeatStatus.available => Icons.check_circle_outline_rounded,
                    SeatStatus.limited => Icons.timelapse_rounded,
                    SeatStatus.occupied => Icons.block_rounded,
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
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              StatusPill(
                label: 'Top pick',
                icon: Icons.auto_awesome_rounded,
                color: AppColors.primary,
                compact: true,
              ),
              StatusPill(
                label: 'Available',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.success,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // The whole card is the tap target; this is its affordance.
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base + 2, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: AppGradients.brand,
                  borderRadius: BorderRadius.circular(AppRadii.full),
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
