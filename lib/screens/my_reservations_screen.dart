import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/state/app_state.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/shared_widgets.dart';
import '../models/models.dart';

const Color _bookFlowBackground = Color(0xFF141518);
const Color _bookFlowSurface = Color(0xFF22242A);
const Color _bookFlowBorder = Color(0xFF2E313A);
const Color _bookFlowAccent = Color(0xFFE8A838);
const Color _bookFlowTextPrimary = Colors.white;
final Color _bookFlowTextSecondary = Colors.grey[400]!;
const Color _bookFlowTextInverse = Color(0xFF141518);

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  String _tab = 'Active';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final reservations = _tab == 'History'
        ? state.reservationHistory
        : state.activeReservations;

    return Scaffold(
      backgroundColor: _bookFlowBackground,
      appBar: AppBar(
        backgroundColor: _bookFlowBackground,
        foregroundColor: _bookFlowTextPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('My Reservations'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text(
                'Books waiting for pickup and your past reservations',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _bookFlowTextSecondary,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ModeChip(
                    label: 'Active',
                    selected: _tab == 'Active',
                    onSelected: () => setState(() => _tab = 'Active'),
                  ),
                  _ModeChip(
                    label: 'History',
                    selected: _tab == 'History',
                    onSelected: () => setState(() => _tab = 'History'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: reservations.isEmpty
                  ? _EmptyReservationsState(
                      isHistory: _tab == 'History',
                      onBrowse: () => Navigator.of(context).maybePop(),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: reservations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final reservation = reservations[index];
                        return _ReservationCard(
                          reservation: reservation,
                          showCancel: _tab == 'Active',
                          onCancel: () => _confirmCancel(reservation),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BookReservation reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _bookFlowSurface,
          title: const Text('Cancel reservation'),
          content: Text(
            'Cancel ${reservation.book.title} and move it to history?',
            style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                  color: _bookFlowTextSecondary,
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep it'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _bookFlowAccent,
                foregroundColor: _bookFlowTextInverse,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Cancel Reservation'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      AppScope.of(context).cancelReservation(reservation.id);
      if (_tab == 'Active' && AppScope.of(context).activeReservations.isEmpty) {
        setState(() {});
      }
    }
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        color: selected ? _bookFlowTextInverse : _bookFlowTextSecondary,
        fontWeight: FontWeight.w600,
      ),
      selectedColor: _bookFlowAccent,
      backgroundColor: _bookFlowSurface,
      side: const BorderSide(color: _bookFlowBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      showCheckmark: false,
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({
    required this.reservation,
    required this.showCancel,
    required this.onCancel,
  });

  final BookReservation reservation;
  final bool showCancel;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isCancelled = reservation.status == ReservationStatus.cancelled;
    final statusText = switch (reservation.status) {
      ReservationStatus.cancelled => 'Cancelled',
      ReservationStatus.completed => 'Completed',
      ReservationStatus.expiringSoon => 'Expiring soon',
      ReservationStatus.active => 'Active',
      ReservationStatus.ready => 'Ready for pickup',
    };
    final statusColor = switch (reservation.status) {
      ReservationStatus.cancelled => const Color(0xFFE46B6B),
      ReservationStatus.completed => const Color(0xFF8F96A3),
      ReservationStatus.expiringSoon => const Color(0xFFF2C25B),
      ReservationStatus.active => _bookFlowAccent,
      ReservationStatus.ready => const Color(0xFF8FD6A3),
    };

    return Material(
      color: _bookFlowSurface,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: _bookFlowBorder),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(
              title: reservation.book.title,
              color: reservation.book.coverColor,
              isbn: reservation.book.isbn,
              width: 60,
              height: 86,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reservation.book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _bookFlowTextPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    reservation.book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _bookFlowTextSecondary,
                        ),
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.confirmation_number_outlined,
                    label: 'Ref ${reservation.id}',
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.schedule_outlined,
                    label: 'Pickup by ${DateFormat('EEE, d MMM yyyy').format(reservation.pickupBy)}',
                  ),
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.store_mall_directory_outlined,
                    label: '${reservation.pickupLocation} – Counter 01',
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          statusText,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      if (showCancel && !isCancelled)
                        TextButton.icon(
                          onPressed: onCancel,
                          style: TextButton.styleFrom(
                            foregroundColor: _bookFlowAccent,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Cancel Reservation'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _bookFlowAccent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _bookFlowTextSecondary,
                  height: 1.25,
                ),
          ),
        ),
      ],
    );
  }
}

class _EmptyReservationsState extends StatelessWidget {
  const _EmptyReservationsState({
    required this.isHistory,
    required this.onBrowse,
  });

  final bool isHistory;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _bookFlowSurface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: _bookFlowBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _bookFlowBackground,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _bookFlowBorder),
                ),
                child: Icon(
                  isHistory ? Icons.history_rounded : Icons.bookmark_border_rounded,
                  size: 34,
                  color: _bookFlowAccent,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isHistory ? 'No reservation history yet' : 'No active reservations',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _bookFlowTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                isHistory
                    ? 'Cancelled or completed reservations will appear here.'
                    : 'Your confirmed book reservations will appear here once you reserve a title.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _bookFlowTextSecondary,
                      height: 1.5,
                    ),
              ),
              if (!isHistory) ...[
                const SizedBox(height: 18),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _bookFlowAccent,
                    foregroundColor: _bookFlowTextInverse,
                  ),
                  onPressed: onBrowse,
                  child: const Text('Browse books'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}