import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/reservation_repository.dart';

/// Asks the user to confirm cancelling a reservation.
/// Resolves to `true` only when the user explicitly confirms.
Future<bool> showCancelReservationDialog(
  BuildContext context,
  ReservationRecord record,
) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (dialogContext) => _CancelConfirmationDialog(record: record),
  ).then((confirmed) => confirmed ?? false);
}

class _CancelConfirmationDialog extends StatelessWidget {
  const _CancelConfirmationDialog({required this.record});

  final ReservationRecord record;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      title: Row(
        children: [
          IconBadge(
            icon: Icons.warning_amber_rounded,
            color: AppColors.error,
            size: 40,
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Text(
              'Cancel Reservation?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to cancel this reservation?',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
      ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 44),
          ),
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep Reservation'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 44),
            backgroundColor: AppColors.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Cancel Reservation'),
        ),
      ],
    );
  }
}

/// Cancels the reservation (after confirmation) and surfaces the standard
/// success snackbar.
Future<void> confirmAndCancelReservation(
  BuildContext context,
  ReservationRecord record,
) async {
  final confirmed = await showCancelReservationDialog(context, record);
  if (!confirmed || !context.mounted) return;
  ReservationRepository.instance.cancel(record.id);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Reservation cancelled successfully.'),
    ),
  );
}
