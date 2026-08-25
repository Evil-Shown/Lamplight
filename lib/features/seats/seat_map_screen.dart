import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading room'),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: SoftCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$available available · ${seats.length} shown',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const _LegendDot(color: AppColors.seatAvailable, label: 'Free'),
                  const SizedBox(width: 12),
                  const _LegendDot(color: AppColors.seatReserved, label: 'Hold'),
                  const SizedBox(width: 12),
                  const _LegendDot(color: AppColors.seatOccupied, label: 'Busy'),
                ],
              ),
            ),
          ),
          Expanded(
            child: _mapView
                ? _SeatGrid(
                    seats: seats,
                    onSeatTap: (seat) => _openSeat(context, seat),
                  )
                : _SeatList(
                    seats: seats,
                    onSeatTap: (seat) => _openSeat(context, seat),
                  ),
          ),
        ],
      ),
    );
  }

  void _openSeat(BuildContext context, Seat seat) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SeatDetailScreen(seat: seat)),
    );
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _SeatGrid extends StatelessWidget {
  const _SeatGrid({required this.seats, required this.onSeatTap});

  final List<Seat> seats;
  final ValueChanged<Seat> onSeatTap;

  @override
  Widget build(BuildContext context) {
    if (seats.isEmpty) {
      return const EmptyState(
        icon: Icons.event_seat_outlined,
        title: 'No seats match',
        message: 'Try changing floor or section filters.',
      );
    }

    final maxRow = seats.map((s) => s.row).reduce((a, b) => a > b ? a : b);
    final maxCol = seats.map((s) => s.col).reduce((a, b) => a > b ? a : b);

    return InteractiveViewer(
      minScale: 0.85,
      maxScale: 2.2,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppNavInset.bottom,
        ),
        child: SoftCard(
          elevated: true,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.door_front_door_outlined, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Entrance',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (var row = 0; row <= maxRow; row++) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var col = 0; col <= maxCol; col++)
                      _SeatTile(
                        seat: seats.cast<Seat?>().firstWhere(
                              (s) => s!.row == row && s.col == col,
                              orElse: () => null,
                            ),
                        onTap: onSeatTap,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SeatTile extends StatelessWidget {
  const _SeatTile({required this.seat, required this.onTap});

  final Seat? seat;
  final ValueChanged<Seat> onTap;

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
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Semantics(
        label: 'Seat ${seat!.label}, ${seatStatusLabel(seat!.status.name)}',
        button: true,
        child: Material(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => onTap(seat!),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      seat!.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: color,
                      ),
                    ),
                  ),
                  if (seat!.hasPowerOutlet)
                    const Positioned(
                      right: 4,
                      bottom: 3,
                      child: Icon(
                        Icons.bolt_rounded,
                        size: 12,
                        color: Color(0xFFB97A16),
                      ),
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
  const _SeatList({required this.seats, required this.onSeatTap});

  final List<Seat> seats;
  final ValueChanged<Seat> onSeatTap;

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
        AppSpacing.md,
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
          onTap: () => onSeatTap(seat),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.event_seat_rounded, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seat ${seat.label}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Floor ${seat.floor} · ${seat.section} · ${seat.distanceFromEntranceMeters}m in',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
