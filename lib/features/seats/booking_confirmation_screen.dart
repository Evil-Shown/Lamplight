import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart' show AppPolicy;
import '../../core/feedback/app_feedback.dart';
import '../../core/navigation/app_route.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../qr/qr_ticket_screen.dart';

/// P-08 Seat Reserved.
///
/// Confirms the booking and hands over the booking ID that the QR pass
/// will carry, with a refined, tactile boarding-pass presentation.
class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key, required this.booking});

  final SeatBooking booking;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    final timeRange =
        '${DateFormat('h:mm a').format(booking.startTime)} – ${DateFormat('h:mm a').format(booking.endTime)}';
    final dateStr = DateFormat('EEE, d MMM yyyy').format(booking.date);
    final durationHours = booking.endTime.difference(booking.startTime).inMinutes / 60;
    final durationLabel = durationHours == durationHours.roundToDouble()
        ? '${durationHours.toInt()} hr session'
        : '${durationHours.toStringAsFixed(1)} hr session';

    return AppScaffold(
      title: 'Booking confirmed',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          AppSpacing.md,
          AppSpacing.screenMargin,
          AppSpacing.scrollBottomInset,
        ),
        children: [
          // Outcome Hero Banner with soft glowing aura & celebration badge
          StaggeredEntrance(
            index: 0,
            child: GlassSurface(
              radius: AppRadii.xl,
              tint: AppColors.success.withValues(alpha: isDark ? 0.22 : 0.12),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Soft ambient celebration halo
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.success.withValues(alpha: isDark ? 0.35 : 0.22),
                                AppColors.success.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                        const SuccessCheck(size: 80),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Booking confirmed!',
                      textAlign: TextAlign.center,
                      style: AppText.display(
                        24,
                        w: FontWeight.w800,
                        ls: -0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text.rich(
                      TextSpan(
                        text: 'Seat ',
                        style: AppText.body(
                          14,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.28),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                booking.seat.label,
                                style: AppText.title(
                                  13.5,
                                  w: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const TextSpan(text: ' is reserved for you'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Boarding-Pass Style Ticket Card
          StaggeredEntrance(
            index: 1,
            child: TicketCard(
              notchFraction: 0.64,
              top: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pass Header: Zone and Floor Pill Tags
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Icon(
                          Icons.event_seat_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SEAT PASS',
                              style: AppText.overline(
                                10,
                                w: FontWeight.w700,
                                color: AppColors.textFaint,
                                ls: 1.2,
                              ),
                            ),
                            Text(
                              booking.seat.zoneLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.title(14.5, w: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(AppRadii.full),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.layers_outlined,
                              size: 12.5,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Floor ${booking.seat.floor}',
                              style: AppText.label(
                                11.5,
                                w: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Amenities Chips (Window, Power, Monitor, etc.)
                  if (booking.seat.matchReasons.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: booking.seat.matchReasons.map((reason) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 12,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                reason,
                                style: AppText.body(
                                  11,
                                  w: FontWeight.w600,
                                  color: isDark ? const Color(0xFFFDE68A) : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 10),

                  // Metadata Rows with clean iconography
                  _PassDetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: dateStr,
                  ),
                  _PassDetailRow(
                    icon: Icons.schedule_rounded,
                    label: 'Reserved Time',
                    value: timeRange,
                    badge: durationLabel,
                  ),
                  if (booking.seat.section.isNotEmpty)
                    _PassDetailRow(
                      icon: Icons.meeting_room_outlined,
                      label: 'Section',
                      value: booking.seat.section,
                    ),
                ],
              ),
              bottom: InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: booking.id));
                  AppFeedback.tap();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Booking ID copied: ${booking.id}'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadii.lg)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.confirmation_number_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BOOKING ID',
                              style: AppText.overline(
                                10,
                                w: FontWeight.w700,
                                color: AppColors.textFaint,
                                ls: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booking.id,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tooltip(
                        message: 'Copy ID',
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Guided Steps & Notices
          StaggeredEntrance(
            index: 2,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                    : const Color(0xFFF1F5F9).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Turnstile QR Ready',
                          style: AppText.title(13, w: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Show the digital pass at the entrance scanner when arriving.',
                          style: AppText.body(
                            12,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          StaggeredEntrance(
            index: 3,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF261A08).withValues(alpha: 0.6)
                    : const Color(0xFFFFFBEB).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.35 : 0.28),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1.5),
                    child: Icon(
                      Icons.timer_outlined,
                      size: 18,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your seat is released if you don’t check in within ${AppPolicy.checkInGraceMinutes} minutes of start time.',
                      style: AppText.body(
                        12.5,
                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),

          // Interactive CTA Buttons
          StaggeredEntrance(
            index: 4,
            child: PrimaryButton(
              label: 'Show QR Pass',
              icon: Icons.qr_code_rounded,
              onPressed: () => AppRoute.push(
                context,
                QrTicketScreen(booking: booking),
              ),
            ),
          ),
          const SizedBox(height: 10),
          StaggeredEntrance(
            index: 5,
            child: PrimaryButton(
              label: 'Return to Home',
              tone: ButtonTone.secondary,
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact info row inside the boarding pass ticket.
class _PassDetailRow extends StatelessWidget {
  const _PassDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              icon,
              size: 15,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppText.body(13, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                Text(
                  value,
                  textAlign: TextAlign.end,
                  style: AppText.title(13, w: FontWeight.w600),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge!,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

