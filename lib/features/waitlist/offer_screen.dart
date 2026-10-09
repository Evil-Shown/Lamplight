import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../reservations/live_widgets.dart';

/// Opened from an offer notification: the pending offer for [entryId], or a
/// calm "no longer available" note when it was answered or lapsed.
class OfferScreen extends StatelessWidget {
  const OfferScreen({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final offers = state.pendingOffers.where((e) => e.id == entryId).toList();

    return AppScaffold(
      title: 'Your offer',
      body: offers.isEmpty
          ? const EmptyState(
              icon: Icons.timer_off_rounded,
              title: 'This offer is no longer available',
              message:
                  'It was answered or it ran out of time. Check Bookings for '
                  'your other waitlist places.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                AppSpacing.sm,
                AppSpacing.screenMargin,
                AppSpacing.xl,
              ),
              children: [OfferStack(offers: offers)],
            ),
    );
  }
}
