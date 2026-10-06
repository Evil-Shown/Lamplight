import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import 'booking_confirmation_screen.dart';
import '../waitlist/waitlist_joined_screen.dart';

/// P-07 Seat Details.
///
/// The seat's identity, its feature chips, the reservation period, and the
/// amenities included — with reserve or join-waitlist as the action.
class SeatDetailScreen extends StatelessWidget {
  const SeatDetailScreen({super.key, required this.seat});

  final Seat seat;

  bool get _canBook => seat.status == SeatStatus.available;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateFormat('d MMM yyyy').format(now);

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
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 15),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 17, color: AppColors.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Today, $today',
                                style: AppText.body(14)),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              size: 20, color: AppColors.textFaint),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 15),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 17, color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('2:00 PM – 5:00 PM',
                              style: AppText.body(14)),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 30),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text('Edit',
                              style: AppText.label(
                                13,
                                w: FontWeight.w600,
                                color: AppColors.primary,
                              )),
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
          StaggeredEntrance(
            index: 3,
            child: SurfaceCard(
              child: Column(
                children: const [
                  _AmenityRow(
                      label: 'Desk lamp with brightness control'),
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
                label: 'Reserve Seat ${seat.label}',
                onPressed: () {
                  final booking = AppScope.read(context).reserveSeat(seat);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          BookingConfirmationScreen(booking: booking),
                    ),
                  );
                },
              )
            : PrimaryButton(
                label: 'JOIN WAITLIST',
                icon: Icons.hourglass_bottom_rounded,
                tone: ButtonTone.secondary,
                onPressed: () {
                  final entry = AppScope.read(context).joinWaitlist(
                    title: 'Seat ${seat.label}',
                    subtitle: 'Floor 2 · ${seat.section}',
                    seatPreference: '${seat.zoneLabel} + Power Outlet',
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WaitlistJoinedScreen(entry: entry),
                    ),
                  );
                },
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
