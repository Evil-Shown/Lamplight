import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';

/// Rebuilds [builder] with the current time every [period]. A plain
/// [Timer], so text keeps counting down when animations are disabled
/// (only motion is turned off, never information). Cancelled on dispose.
class LiveClock extends StatefulWidget {
  const LiveClock({
    super.key,
    required this.builder,
    this.period = const Duration(seconds: 1),
  });

  final Widget Function(BuildContext context, DateTime now) builder;
  final Duration period;

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.period, (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now);
}

/// "1 h 40 m", "12 min" or "45 s" — coarse enough to read at a glance.
String formatRemaining(Duration d) {
  if (d.inHours >= 1) {
    final m = d.inMinutes.remainder(60);
    return m == 0 ? '${d.inHours} h' : '${d.inHours} h $m m';
  }
  if (d.inMinutes >= 1) return '${d.inMinutes} min';
  return '${d.inSeconds} s';
}

/// Below this the countdown turns amber.
const Duration kCountdownWarning = Duration(minutes: 5);

/// A pill that counts down to a deadline: "Check in within 12 min". Amber
/// with a warning icon under five minutes, and a plain "Missed" state at
/// zero, so urgency is never conveyed by colour alone. Renders nothing when
/// [remaining] returns null (not applicable).
class CountdownBadge extends StatelessWidget {
  const CountdownBadge({
    super.key,
    required this.prefix,
    required this.remaining,
    this.missedLabel = 'Missed',
    this.onGradient = false,
  });

  /// Lead-in, e.g. "Check in within".
  final String prefix;
  final Duration? Function(DateTime now) remaining;
  final String missedLabel;

  /// Use the inverse (white) treatment on a gradient hero.
  final bool onGradient;

  @override
  Widget build(BuildContext context) {
    return LiveClock(
      builder: (context, now) {
        final left = remaining(now);
        if (left == null) return const SizedBox.shrink();
        final missed = left <= Duration.zero;
        final warn = !missed && left < kCountdownWarning;
        final text = missed ? missedLabel : '$prefix ${formatRemaining(left)}';
        final icon = missed
            ? Icons.error_outline_rounded
            : warn
                ? Icons.warning_amber_rounded
                : Icons.schedule_rounded;
        final Color fg;
        final Color bg;
        if (missed) {
          fg = AppColors.scheme.onErrorContainer;
          bg = AppColors.errorContainer;
        } else if (warn) {
          fg = AppColors.onWarningContainer;
          bg = AppColors.warningContainer;
        } else if (onGradient) {
          fg = AppColors.textInverse;
          bg = AppColors.textInverse.withValues(alpha: 0.22);
        } else {
          fg = AppColors.isDark ? const Color(0xFFFDE68A) : AppColors.primary;
          bg = AppColors.isDark
              ? const Color(0xFF451A03).withValues(alpha: 0.8)
              : AppColors.primary.withValues(alpha: 0.12);
        }
        return Semantics(
          label: text,
          liveRegion: missed,
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
            decoration: BoxDecoration(
              color: bg,
              border: AppColors.isDark && !onGradient
                  ? Border.all(
                      color: (missed
                              ? AppColors.error
                              : warn
                                  ? AppColors.warning
                                  : const Color(0xFFF59E0B))
                          .withValues(alpha: 0.35),
                      width: 1,
                    )
                  : null,
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(12.5, w: FontWeight.w700, color: fg),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Waitlist status as text + icon + colour (waiting / offered / expired...).
class WaitlistStatusPill extends StatelessWidget {
  const WaitlistStatusPill({super.key, required this.status});

  final WaitlistStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (status) {
      WaitlistStatus.waiting => (
          'Waiting',
          Icons.hourglass_top_rounded,
          AppColors.primary
        ),
      WaitlistStatus.offered => (
          'Offer available',
          Icons.notifications_active_rounded,
          AppColors.success
        ),
      WaitlistStatus.accepted => (
          'Accepted',
          Icons.check_rounded,
          AppColors.success
        ),
      WaitlistStatus.declined => (
          'Declined',
          Icons.close_rounded,
          AppColors.neutral
        ),
      WaitlistStatus.expired => (
          'Expired',
          Icons.timer_off_rounded,
          AppColors.error
        ),
    };
    return StatusPill(label: label, icon: icon, color: color, compact: true);
  }
}

/// "A seat/copy is available for you" with a live countdown and Accept /
/// Decline. The outcome is reported through the nearest [ScaffoldMessenger]
/// because an accepted or declined offer leaves the list straight away
/// (optimistic update), taking this card with it.
class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.entry});

  final WaitlistEntry entry;

  bool get _isSeat => entry.type == WaitlistType.seat;

  Future<void> _respond(BuildContext context, bool accept) async {
    final state = AppScope.read(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final what = _isSeat ? 'seat' : 'copy';
    try {
      await state.respondToOffer(entry.id, accept);
      if (accept) {
        AppFeedback.success();
        messenger?.showSnackBar(SnackBar(
          content: Text(
            _isSeat
                ? 'Seat accepted. It is held for you.'
                : 'Copy accepted. Collect it before the pickup deadline.',
          ),
        ));
      } else {
        messenger?.showSnackBar(SnackBar(
          content: Text('Offer declined. The $what goes to the next person.'),
        ));
      }
    } catch (_) {
      AppFeedback.error();
      messenger?.showSnackBar(SnackBar(
        content: Text(
          'Could not ${accept ? 'accept' : 'decline'} the offer. It may have '
          'expired, or you may be offline.',
        ),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () {
            unawaited(
                state.respondToOffer(entry.id, accept).catchError((_) {}));
          },
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final busy = state.isOfferResponding(entry.id);
    final noun = _isSeat ? 'seat' : 'copy';

    return LiveClock(
      builder: (context, now) {
        final left = state.offerRemaining(entry, now: now);
        final expired = left != null && left <= Duration.zero;
        final urgent = left != null && left < kCountdownWarning && !expired;
        final timer = left == null
            ? 'Respond soon'
            : expired
                ? 'Offer expired'
                : 'Respond within ${formatRemaining(left)}';
        final enabled = !busy && !expired;

        return Semantics(
          container: true,
          label: 'A $noun is available for you. ${entry.title}. $timer.',
          child: GlassSurface(
            radius: AppRadii.xl,
            tint: AppColors.success.withValues(alpha: 0.16),
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconBadge(
                      icon: _isSeat
                          ? Icons.event_seat_rounded
                          : Icons.menu_book_rounded,
                      color: AppColors.success,
                      size: 44,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'A $noun is available for you',
                            style: AppText.title(16, w: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(13,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                StatusPill(
                  label: timer,
                  icon: expired
                      ? Icons.timer_off_rounded
                      : urgent
                          ? Icons.warning_amber_rounded
                          : Icons.schedule_rounded,
                  color: expired
                      ? AppColors.error
                      : urgent
                          ? AppColors.warning
                          : AppColors.success,
                ),
                const SizedBox(height: AppSpacing.base),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: busy ? 'Working…' : 'Accept',
                        icon: Icons.check_rounded,
                        onPressed:
                            enabled ? () => _respond(context, true) : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Decline',
                        tone: ButtonTone.secondary,
                        onPressed:
                            enabled ? () => _respond(context, false) : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Offers stacked with a gap; empty when there are none.
class OfferStack extends StatelessWidget {
  const OfferStack({super.key, required this.offers});

  final List<WaitlistEntry> offers;

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final offer in offers) ...[
          OfferCard(key: ValueKey('offer-${offer.id}'), entry: offer),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

/// True when the live streams failed and there is nothing to show.
bool syncFailed(AppState state) =>
    !state.isHydrated &&
    (state.syncStatus == SyncStatus.permissionDenied ||
        state.syncStatus == SyncStatus.error);

/// The shared error view with a Retry that calls [AppState.refresh].
Widget syncErrorState(AppState state) => ErrorState(
      message: state.syncStatus == SyncStatus.permissionDenied
          ? 'You do not have access to this data. Try signing in again.'
          : (state.lastError?.message ??
              'We could not reach the library service just now.'),
      onRetry: () => state.refresh(),
    );

/// Wraps a scrollable in pull-to-refresh; [state.refresh] drives it.
Widget refreshable(AppState state, Widget child) => RefreshIndicator(
      onRefresh: () => state.refresh(),
      child: child,
    );
