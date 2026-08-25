import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import 'booking_confirmation_screen.dart';

class SeatDetailScreen extends StatelessWidget {
  const SeatDetailScreen({super.key, required this.seat});

  final Seat seat;

  @override
  Widget build(BuildContext context) {
    final canBook = seat.status == SeatStatus.available;
    final statusColor = switch (seat.status) {
      SeatStatus.available => AppColors.seatAvailable,
      SeatStatus.reserved => AppColors.seatReserved,
      SeatStatus.occupied => AppColors.seatOccupied,
    };

    final typeLabel = switch (seat.type) {
      SeatType.quiet => 'Quiet study',
      SeatType.group => 'Group study',
      SeatType.computer => 'Computer station',
    };

    return Scaffold(
      appBar: AppBar(title: Text('Seat ${seat.label}')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          SoftCard(
            elevated: true,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withValues(alpha: 0.12),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Icon(Icons.event_seat_rounded, size: 48, color: statusColor),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Seat ${seat.label}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                StatusChip(
                  label: seatStatusLabel(seat.status.name),
                  color: statusColor,
                  icon: canBook ? Icons.check_circle_outline : Icons.lock_outline_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SoftCard(
            elevated: true,
            child: Column(
              children: [
                InfoRow(icon: Icons.layers_outlined, label: 'Floor', value: 'Floor ${seat.floor}'),
                const Divider(),
                InfoRow(icon: Icons.place_outlined, label: 'Section', value: seat.section),
                const Divider(),
                InfoRow(icon: Icons.volume_off_outlined, label: 'Area type', value: typeLabel),
                const Divider(),
                InfoRow(
                  icon: Icons.power_outlined,
                  label: 'Power outlet',
                  value: seat.hasPowerOutlet ? 'Available' : 'Not available',
                ),
                const Divider(),
                InfoRow(
                  icon: Icons.directions_walk_outlined,
                  label: 'Distance from entrance',
                  value: '${seat.distanceFromEntranceMeters} meters',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: canBook
            ? ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingConfirmationScreen(seat: seat),
                  ),
                ),
                icon: const Icon(Icons.event_available_rounded),
                label: const Text('Book this seat'),
              )
            : OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to waitlist for this section.')),
                  );
                },
                icon: const Icon(Icons.hourglass_top_rounded),
                label: const Text('Join waitlist'),
              ),
      ),
    );
  }
}
