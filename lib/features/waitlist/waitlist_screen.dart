import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import 'waitlist_joined_screen.dart';

/// P-09 Waiting List.
///
/// Shown when the wanted seat is taken: what the user is waiting for, their
/// preferences, their place in the queue, and the join action.
class WaitlistScreen extends StatelessWidget {
  const WaitlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final alreadyWaiting = state.waitlist.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Waiting List',
            style: AppText.title(17, w: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const Callout(
            icon: Icons.warning_amber_rounded,
            tone: CalloutTone.warning,
            message:
                'This seat is currently unavailable. Seat 2C is occupied '
                'until 5:00 PM.',
          ),
          const SizedBox(height: 22),
          const SectionLabel('Your preferences'),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PreferenceChip(label: 'Quiet Area'),
              _PreferenceChip(label: 'Power Outlet'),
              _PreferenceChip(label: 'Floor 2'),
            ],
          ),
          const SizedBox(height: 30),
          Center(
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => AppGradients.aurora
                      .createShader(bounds),
                  child: CountUp(
                    value: 3,
                    style: AppText.display(
                      58,
                      w: FontWeight.w800,
                      ls: -1.6,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text('Your position in queue',
                    style: AppText.body(14, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  'Estimated Wait: Approximately 45 minutes',
                  style: AppText.body(12.5, color: AppColors.textFaint),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Callout(
            icon: Icons.notifications_active_outlined,
            message:
                'You will be notified via push notification and email when a '
                'matching seat becomes available.',
          ),
          const SizedBox(height: 26),
          PrimaryButton(
            label: alreadyWaiting ? 'Already on the waitlist' : 'Join Waiting List',
            onPressed: alreadyWaiting
                ? null
                : () {
                    final entry = AppScope.read(context).joinWaitlist(
                      title: 'Seat 2C',
                      subtitle: 'Floor 2 · Quiet Wing',
                      seatPreference: 'Quiet Area + Power Outlet',
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WaitlistJoinedScreen(entry: entry),
                      ),
                    );
                  },
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: 'Cancel',
            tone: ButtonTone.secondary,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

class _PreferenceChip extends StatelessWidget {
  const _PreferenceChip({required this.label});

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
      child: Text(label, style: AppText.label(12.5, w: FontWeight.w600)),
    );
  }
}
