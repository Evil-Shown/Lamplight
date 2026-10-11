import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../reservations/reservations_screen.dart';

/// P-09A Waitlist Joined.
///
/// Confirmation that the user is in the queue, plus the details of what
/// they are waiting for and how long it is likely to take.
class WaitlistJoinedScreen extends StatelessWidget {
  const WaitlistJoinedScreen({super.key, required this.entry});

  final WaitlistEntry entry;

  @override
  Widget build(BuildContext context) {
    final isBook = entry.type == WaitlistType.book;
    return AppScaffold(
      title: 'Waiting List',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xl),
        children: [
          StaggeredEntrance(
            child: GlassSurface(
              radius: AppRadii.xl,
              tint: AppColors.success.withValues(alpha: 0.14),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    const SuccessCheck(size: 78),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Joined Waiting List',
                      textAlign: TextAlign.center,
                      style: AppText.display(AppText.displayMd,
                          w: FontWeight.w700, ls: -1.0),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'You have been added to the waiting list.',
                      textAlign: TextAlign.center,
                      style: AppText.body(13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          StaggeredEntrance(
            index: 1,
            child: SurfaceCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base, vertical: 6),
              child: Column(
                children: [
                  InfoRow(
                    label: isBook ? 'Preference' : 'Seat Preference',
                    value: entry.seatPreference ?? entry.subtitle,
                  ),
                  const Divider(height: 1),
                  if (!isBook) ...[
                    InfoRow(
                        label: 'Floor',
                        value: entry.subtitle.split('·').first.trim()),
                    const Divider(height: 1),
                  ] else ...[
                    InfoRow(label: 'Title', value: entry.title),
                    const Divider(height: 1),
                  ],
                  InfoRow(
                    label: 'Queue Position',
                    value: '#${entry.position}',
                    valueColor: AppColors.primary,
                  ),
                  const Divider(height: 1),
                  InfoRow(
                    label: 'Estimated Wait',
                    value: '~${entry.estimatedWaitMinutes ?? 45} minutes',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Callout(
            icon: Icons.info_outline_rounded,
            message: 'We will notify you as soon as it is your turn. Keep your '
                'notifications enabled.',
          ),
          const SizedBox(height: 26),
          PrimaryButton(
            label: isBook ? 'View My Reservations' : 'Back to Seat Map',
            onPressed: () {
              final navigator = Navigator.of(context);
              navigator.popUntil((route) => route.isFirst);
              if (isBook) {
                // The shell is not an ancestor of pushed routes, so open the
                // reservations list directly.
                navigator.push(MaterialPageRoute<void>(
                  builder: (_) =>
                      const AuroraBackground(child: ReservationsScreen()),
                ));
              }
            },
          ),
        ],
      ),
    );
  }
}
