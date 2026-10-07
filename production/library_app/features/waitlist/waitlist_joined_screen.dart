import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';

/// P-09A Waitlist Joined.
///
/// Confirmation that the user is in the queue, plus the details of what
/// they are waiting for and how long it is likely to take.
class WaitlistJoinedScreen extends StatelessWidget {
  const WaitlistJoinedScreen({super.key, required this.entry});

  final WaitlistEntry entry;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Waiting List',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          Center(
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1),
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: Icon(Icons.notifications_active_rounded,
                        size: 38, color: AppColors.textInverse),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Joined Waiting List',
                  style: AppText.display(22, w: FontWeight.w700, ls: -0.4),
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
          const SizedBox(height: 28),
          StaggeredEntrance(
            child: SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  InfoRow(
                    label: 'Seat Preference',
                    value: entry.seatPreference ?? entry.subtitle,
                  ),
                  const Divider(height: 1),
                  InfoRow(
                      label: 'Floor',
                      value: entry.subtitle.split('·').first.trim()),
                  const Divider(height: 1),
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
            message:
                'We will notify you as soon as a matching seat becomes '
                'available. Keep your notifications enabled.',
          ),
          const SizedBox(height: 26),
          PrimaryButton(
            label: 'Back to Seat Map',
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }
}
