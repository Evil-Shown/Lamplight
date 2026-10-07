import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/mock/mock_data.dart';
import '../qr/active_session_screen.dart';

/// P-15 Verification Result.
///
/// What the staff member sees after a successful scan: a valid-reservation
/// banner, the student's identity and booking, then confirm or report.
class VerificationResultScreen extends StatelessWidget {
  const VerificationResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const student = MockData.verificationStudent;
    final booking = MockData.buildBookings().first;

    return AppScaffold(
      title: 'Verification Result',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          StaggeredEntrance(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Column(
                children: [
                  const SuccessCheck(size: 54),
                  const SizedBox(height: 12),
                  Text(
                    'Valid reservation',
                    style: AppText.title(
                      17,
                      w: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Identity and booking details matched.',
                    style: AppText.body(12.5, color: AppColors.success),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          StaggeredEntrance(
            index: 1,
            child: SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius:
                              BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Text(
                          booking.seat.label,
                          style: AppText.title(
                            15,
                            w: FontWeight.w800,
                            color: AppColors.textInverse,
                          ),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style:
                                  AppText.title(15.5, w: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              student.studentId,
                              style: AppText.body(
                                  12.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  InfoRow(
                    label: 'Location',
                    value: 'Floor ${booking.seat.floor} – '
                        '${booking.seat.section}',
                  ),
                  const Divider(height: 1),
                  InfoRow(
                    label: 'Date',
                    value: DateFormat('d MMMM yyyy').format(booking.date),
                  ),
                  const Divider(height: 1),
                  InfoRow(
                    label: 'Time',
                    value:
                        '${DateFormat('h:mm a').format(booking.startTime)} – '
                        '${DateFormat('h:mm a').format(booking.endTime)}',
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Near window · Power outlet',
                            style: AppText.body(
                                13.5, color: AppColors.textSecondary),
                          ),
                        ),
                        StatusPill(
                          label: 'Verified',
                          color: AppColors.success,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Confirm Check-in',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ActiveSessionScreen(booking: booking),
              ),
            ),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'Report an Issue',
            tone: ButtonTone.danger,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Issue reported to the duty librarian')),
              );
            },
          ),
        ],
      ),
    );
  }
}
