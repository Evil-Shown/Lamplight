import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/mock/mock_data.dart';
import '../../models/models.dart';
import 'waitlist_joined_screen.dart';

/// P-09 Waiting List.
///
/// One screen for both resource types (D-08): pass a [seat] for an
/// occupied reading-room desk or a [book] for a fully-loaned title. Shows
/// what the user is waiting for, their preferences, their place in the
/// queue, and the join action.
class WaitlistScreen extends StatelessWidget {
  const WaitlistScreen({super.key, this.seat, this.book});

  final Seat? seat;
  final Book? book;

  WaitlistType get _type => book != null ? WaitlistType.book : WaitlistType.seat;

  String get _title => _type == WaitlistType.book
      ? 'Join Book Waitlist'
      : 'Join Waitlist';

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
    final state = AppScope.of(context);
    final isBook = _type == WaitlistType.book;
    final current = isBook ? null : _seat(context);
    final resourceTitle = isBook ? book!.title : 'Seat ${current!.label}';
    final resourceSubtitle = isBook
        ? 'By ${book!.author}'
        : 'Floor ${current!.floor} · ${current.section}';
    final preferences = isBook
        ? <String>['Any edition', book!.subject]
        : _preferences(current!);

    final mine = state.waitlist.where(
      (entry) => entry.title == resourceTitle,
    );
    final alreadyWaiting = mine.isNotEmpty;
    final position =
        alreadyWaiting ? mine.first.position : state.waitlist.length + 1;

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
        title: Text(_title,
            style: AppText.title(17, w: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Callout(
            icon: Icons.warning_amber_rounded,
            tone: CalloutTone.warning,
            message: isBook
                ? '${book!.title} is fully loaned out. Join the queue and '
                    'we will tell you the moment a copy is returned.'
                : 'Seat ${current!.label} is currently unavailable. Join the '
                    'queue and we will tell you when it frees up.',
          ),
          const SizedBox(height: 22),
          const SectionLabel('Your preferences'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final label in preferences)
                Semantics(
                  label: 'Preference: $label',
                  child: _PreferenceChip(label: label),
                ),
            ],
          ),
          const SizedBox(height: 30),
          Center(
            child: Column(
              children: [
                Semantics(
                  label: 'You are number $position in the queue',
                  child: CountUp(
                    value: position,
                    prefix: '#',
                    style: AppText.display(
                      AppText.displayXl,
                      w: FontWeight.w800,
                      ls: -1.6,
                      color: AppColors.primary,
                    ),
                  ),
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
                'You will be notified in the app when it is your turn.',
          ),
          const SizedBox(height: 26),
          PrimaryButton(
            label: alreadyWaiting ? 'Already on the waitlist' : 'Join waiting list',
            onPressed: alreadyWaiting
                ? null
                : () {
                    final entry = AppScope.read(context).joinWaitlist(
                      title: resourceTitle,
                      subtitle: resourceSubtitle,
                      type: _type,
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
