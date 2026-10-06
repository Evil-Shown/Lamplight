import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/mock/mock_data.dart';
import '../../models/models.dart';
import 'waitlist_joined_screen.dart';

/// P-09 Waiting List.
///
/// Shown when the wanted seat is taken: what the user is waiting for, their
/// preferences, their place in the queue, and the join action.
class WaitlistScreen extends StatelessWidget {
  const WaitlistScreen({super.key, this.seat});

  final Seat? seat;

  Seat _seat(BuildContext context) {
    if (seat != null) return seat!;
    final seats = AppScope.of(context).seats;
    return seats.firstWhere(
      (item) => item.label == '2C',
      orElse: () => MockData.seats.first,
    );
  }

  List<String> _preferences(Seat current) {
    return [
      current.zoneLabel,
      if (current.hasPowerOutlet) 'Power Outlet',
      if (current.nearWindow) 'Near window',
      'Floor ${current.floor}',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final current = _seat(context);
    final state = AppScope.of(context);
    final mine = state.waitlist.where(
      (entry) => entry.title == 'Seat ${current.label}',
    );
    final alreadyWaiting = mine.isNotEmpty;
    final position = alreadyWaiting ? mine.first.position : state.waitlist.length + 1;
    final preferences = _preferences(current);

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
          Callout(
            icon: Icons.warning_amber_rounded,
            tone: CalloutTone.warning,
            message:
                'Seat ${current.label} is currently unavailable. Join the '
                'queue and we will tell you when it frees up.',
          ),
          const SizedBox(height: 22),
          const SectionLabel('Your preferences'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final label in preferences) _PreferenceChip(label: label),
            ],
          ),
          const SizedBox(height: 30),
          Center(
            child: Column(
              children: [
                Text(
                  '#$position',
                  style: AppText.display(58, w: FontWeight.w800, ls: -1.6,
                      color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text('Your position in queue',
                    style: AppText.body(14, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  'Estimated wait: about 45 minutes',
                  style: AppText.body(12.5, color: AppColors.textFaint),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Callout(
            icon: Icons.notifications_active_outlined,
            message:
                'You will be notified in the app when a matching seat becomes available.',
          ),
          const SizedBox(height: 26),
          PrimaryButton(
            label: alreadyWaiting ? 'Already on the waitlist' : 'Join waiting list',
            onPressed: alreadyWaiting
                ? null
                : () {
                    final entry = AppScope.read(context).joinWaitlist(
                      title: 'Seat ${current.label}',
                      subtitle: 'Floor ${current.floor} · ${current.section}',
                      seatPreference: preferences.join(' + '),
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
