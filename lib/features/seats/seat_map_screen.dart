import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ledger_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/mock/mock_data.dart';
import '../../models/models.dart';
import 'my_bookings_screen.dart';
import 'seat_detail_screen.dart';

class SeatMapScreen extends StatefulWidget {
  const SeatMapScreen({super.key});

  @override
  State<SeatMapScreen> createState() => _SeatMapScreenState();
}

class _SeatMapScreenState extends State<SeatMapScreen> {
  bool _mapView = true;
  String _floorFilter = 'All floors';
  String _sectionFilter = 'All sections';

  static const _floors = ['All floors', 'Floor 1', 'Floor 2'];
  static const _sections = ['All sections', 'Quiet Zone', 'Group Study'];

  List<Seat> get _filteredSeats {
    return MockData.seats.where((seat) {
      final floorMatch =
          _floorFilter == 'All floors' || _floorFilter == 'Floor ${seat.floor}';
      final sectionMatch =
          _sectionFilter == 'All sections' || seat.section == _sectionFilter;
      return floorMatch && sectionMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final seats = _filteredSeats;
    final available = seats.where((s) => s.status == SeatStatus.available).length;
    final best = _bestMatch(seats);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 84,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('READING ROOM'),
            const SizedBox(height: 3),
            Text('Find a seat', style: AppText.serif(24)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'My bookings',
            icon: const Icon(Icons.event_available_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
            ),
          ),
          IconButton(
            tooltip: _mapView ? 'List view' : 'Map view',
            icon: Icon(_mapView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _mapView = !_mapView),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterChipBar(
            options: _floors,
            selected: _floorFilter,
            onSelected: (v) => setState(() => _floorFilter = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilterChipBar(
            options: _sections,
            selected: _sectionFilter,
            onSelected: (v) => setState(() => _sectionFilter = v),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SoftCard(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: '$available',
                      style: AppText.serif(16, color: AppColors.goldDeep, ls: 0),
                      children: [
                        TextSpan(
                          text: ' available of ${seats.length} shown',
                          style: AppText.sans(13, w: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      _LegendDot(color: AppColors.seatAvailable, label: 'Free'),
                      SizedBox(width: 14),
                      _LegendDot(color: AppColors.seatReserved, label: 'Hold'),
                      SizedBox(width: 14),
                      _LegendDot(color: AppColors.seatOccupied, label: 'Busy'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (best != null) ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: BestMatchCard(
                seatLabel: best.label,
                description:
                    '${best.hasPowerOutlet ? 'Power outlet' : 'Standard desk'} · ${best.distanceFromEntranceMeters} m from entrance · ${best.section}',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SeatDetailScreen(seat: best)),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: _mapView
                ? _SeatGrid(seats: seats, best: best)
                : _SeatList(seats: seats),
          ),
        ],
      ),
    );
  }

  Seat? _bestMatch(List<Seat> seats) {
    final withPower =
        seats.where((s) => s.status == SeatStatus.available && s.hasPowerOutlet);
    if (withPower.isNotEmpty) return withPower.first;
    final anyFree = seats.where((s) => s.status == SeatStatus.available);
    return anyFree.isEmpty ? null : anyFree.first;
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppText.sans(11.5, w: FontWeight.w500, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _SeatGrid extends StatelessWidget {
  const _SeatGrid({required this.seats, required this.best});

  final List<Seat> seats;
  final Seat? best;

  static const _rowLabels = {
    0: 'WINDOW SIDE',
    1: 'CARREL DESKS',
    2: 'GROUP TABLES',
    3: 'LOUNGE SIDE',
  };

  @override
  Widget build(BuildContext context) {
    if (seats.isEmpty) {
      return const EmptyState(
        icon: Icons.event_seat_outlined,
        title: 'No seats match',
        message: 'Try changing floor or section filters.',
      );
    }

    final maxCol = seats.map((s) => s.col).reduce((a, b) => a > b ? a : b);
    final rowsPresent = seats.map((s) => s.row).toSet().toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppNavInset.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SoftCard(
            elevated: true,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Dashed entrance strip
                CustomPaint(
                  foregroundPainter: DashedRRectPainter(
                    color: AppColors.goldDeep.withValues(alpha: 0.55),
                    radius: AppRadii.sm,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.paperDeep.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.south_rounded,
                            size: 14, color: AppColors.goldDeep),
                        const SizedBox(width: 6),
                        Text('ENTRANCE', style: AppText.mono(10.5, ls: 3, color: AppColors.goldDeep)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final (i, row) in rowsPresent.indexed) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ROW ${String.fromCharCode(65 + row)} — ${_rowLabels[row] ?? ''}',
                      style: AppText.mono(9.5, ls: 2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var col = 0; col <= maxCol; col++)
                        _SeatTile(
                          seat: seats.cast<Seat?>().firstWhere(
                                (s) => s!.row == row && s.col == col,
                                orElse: () => null,
                              ),
                          recommended: best?.id,
                        ),
                    ],
                  ),
                  if (i < rowsPresent.length - 1) ...[
                    const SizedBox(height: AppSpacing.md),
                    const DashedRule(),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.goldDeep,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('MARKS POWER OUTLET', style: AppText.mono(9, ls: 2)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _OtherSections(seats: seats),
        ],
      ),
    );
  }
}

class _OtherSections extends StatelessWidget {
  const _OtherSections({required this.seats});

  final List<Seat> seats;

  @override
  Widget build(BuildContext context) {
    final groupFree = MockData.seats
        .where((s) => s.section == 'Group Study' && s.status == SeatStatus.available)
        .length;
    final floor2Free = MockData.seats
        .where((s) => s.floor == 2 && s.status == SeatStatus.available)
        .length;
    final showSections = seats.any((s) => s.section != 'Group Study') ||
        seats.any((s) => s.floor != 2);
    if (!showSections) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Other sections', style: AppText.serif(19)),
        const SizedBox(height: AppSpacing.sm + 2),
        Row(
          children: [
            Expanded(
              child: SoftCard(
                elevated: true,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('GROUP STUDY'),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        text: '$groupFree',
                        style: AppText.serif(22, color: AppColors.goldDeep, ls: 0),
                        children: [
                          TextSpan(
                            text: ' rooms free',
                            style: AppText.sans(12, w: FontWeight.w500,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SoftCard(
                elevated: true,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('FLOOR 2'),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        text: '$floor2Free',
                        style: AppText.serif(22, color: AppColors.goldDeep, ls: 0),
                        children: [
                          TextSpan(
                            text: ' seats free',
                            style: AppText.sans(12, w: FontWeight.w500,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SeatTile extends StatelessWidget {
  const _SeatTile({required this.seat, this.recommended});

  final Seat? seat;
  final String? recommended;

  Color get _color {
    if (seat == null) return Colors.transparent;
    return switch (seat!.status) {
      SeatStatus.available => AppColors.seatAvailable,
      SeatStatus.reserved => AppColors.seatReserved,
      SeatStatus.occupied => AppColors.seatOccupied,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (seat == null) {
      return const SizedBox(width: 48, height: 48);
    }

    final color = _color;
    final isBest = seat!.id == recommended;
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Semantics(
        label:
            'Seat ${seat!.label}, ${seatStatusLabel(seat!.status.name)}${seat!.hasPowerOutlet ? ', power outlet' : ''}',
        button: true,
        child: Material(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SeatDetailScreen(seat: seat!)),
            ),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isBest ? AppColors.gold : color,
                  width: isBest ? 2.2 : 1.6,
                ),
                boxShadow: isBest
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.35),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      seat!.label,
                      style: AppText.mono(12, w: FontWeight.w700, ls: 0.5, color: color),
                    ),
                  ),
                  if (seat!.hasPowerOutlet)
                    const Positioned(
                      right: 5,
                      bottom: 4,
                      child: Icon(Icons.bolt_rounded, size: 11, color: AppColors.goldDeep),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeatList extends StatelessWidget {
  const _SeatList({required this.seats});

  final List<Seat> seats;

  @override
  Widget build(BuildContext context) {
    if (seats.isEmpty) {
      return const EmptyState(
        icon: Icons.event_seat_outlined,
        title: 'No seats match',
        message: 'Try changing floor or section filters.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppNavInset.bottom,
      ),
      itemCount: seats.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final seat = seats[index];
        final color = switch (seat.status) {
          SeatStatus.available => AppColors.seatAvailable,
          SeatStatus.reserved => AppColors.seatReserved,
          SeatStatus.occupied => AppColors.seatOccupied,
        };

        return SoftCard(
          elevated: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SeatDetailScreen(seat: seat)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.event_seat_rounded, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Seat ${seat.label}', style: AppText.serif(16.5, ls: -0.2)),
                    const SizedBox(height: 2),
                    Text(
                      'Floor ${seat.floor} · ${seat.section} · ${seat.distanceFromEntranceMeters} m in',
                      style: AppText.sans(12.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: seatStatusLabel(seat.status.name),
                color: color,
                compact: true,
              ),
            ],
          ),
        );
      },
    );
  }
}
