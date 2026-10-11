import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/navigation/app_route.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/mock/mock_data.dart';
import '../../models/models.dart';
import '../reservations/live_widgets.dart';
import 'seat_detail_screen.dart';
import 'forest_scene.dart';
import 'seat_filter_sheet.dart';

/// P-06 Seat Map.
///
/// A polished, architectural interactive seat map with multi-floor browsing,
/// live occupancy indicators, smart recommendation card, accessible list view,
/// and smooth desk selection.
class SeatMapScreen extends StatefulWidget {
  const SeatMapScreen({super.key});

  @override
  State<SeatMapScreen> createState() => _SeatMapScreenState();
}

class _SeatMapScreenState extends State<SeatMapScreen> {
  SeatFilters _filters = const SeatFilters();
  Seat? _selected;
  String _view = 'Map';

  int get _currentFloorNumber =>
      int.tryParse(_filters.floor.replaceAll(RegExp(r'[^0-9]'), '')) ?? 2;

  /// Inventory for the selected floor. If state has seats, use that floor's
  /// seats (or fallback to MockData floor plan if not yet populated for this
  /// floor). If state.seats is explicitly empty (e.g. testing _NoSeats),
  /// returns empty list so empty states trigger.
  List<Seat> get _floorSeats {
    final floor = _currentFloorNumber;
    final seats = AppScope.of(context).seats;
    if (seats.isEmpty) return const [];
    final onFloor = seats.where((seat) => seat.floor == floor).toList();
    if (onFloor.isNotEmpty) return onFloor;
    return MockData.seatsForFloor(floor);
  }

  List<Seat> get _visible {
    return _floorSeats.where(_filters.matches).toList();
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
      if (seat.floor == _currentFloorNumber) score += 2;
      if (score > bestScore) {
        best = seat;
        bestScore = score;
      }
    }
    if (best == null) return null;
    return (seat: best, reasons: best.matchReasons);
  }

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

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: canPop
            ? GlassAppBar(
                title: 'Seat map',
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
                  color: AppColors.textPrimary,
                  onPressed: () {
                    AppFeedback.tap();
                    Navigator.of(context).maybePop();
                  },
                ),
              )
            : null,
        body: SafeArea(
          top: !canPop,
          bottom: false,
          child: Column(
            children: [
              ConnectivityBanner(lastSyncedAt: state.lastSyncedAt),
              Expanded(
                child: Stack(
                  children: [
                    syncFailed(state)
                        ? syncErrorState(state)
                        : !state.isHydrated
                            ? ListView(
                                padding:
                                    const EdgeInsets.all(AppSpacing.screenMargin),
                                children: const [
                                  Skeleton(height: 120, radius: AppRadii.xl),
                                  SizedBox(height: AppSpacing.base),
                                  Skeleton(height: 280, radius: AppRadii.xl),
                                ],
                              )
                            : refreshable(
                                state,
                                SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.screenMargin,
                                    AppSpacing.sm,
                                    AppSpacing.screenMargin,
                                    AppSpacing.xl + 88,
                                  ),
                                  child: _content(state, visible, mySeatIds),
                                ),
                              ),
                    if (selected != null)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 12,
                        child: AnimatedSwitcher(
                          duration: noMotion ? Duration.zero : AppMotion.fast,
                          child: Container(
                            key: ValueKey('float-bar-${selected.id}'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.isDark
                                  ? const Color(0xFF1E293B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(AppRadii.full),
                              border: Border.all(
                                color: AppColors.isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: AppColors.isDark ? 0.45 : 0.14,
                                  ),
                                  blurRadius: 18,
                                  spreadRadius: -2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                _MiniSeat(
                                  label: selected.label,
                                  mine: mySeatIds.contains(selected.id),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Seat ${selected.label}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.title(
                                          14.5,
                                          w: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${_statusText(selected.status)} · ${selected.zoneLabel}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.body(
                                          11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PrimaryButton(
                                  label: 'Book seat',
                                  trailingIcon: Icons.arrow_forward_rounded,
                                  onPressed: () => _openDetail(selected),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

  int get _activeFilterCount =>
      _filters.categories.length +
      (_filters.powerOutlet ? 1 : 0) +
      (_filters.monitor ? 1 : 0) +
      (_filters.standingDesk ? 1 : 0);

  void _clearFacilityFilters() => setState(() {
        _filters = _filters.copyWith(
          categories: const {},
          powerOutlet: false,
          monitor: false,
          standingDesk: false,
        );
      });

  void _goToFloor(int floor) => setState(() {
        _filters = _filters.copyWith(floor: 'Floor $floor');
        if (_selected != null && _selected!.floor != floor) _selected = null;
      });

  Widget _content(AppState state, List<Seat> visible, Set<String> mySeatIds) {
    final floorSeats = _floorSeats;
    final top = _recommended;
    final floorNo = _currentFloorNumber;
    final freeByFloor = <int, int>{};
    final countByFloor = <int, int>{};
    for (final f in const [1, 2, 3]) {
      final onFloor = state.seats.where((s) => s.floor == f).toList();
      final floorItems = onFloor.isNotEmpty
          ? onFloor
          : (state.seats.isEmpty ? <Seat>[] : MockData.seatsForFloor(f));
      countByFloor[f] = floorItems.length;
      freeByFloor[f] =
          floorItems.where((s) => s.status == SeatStatus.available).length;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaggeredEntrance(child: _Header(lastSyncedAt: state.lastSyncedAt)),
        const SizedBox(height: AppSpacing.md),
        StaggeredEntrance(
          index: 1,
          child: _FloorPicker(
            selected: floorNo,
            freeByFloor: freeByFloor,
            onSelected: _goToFloor,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        StaggeredEntrance(
          index: 2,
          child: _AvailabilitySummary(
            floorSeats: floorSeats,
            visible: visible,
            activeFilters: _activeFilterCount,
            onFilters: _openFilters,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _FilterChipsBar(
          filters: _filters,
          onToggle: (option) => setState(() {
            switch (option) {
              case 'Quiet Area':
                final next = Set<SeatCategory>.from(_filters.categories);
                if (!next.remove(SeatCategory.quietZone)) {
                  next.add(SeatCategory.quietZone);
                }
                _filters = _filters.copyWith(categories: next);
              case 'Power Outlets':
                _filters = _filters.copyWith(powerOutlet: !_filters.powerOutlet);
              case 'Dual Monitors':
                _filters = _filters.copyWith(monitor: !_filters.monitor);
              case 'Standing Desk':
                _filters =
                    _filters.copyWith(standingDesk: !_filters.standingDesk);
            }
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (visible.isEmpty)
          _EmptyFloor(
            floorHasSeats: floorSeats.isNotEmpty,
            floorLabel: _filters.floor,
            otherFloors: [
              for (final f in const [1, 2, 3])
                if (f != floorNo && (countByFloor[f] ?? 0) > 0)
                  (f, freeByFloor[f] ?? 0),
            ],
            onClear: _clearFacilityFilters,
            onGoToFloor: _goToFloor,
            onLoadSampleSeats: () => state.seedSampleSeats(),
          )
        else ...[
          if (top != null)
            StaggeredEntrance(
              child: _RecommendedCard(
                seat: top.seat,
                reasons: top.reasons,
                onTap: () => _openDetail(top.seat),
              ),
            )
          else
            _NoFreeNote(
              canClear: _activeFilterCount > 0,
              onClear: _clearFacilityFilters,
            ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    _view == 'Map' ? 'Floor map' : 'All seats',
                    style: AppText.title(17, w: FontWeight.w700),
                  ),
                ),
              ),
              _ViewToggle(
                view: _view,
                onChanged: (v) => setState(() => _view = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_view == 'List')
            _SeatList(
              seats: visible,
              selected: _selected,
              mySeatIds: mySeatIds,
              onSelect: (seat) => setState(() => _selected = seat),
              onOpen: _openDetail,
            )
          else
            StaggeredEntrance(
              child: _SeatGridCard(
                visible: visible,
                floorSeats: floorSeats,
                selected: _selected,
                mySeatIds: mySeatIds,
                onSelect: (seat) => setState(() => _selected = seat),
                onOpen: _openDetail,
                floorNo: floorNo,
              ),
            ),
        ],
      ],
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

const Color _onAmber = Colors.white;

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
        borderRadius: BorderRadius.circular(12),
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

/// Screen header with live status pill, modern typography and subtitle.
class _Header extends StatelessWidget {
  const _Header({required this.lastSyncedAt});

  final DateTime? lastSyncedAt;

  @override
  Widget build(BuildContext context) {
    final isDemo = AppScope.of(context).dataSource == DataSource.demo;
    final isDark = AppColors.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.card),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/hilltop_sanctuary.png',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.4),
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF163832),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (isDark
                                  ? const Color(0xFF051F20)
                                  : const Color(0xFF163832))
                              .withValues(alpha: 0.88),
                          Colors.transparent,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: const [0.48, 1.0],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF8EB69B).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(AppRadii.full),
                        ),
                        child: Text(
                          'HILLTOP STUDY SANCTUARY',
                          style: AppText.overline(
                            10,
                            ls: 1.0,
                            color: const Color(0xFFDAF1DE),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Desks & Reading Pods',
                        style: AppText.title(
                          17,
                          w: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Quiet pods, garden desks & power outlets',
                        style: AppText.body(
                          11.5,
                          color:
                              const Color(0xFFDAF1DE).withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Text(
          'Pick your seat',
          style: AppText.title(26, w: FontWeight.w800, ls: -0.6),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap a free spot, then continue to reserve it.',
          style: AppText.body(13.5, color: AppColors.textSecondary),
        ),
        if (!isDemo) ...[
          const SizedBox(height: 8),
          LiveFreshness(lastSyncedAt: lastSyncedAt),
        ],
      ],
    );
  }
}

/// Three elevated floor cards with distinct zone identity and live counters.
class _FloorPicker extends StatelessWidget {
  const _FloorPicker({
    required this.selected,
    required this.freeByFloor,
    required this.onSelected,
  });

  final int selected;
  final Map<int, int> freeByFloor;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final floor in const [1, 2, 3]) ...[
          if (floor > 1) const SizedBox(width: 10),
          Expanded(
            child: _FloorCard(
              floor: floor,
              free: freeByFloor[floor] ?? 0,
              selected: floor == selected,
              onTap: () {
                if (floor == selected) return;
                AppFeedback.select();
                onSelected(floor);
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _FloorCard extends StatelessWidget {
  const _FloorCard({
    required this.floor,
    required this.free,
    required this.selected,
    required this.onTap,
  });

  final int floor;
  final int free;
  final bool selected;
  final VoidCallback onTap;

  String get _floorSubtitle => switch (floor) {
        1 => 'Commons',
        2 => 'Quiet Wing',
        _ => 'Silent Pods',
      };

  IconData get _floorIcon => switch (floor) {
        1 => Icons.groups_rounded,
        2 => Icons.menu_book_rounded,
        _ => Icons.laptop_chromebook_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final noMotion = MediaQuery.disableAnimationsOf(context);
    final isAvailable = free > 0;
    final dot = isAvailable ? AppColors.success : AppColors.textFaint;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Floor $floor, $free ${free == 1 ? 'seat' : 'seats'} free',
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        feedback: PressFeedback.none,
        child: AnimatedContainer(
          duration: noMotion ? Duration.zero : AppMotion.fast,
          curve: AppMotion.enter,
          constraints: const BoxConstraints(minHeight: 74),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                    .withValues(alpha: AppColors.isDark ? 0.22 : 0.12)
                : AppGlass.cardFill,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: selected ? AppColors.primary : AppGlass.border,
              width: selected ? 1.8 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Floor $floor',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title(
                        14,
                        w: FontWeight.w800,
                        color: selected
                            ? AppColors.primaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _floorIcon,
                    size: 13,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textFaint,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _floorSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label(
                  10.5,
                  w: FontWeight.w600,
                  color: selected
                      ? AppColors.primaryDark.withValues(alpha: 0.85)
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration:
                        BoxDecoration(color: dot, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '$free free',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        11.5,
                        w: FontWeight.w600,
                        color: isAvailable
                            ? (selected
                                ? AppColors.primaryDark
                                : AppColors.textPrimary)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The live availability summary HUD: radial occupancy dial, live status,
/// and rounded filter button with badge.
class _AvailabilitySummary extends StatelessWidget {
  const _AvailabilitySummary({
    required this.floorSeats,
    required this.visible,
    required this.activeFilters,
    required this.onFilters,
  });

  final List<Seat> floorSeats;
  final List<Seat> visible;
  final int activeFilters;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) {
    final free = visible.where((s) => s.status == SeatStatus.available).length;
    final total = visible.length;
    final occupied =
        floorSeats.where((s) => s.status == SeatStatus.occupied).length;
    final inUse = floorSeats.isEmpty ? 0.0 : occupied / floorSeats.length;
    final freeFraction = total == 0 ? 0.0 : free / total;
    final tone = total == 0
        ? AppColors.textSecondary
        : free == 0
            ? AppColors.warning
            : freeFraction < 0.25
                ? AppColors.warning
                : AppColors.success;
    final headline = total == 0
        ? 'No seats to show'
        : free == 0
            ? 'Fully booked right now'
            : '$free of $total seats free';

    return GlassSurface(
      radius: AppRadii.xl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Semantics(
            label: '$free of $total seats available',
            excludeSemantics: true,
            child: SizedBox(
              width: 58,
              height: 58,
              child: CustomPaint(
                painter: _RingPainter(
                  fraction: freeFraction,
                  color: tone,
                  track: AppColors.border.withValues(alpha: 0.4),
                ),
                child: Center(
                  child: total == 0
                      ? Text(
                          '0',
                          style: AppText.title(20,
                              w: FontWeight.w800, color: tone),
                        )
                      : CountUp(
                          value: free,
                          style: AppText.title(20,
                              w: FontWeight.w800, color: tone),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title(15.5, w: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  total == 0
                      ? 'Try another floor.'
                      : '${(inUse * 100).round()}% of this floor in use',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            button: true,
            label: activeFilters == 0
                ? 'Filters'
                : 'Filters, $activeFilters active',
            excludeSemantics: true,
            child: PressScale(
              onTap: onFilters,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: activeFilters > 0
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: activeFilters > 0
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: activeFilters > 0
                          ? AppColors.textInverse
                          : AppColors.primary,
                    ),
                    if (activeFilters > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          constraints: const BoxConstraints(
                              minWidth: 18, minHeight: 18),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.amberHighlight,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.background, width: 2),
                          ),
                          child: Text(
                            '$activeFilters',
                            style: AppText.label(10,
                                w: FontWeight.w800, color: _onAmber),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.fraction,
    required this.color,
    required this.track,
  });

  final double fraction;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    canvas.drawArc(
      arc,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    if (fraction > 0) {
      canvas.drawArc(
        arc,
        -math.pi / 2,
        math.pi * 2 * fraction.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.fraction != fraction || old.color != color || old.track != track;
}

/// Smooth, horizontally scrollable filter pill bar with zero edge clipping.
class _FilterChipsBar extends StatelessWidget {
  const _FilterChipsBar({
    required this.filters,
    required this.onToggle,
  });

  final SeatFilters filters;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    const chips = <(String, IconData)>[
      ('Quiet Area', Icons.volume_off_rounded),
      ('Power Outlets', Icons.power_rounded),
      ('Dual Monitors', Icons.monitor_rounded),
      ('Standing Desk', Icons.height_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final (label, icon) in chips) ...[
            _QuickFilterChip(
              label: label,
              icon: icon,
              isSelected: switch (label) {
                'Quiet Area' =>
                  filters.categories.contains(SeatCategory.quietZone),
                'Power Outlets' => filters.powerOutlet,
                'Dual Monitors' => filters.monitor,
                _ => filters.standingDesk,
              },
              onTap: () => onToggle(label),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  const _QuickFilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final noMotion = MediaQuery.disableAnimationsOf(context);
    final activeBg = AppColors.primary;
    final activeFg = AppColors.textInverse;
    final inactiveBg = AppGlass.cardFill;
    final inactiveFg = AppColors.textPrimary;

    return Semantics(
      button: true,
      selected: isSelected,
      child: PressScale(
        onTap: () {
          AppFeedback.select();
          onTap();
        },
        child: AnimatedContainer(
          duration: noMotion ? Duration.zero : AppMotion.fast,
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(AppRadii.full),
            border: Border.all(
              color: isSelected ? activeBg : AppGlass.border,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeBg.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? activeFg : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppText.label(
                  12,
                  w: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? activeFg : inactiveFg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact Map / List view switch.
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.view, required this.onChanged});

  final String view;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(color: AppGlass.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewOption(
            label: 'Map',
            icon: Icons.grid_view_rounded,
            selected: view == 'Map',
            onTap: () => onChanged('Map'),
          ),
          _ViewOption(
            label: 'List',
            icon: Icons.view_list_rounded,
            selected: view == 'List',
            onTap: () => onChanged('List'),
          ),
        ],
      ),
    );
  }
}

class _ViewOption extends StatelessWidget {
  const _ViewOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final noMotion = MediaQuery.disableAnimationsOf(context);
    final tone = selected ? AppColors.textInverse : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      child: PressScale(
        onTap: selected ? () {} : onTap,
        child: AnimatedContainer(
          duration: noMotion ? Duration.zero : AppMotion.fast,
          constraints: const BoxConstraints(minHeight: 34),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: tone),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppText.label(12, w: FontWeight.w700, color: tone),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoFreeNote extends StatelessWidget {
  const _NoFreeNote({required this.canClear, required this.onClear});

  final bool canClear;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hourglass_bottom_rounded,
              size: 22, color: AppColors.onWarningContainer),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nothing free right now',
                  style: AppText.title(14.5,
                      w: FontWeight.w700, color: AppColors.onWarningContainer),
                ),
                const SizedBox(height: 2),
                Text(
                  'Seats open up all the time. Try another floor'
                  '${canClear ? ' or loosen your filters' : ''}.',
                  style: AppText.body(12.5,
                      color: AppColors.onWarningContainer
                          .withValues(alpha: 0.85)),
                ),
                if (canClear)
                  TextButton(
                    onPressed: onClear,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 44),
                      alignment: Alignment.centerLeft,
                      foregroundColor: AppColors.onWarningContainer,
                    ),
                    child: Text('Clear filters',
                        style: AppText.label(13,
                            w: FontWeight.w700,
                            color: AppColors.onWarningContainer)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Refined empty state card: glowing icon, informative message, and actionable buttons.
class _EmptyFloor extends StatelessWidget {
  const _EmptyFloor({
    required this.floorHasSeats,
    required this.floorLabel,
    required this.otherFloors,
    required this.onClear,
    required this.onGoToFloor,
    this.onLoadSampleSeats,
  });

  final bool floorHasSeats;
  final String floorLabel;
  final List<(int, int)> otherFloors;
  final VoidCallback onClear;
  final ValueChanged<int> onGoToFloor;
  final VoidCallback? onLoadSampleSeats;

  @override
  Widget build(BuildContext context) {
    return FrostedCard(
      radius: AppRadii.xl,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySoft
                  .withValues(alpha: AppColors.isDark ? 0.35 : 0.65),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              floorHasSeats
                  ? Icons.filter_alt_off_rounded
                  : Icons.event_seat_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            floorHasSeats
                ? 'No seats match these filters'
                : '$floorLabel has no seats yet',
            textAlign: TextAlign.center,
            style: AppText.title(17, w: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            floorHasSeats
                ? 'Every desk here is hidden by your filters. Clear them to '
                    'see the whole floor.'
                : otherFloors.isEmpty
                    ? 'Pull down to refresh, or check back in a moment.'
                    : 'Jump to a floor that does.',
            textAlign: TextAlign.center,
            style: AppText.body(13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          if (floorHasSeats)
            PrimaryButton(
              label: 'Clear filters',
              icon: Icons.refresh_rounded,
              onPressed: onClear,
            )
          else if (otherFloors.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final (floor, free) in otherFloors)
                  PressScale(
                    onTap: () => onGoToFloor(floor),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.base),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.full),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stairs_rounded,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Floor $floor · $free free',
                            style: AppText.label(13,
                                w: FontWeight.w700, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            )
          else if (onLoadSampleSeats != null)
            PrimaryButton(
              label: 'Load Sample Floor Plan',
              icon: Icons.layers_outlined,
              onPressed: onLoadSampleSeats!,
            ),
        ],
      ),
    );
  }
}

/// Architectural seat grid card with window orientation and tactile desk badges.
class _SeatGridCard extends StatelessWidget {
  const _SeatGridCard({
    required this.visible,
    required this.floorSeats,
    required this.selected,
    required this.mySeatIds,
    required this.onSelect,
    required this.floorNo,
    this.onOpen,
  });

  final List<Seat> visible;
  final List<Seat> floorSeats;
  final Seat? selected;
  final Set<String> mySeatIds;
  final ValueChanged<Seat> onSelect;
  final ValueChanged<Seat>? onOpen;
  final int floorNo;

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

    // The map sits on a dark clearing in front of a misty pine forest: the
    // crowns rise above and beside the panel, the seats stay on solid dark
    // green so every tile and label keeps its contrast in both themes.
    final isDark = AppColors.isDark;
    const cream = Color(0xFFF3E8D6);
    final faint = isDark
        ? const Color(0xFFE2E8F0)
        : cream.withValues(alpha: 0.85);

    final panel = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F1B14).withValues(alpha: 0.96)
            : const Color(0xFF0E1D13).withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isDark
              ? const Color(0xFF34D399).withValues(alpha: 0.35)
              : cream.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.window_rounded, size: 14, color: faint),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'WINDOW WALL · NATURAL LIGHT',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.overline(9.5, ls: 1.1, color: faint),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF34D399).withValues(alpha: 0.15)
                      : cream.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF34D399).withValues(alpha: 0.35)
                        : cream.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.compass_calibration_outlined,
                        size: 11, color: faint),
                    const SizedBox(width: 4),
                    Text(
                      'NORTH WING',
                      style: AppText.overline(9, ls: 0.8, color: faint),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: isDark
                ? const Color(0xFF34D399).withValues(alpha: 0.25)
                : cream.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, box) {
              final needed = cols * 54.0 + (cols - 1) * 12.0;
              return needed > box.maxWidth
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: buildGrid(),
                    )
                  : buildGrid();
            },
          ),
          const SizedBox(height: 20),
          Divider(
            height: 1,
            color: isDark
                ? const Color(0xFF34D399).withValues(alpha: 0.25)
                : cream.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 14),
          _Legend(hasMine: mySeatIds.isNotEmpty, textColor: faint),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.meeting_room_outlined, size: 15, color: faint),
              const SizedBox(width: 6),
              Flexible(
                child: Text('ENTRANCE · STAIRWELL A',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.overline(9.5, ls: 1.2, color: faint)),
              ),
            ],
          ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: AppGlass.shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: Stack(
          children: [
            const Positioned.fill(child: ForestScene()),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 96, 12, 26),
              child: panel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridCell(Seat? seat, Set<String> visibleIds) {
    if (seat == null) return const SizedBox(width: 54, height: 54);
    final isVisible = visibleIds.contains(seat.id);
    final isSelected = selected?.id == seat.id;
    return _SeatBadge(
      seat: seat,
      dimmed: !isVisible,
      isSelected: isSelected,
      isMine: mySeatIds.contains(seat.id),
      onTap: isVisible
          ? () {
              if (isSelected && onOpen != null) {
                onOpen!(seat);
              } else {
                onSelect(seat);
              }
            }
          : null,
    );
  }
}

/// Tactile desk badge node with amenities indicators and clear status states.
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
  final bool dimmed;

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
              color: _glowColor.withValues(alpha: isSelected ? 0.55 : 0.20),
              blurRadius: isSelected ? 16 : 8,
              spreadRadius: isSelected ? 1 : -2,
              offset: isSelected ? const Offset(0, 4) : Offset.zero,
            ),
          ];

    final node = AnimatedContainer(
      duration: noMotion ? Duration.zero : AppMotion.fast,
      curve: AppMotion.enter,
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: _fillColor,
        border: Border.all(color: _ringColor, width: _ringWidth),
        boxShadow: glow,
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 4,
            child: Container(
              width: 22,
              height: 2,
              decoration: BoxDecoration(
                color: (isSelected ? Colors.white : _ringColor)
                    .withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            seat.label,
            style: AppText.title(
              13,
              w: FontWeight.w800,
              color: dimmed ? AppColors.textSecondary : _labelColor,
            ),
          ),
          if (seat.status == SeatStatus.occupied && !dimmed && !_renderMine)
            SizedBox(
              width: 54,
              height: 54,
              child: Center(
                child: Transform.rotate(
                  angle: -math.pi / 4,
                  child: Container(
                    width: 32,
                    height: 1.8,
                    color: AppColors.seatOccupied.withValues(alpha: 0.65),
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
                  size: 11, color: AppColors.seatLimited),
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
                  border: Border.all(color: _ringColor, width: 1.2),
                ),
                child: Icon(Icons.check_rounded, size: 10, color: _ringColor),
              ),
            )
          else if (showPower)
            Positioned(
              right: 5,
              bottom: 5,
              child: Icon(Icons.bolt_rounded,
                  size: 11, color: AppColors.seatAvailable),
            ),
          if (seat.nearWindow &&
              !dimmed &&
              !_renderMine &&
              !isSelected &&
              seat.status == SeatStatus.available)
            Positioned(
              left: 5,
              top: 5,
              child: Icon(Icons.wb_sunny_outlined,
                  size: 10,
                  color: AppColors.seatAvailable.withValues(alpha: 0.7)),
            ),
        ],
      ),
    );

    final springy = AnimatedScale(
      duration: noMotion ? Duration.zero : AppMotion.pressSettle,
      curve: AppMotion.springPress,
      scale: isSelected ? 1.08 : 1,
      child: node,
    );

    final extras = [
      if (seat.hasPowerOutlet) 'power outlet',
      if (seat.nearWindow) 'near window',
    ];
    return Semantics(
      label: 'Seat ${seat.label}, ${seat.zoneLabel.toLowerCase()}, '
          '$statusLabel'
          '${extras.isEmpty ? '' : ', ${extras.join(', ')}'}'
          '${isSelected ? ', selected' : ''}',
      button: onTap != null,
      selected: isSelected,
      excludeSemantics: true,
      child: Opacity(
        opacity: dimmed ? 0.40 : 1,
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

  Color get _fillColor => dimmed
      ? AppColors.scheme.outlineVariant.withValues(alpha: 0.3)
      : isSelected
          ? AppColors.seatSelected
          : _renderMine
              ? AppColors.amberHighlight
              : switch (seat.status) {
                  SeatStatus.available => AppColors.isDark
                      ? const Color(0xFF143823)
                      : AppColors.successContainer.withValues(alpha: 0.85),
                  SeatStatus.limited => AppColors.isDark
                      ? const Color(0xFF452205)
                      : AppColors.warningContainer.withValues(alpha: 0.85),
                  SeatStatus.occupied => AppColors.isDark
                      ? const Color(0xFF1E242B)
                      : const Color(0xFF3B3A34),
                };

  Color get _glowColor => isSelected
      ? AppColors.indigo
      : _renderMine
          ? AppColors.amberHighlight
          : switch (seat.status) {
              SeatStatus.available => AppColors.success,
              SeatStatus.limited => AppColors.warning,
              SeatStatus.occupied => Colors.transparent,
            };

  Color get _ringColor => dimmed
      ? Colors.transparent
      : isSelected
          ? AppColors.indigo
          : _renderMine
              ? AppColors.amberHighlight
              : switch (seat.status) {
                  SeatStatus.available => AppColors.isDark
                      ? const Color(0xFF34D399)
                      : AppColors.seatAvailable.withValues(alpha: 0.6),
                  SeatStatus.limited => AppColors.isDark
                      ? const Color(0xFFFBBF24)
                      : AppColors.seatLimited.withValues(alpha: 0.6),
                  SeatStatus.occupied => AppColors.isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFF3E8D6).withValues(alpha: 0.22),
                };

  double get _ringWidth => dimmed
      ? 0
      : isSelected
          ? 2.5
          : _renderMine
              ? 2.0
              : 1.2;

  Color get _labelColor => isSelected
      ? AppColors.textInverse
      : _renderMine
          ? _onAmber
          : switch (seat.status) {
              SeatStatus.available => AppColors.isDark
                  ? const Color(0xFFECFDF5)
                  : AppColors.onSuccessContainer,
              SeatStatus.limited => AppColors.isDark
                  ? const Color(0xFFFEF3C7)
                  : AppColors.onWarningContainer,
              SeatStatus.occupied => AppColors.isDark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFFF3E8D6).withValues(alpha: 0.7),
            };

  String _statusLabel(SeatStatus status) => switch (status) {
        SeatStatus.available => 'available',
        SeatStatus.limited => 'limited',
        SeatStatus.occupied => 'full',
      };
}

class _Legend extends StatelessWidget {
  const _Legend({required this.hasMine, this.textColor});

  final bool hasMine;

  /// Label colour; defaults to the theme's secondary text.
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    final items = <(Color, Color, IconData?, String)>[
      (
        isDark ? const Color(0xFF143823) : AppColors.successContainer,
        isDark ? const Color(0xFF34D399) : AppColors.seatAvailable,
        null,
        'Free',
      ),
      (
        isDark ? const Color(0xFF452205) : AppColors.warningContainer,
        isDark ? const Color(0xFFFBBF24) : AppColors.seatLimited,
        null,
        'Limited',
      ),
      (
        isDark ? const Color(0xFF1E242B) : const Color(0xFF3B3A34),
        isDark
            ? const Color(0xFF475569)
            : const Color(0xFFF3E8D6).withValues(alpha: 0.3),
        null,
        'Full',
      ),
      (
        AppColors.seatSelected,
        AppColors.seatSelected,
        Icons.check_rounded,
        'Selected'
      ),
      if (hasMine)
        (
          AppColors.amberHighlight,
          AppColors.amberHighlight,
          Icons.check_rounded,
          'Yours'
        ),
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.base,
      runSpacing: AppSpacing.sm,
      children: [
        for (final (fill, ring, glyph, text) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.5),
                  color: fill,
                  border: Border.all(color: ring, width: 1.4),
                ),
                child: glyph == null
                    ? null
                    : Icon(glyph, size: 9, color: AppColors.textInverse),
              ),
              const SizedBox(width: 6),
              Text(text,
                  style: AppText.body(12,
                      color: textColor ?? AppColors.textSecondary)),
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
    final zones = <String, List<Seat>>{};
    for (final seat in seats) {
      zones.putIfAbsent(seat.zoneLabel, () => []).add(seat);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final zone in zones.entries) ...[
          Semantics(
            header: true,
            child: Padding(
              padding: const EdgeInsets.only(
                  left: AppSpacing.xs, bottom: AppSpacing.sm),
              child: Text(
                '${zone.key.toUpperCase()} · ${zone.value.length} SEATS',
                style: AppText.overline(11, color: AppColors.textFaint),
              ),
            ),
          ),
          for (final seat in ([...zone.value]
            ..sort((a, b) => a.label.compareTo(b.label)))) ...[
            _SeatListRow(
              seat: seat,
              isSelected: selected?.id == seat.id,
              isMine: mySeatIds.contains(seat.id),
              onSelect: () => onSelect(seat),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _SeatListRow extends StatelessWidget {
  const _SeatListRow({
    required this.seat,
    required this.isSelected,
    required this.isMine,
    required this.onSelect,
  });

  final Seat seat;
  final bool isSelected;
  final bool isMine;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final extras = [
      if (seat.hasPowerOutlet) 'power outlet',
      if (seat.nearWindow) 'near window',
    ];
    return Semantics(
      container: true,
      selected: isSelected,
      label: 'Seat ${seat.label}, ${seat.zoneLabel.toLowerCase()}, '
          '${_statusText(seat.status).toLowerCase()}'
          '${extras.isEmpty ? '' : ', ${extras.join(', ')}'}'
          '${isMine ? ', reserved by you' : ''}'
          '${isSelected ? ', selected' : ''}',
      child: SurfaceCard(
        borderColor: isSelected
            ? AppColors.primary
            : isMine
                ? AppColors.amberHighlight
                : null,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Seat ${seat.label}',
                      style: AppText.title(16, w: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    'Floor ${seat.floor}',
                    style: AppText.body(12.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (isMine)
                        StatusPill(
                          label: 'Yours',
                          icon: Icons.check_rounded,
                          color: AppColors.gold,
                          compact: true,
                        ),
                      StatusPill(
                        label: _statusText(seat.status),
                        icon: switch (seat.status) {
                          SeatStatus.available =>
                            Icons.check_circle_outline_rounded,
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
                      if (seat.hasPowerOutlet)
                        StatusPill(
                          label: 'Power',
                          icon: Icons.power_rounded,
                          color: AppColors.primary,
                          compact: true,
                        ),
                      if (seat.nearWindow)
                        StatusPill(
                          label: 'Window',
                          icon: Icons.wb_sunny_outlined,
                          color: AppColors.primary,
                          compact: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            OutlinedButton(
              onPressed: () {
                AppFeedback.select();
                onSelect();
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(72, 44),
                shape: const StadiumBorder(),
              ),
              child: Text(isSelected ? 'Selected' : 'Select'),
            ),
          ],
        ),
      ),
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
    return Semantics(
      button: true,
      label: 'Top pick for you: seat ${seat.label}. $why',
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primarySoft
                    .withValues(alpha: AppColors.isDark ? 0.5 : 0.85),
                AppColors.primarySoft
                    .withValues(alpha: AppColors.isDark ? 0.3 : 0.60),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.28),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  seat.label,
                  style: AppText.title(16,
                      w: FontWeight.w800, color: AppColors.textInverse),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 13, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'TOP PICK FOR YOU',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.overline(10,
                                ls: 1.0, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Seat ${seat.label}',
                        style: AppText.title(16.5, w: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      why,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(12,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 18, color: AppColors.textInverse),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
