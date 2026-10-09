import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/navigation/app_route.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/motion3d.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import 'active_session_screen.dart';

/// S18 · QR Ticket — the student's scannable pass, built on the
/// notched TicketCard motif (spec §2.4): identity on top, QR below the
/// perforation, always ink-on-white, works offline.
class QrTicketScreen extends StatelessWidget {
  const QrTicketScreen({super.key, required this.booking});

  final SeatBooking booking;

  @override
  Widget build(BuildContext context) {
    final time =
        '${DateFormat('HH:mm').format(booking.startTime)} – ${DateFormat('HH:mm').format(booking.endTime)}';
    final day = DateFormat('EEE d MMM').format(booking.date);

    // Track the live booking so a staff-side check-in or the local
    // "I've arrived" action flips the pass in place (spec S18 Conflict).
    final state = AppScope.of(context);
    final live = state.bookings.firstWhere(
      (b) => b.id == booking.id,
      orElse: () => booking,
    );
    final checkedIn = live.checkedInAt != null;

    return AppScaffold(
      title: 'Your pass',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
        children: [
          Text(
            'Show this at the entrance scanner.',
            textAlign: TextAlign.center,
            style: AppText.body(13.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 22),
          StaggeredEntrance(
            child: TicketCard(
              top: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FLOOR ${live.seat.floor} · ${live.seat.section.toUpperCase()}',
                    style: AppText.body(
                      12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          'Seat ${live.seat.label}',
                          style: AppText.display(30, ls: -1.2),
                        ),
                      ),
                      StatusPill(
                        label: checkedIn ? 'CHECKED IN' : 'ACTIVE',
                        color: AppColors.success,
                        background: AppColors.successContainer,
                        icon: checkedIn
                            ? Icons.how_to_reg_rounded
                            : Icons.event_available_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '$day · $time',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(
                            13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              bottom: Column(
                children: [
                  // Tap the tile to flip it over — the booking code and
                  // check-in window live on the back of the pass.
                  Flip3D(
                    front: QrPassTile(data: live.qrCode),
                    back: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.base, vertical: AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'BOOKING CODE',
                            style: AppText.overline(
                              11,
                              ls: 1.4,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SelectableText(
                            live.qrCode,
                            textAlign: TextAlign.center,
                            style: AppText.title(
                              17,
                              w: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Staff can key this in when the scanner can\'t read the QR.',
                            textAlign: TextAlign.center,
                            style: AppText.body(
                              12,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flip_rounded,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Tap pass to flip',
                            style: AppText.body(
                              12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off_rounded,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Works offline',
                            style: AppText.body(
                              12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          if (!checkedIn)
            PrimaryButton(
              label: "I've arrived",
              icon: Icons.how_to_reg_rounded,
              tone: ButtonTone.secondary,
              onPressed: state.checkIn,
            )
          else
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Callout(
                    tone: CalloutTone.success,
                    icon: Icons.how_to_reg_rounded,
                    title: 'Checked in',
                    message:
                        'Checked in at ${DateFormat('HH:mm').format(live.checkedInAt!)}. Enjoy your session.',
                  ),
                ),
                PrimaryButton(
                  label: 'Open active session',
                  trailingIcon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    AppRoute.push(
                      context,
                      ActiveSessionScreen(booking: live),
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}
