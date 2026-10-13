import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/notification_repository.dart';
import '../../data/reservation_repository.dart';
import '../notifications/notifications_screen.dart';
import 'cancel_reservation_dialog.dart';
import 'reservation_details_screen.dart';

class MyReservationsScreen extends StatelessWidget {
  const MyReservationsScreen({super.key});

  static const routeName = '/my-reservations';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reservations'),
        actions: [
          ListenableBuilder(
            listenable: NotificationRepository.instance,
            builder: (context, _) {
              final unread = NotificationRepository.instance.unreadCount;
              return IconButton(
                tooltip: 'Notifications',
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text('$unread'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: const _ReservationsBody(),
    );
  }
}

class _ReservationsBody extends StatefulWidget {
  const _ReservationsBody();

  @override
  State<_ReservationsBody> createState() => _ReservationsBodyState();
}

class _ReservationsBodyState extends State<_ReservationsBody> {
  ReservationKind _tab = ReservationKind.book;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: _SegmentedTabs(
                selected: _tab,
                onChanged: (kind) => setState(() => _tab = kind),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: ReservationRepository.instance,
                builder: (context, _) {
                  final reservations =
                      ReservationRepository.instance.activeByKind(_tab);
                  if (reservations.isEmpty) {
                    return EmptyState(
                      icon: _tab == ReservationKind.book
                          ? Icons.bookmark_border_rounded
                          : Icons.event_seat_outlined,
                      title: _tab == ReservationKind.book
                          ? 'No active book reservations'
                          : 'No active seat bookings',
                      message: _tab == ReservationKind.book
                          ? 'Search the catalog and reserve a book to see it here.'
                          : 'Browse the reading room and book a seat to see it here.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppSpacing.xl,
                    ),
                    itemCount: reservations.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            left: AppSpacing.xs,
                            bottom: AppSpacing.xs,
                            top: AppSpacing.xs,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'ACTIVE RESERVATIONS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }
                      final record = reservations[index - 1];
                      return _ReservationCard(
                        record: record,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ReservationDetailsScreen(record: record),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.selected, required this.onChanged});

  final ReservationKind selected;
  final ValueChanged<ReservationKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              label: 'Books',
              icon: Icons.menu_book_rounded,
              isSelected: selected == ReservationKind.book,
              onTap: () => onChanged(ReservationKind.book),
            ),
          ),
          Expanded(
            child: _Segment(
              label: 'Seats',
              icon: Icons.event_seat_rounded,
              isSelected: selected == ReservationKind.seat,
              onTap: () => onChanged(ReservationKind.seat),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
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
    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: isSelected
                ? Border.all(color: AppColors.border)
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({required this.record, required this.onTap});

  final ReservationRecord record;
  final VoidCallback onTap;

  (String, Color) get _stageVisual {
    if (!record.isActive) return ('Cancelled', AppColors.error);
    return switch (record.stage) {
      ReservationStage.confirmed => ('Confirmed', AppColors.info),
      ReservationStage.readyForPickup => ('Ready for Pickup', AppColors.success),
      ReservationStage.waitingList => ('Waiting List', AppColors.warning),
      ReservationStage.expired => ('Expired', AppColors.neutral),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isBook = record.kind == ReservationKind.book;
    final (stageLabel, stageColor) = _stageVisual;

    return SurfaceCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isBook)
                BookCover(
                  title: record.title,
                  color: record.coverColor,
                  width: 52,
                  height: 72,
                )
              else
                IconBadge(
                  icon: Icons.event_seat_rounded,
                  color: AppColors.info,
                  size: 52,
                ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            record.timeRange != null
                                ? '${DateFormat('MMM d, yyyy').format(record.pickupBy)} · ${record.timeRange}'
                                : 'Reserved ${DateFormat('MMM d, yyyy').format(record.reservedOn)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.confirmation_number_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          record.id,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        StatusPill(
                          label: isBook ? 'Book' : 'Seat',
                          color: AppColors.info,
                          compact: true,
                        ),
                        const SizedBox(width: AppSpacing.xs + 2),
                        StatusPill(
                          label: stageLabel,
                          color: stageColor,
                          compact: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  onPressed: onTap,
                  icon: const Icon(Icons.info_outline_rounded, size: 18),
                  label: const Text('View Details'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  onPressed: () =>
                      confirmAndCancelReservation(context, record),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
