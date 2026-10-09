import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';

/// "1 h 40 m", "25 m", "2 d 3 h" or "under 1 m" for a pickup window.
String formatPickupRemaining(Duration d) {
  if (d.inMinutes < 1) return 'under 1 m';
  if (d.inDays >= 1) return '${d.inDays} d ${d.inHours % 24} h';
  if (d.inHours >= 1) return '${d.inHours} h ${d.inMinutes % 60} m';
  return '${d.inMinutes} m';
}

/// Re-reads the pickup window every minute. A plain timer, not an
/// animation, so the text keeps updating when the user reduces motion.
class PickupTicker extends StatefulWidget {
  const PickupTicker({
    super.key,
    required this.reservation,
    required this.builder,
  });

  final BookReservation reservation;

  /// `remaining` is null when the hold was collected or cancelled, and
  /// [Duration.zero] once it has expired.
  final Widget Function(BuildContext context, Duration? remaining) builder;

  @override
  State<PickupTicker> createState() => _PickupTickerState();
}

class _PickupTickerState extends State<PickupTicker> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = AppScope.of(context).pickupRemaining(widget.reservation);
    return widget.builder(context, remaining);
  }
}

/// Banner for a hold: a live countdown while it can be collected, a clear
/// "expired" notice afterwards, nothing once collected or cancelled.
class PickupCountdownBanner extends StatelessWidget {
  const PickupCountdownBanner({super.key, required this.reservation});

  final BookReservation reservation;

  @override
  Widget build(BuildContext context) {
    return PickupTicker(
      reservation: reservation,
      builder: (context, remaining) {
        if (remaining == null) return const SizedBox.shrink();
        final expired = remaining == Duration.zero;
        return Semantics(
          liveRegion: true,
          child: Callout(
            tone: expired ? CalloutTone.danger : CalloutTone.info,
            icon: expired ? Icons.event_busy_rounded : Icons.timer_outlined,
            message: expired
                ? 'This reservation has expired. The copy was released for '
                    'other students.'
                : 'Pick up within ${formatPickupRemaining(remaining)}.',
          ),
        );
      },
    );
  }
}

/// Inline "Pick up within 1 h 40 m" line for cards.
class PickupCountdownText extends StatelessWidget {
  const PickupCountdownText({super.key, required this.reservation});

  final BookReservation reservation;

  @override
  Widget build(BuildContext context) {
    return PickupTicker(
      reservation: reservation,
      builder: (context, remaining) {
        if (remaining == null) return const SizedBox.shrink();
        final expired = remaining == Duration.zero;
        return Text(
          expired
              ? 'Pickup window ended'
              : 'Pick up within ${formatPickupRemaining(remaining)}',
          style: AppText.label(
            13,
            w: FontWeight.w700,
            color: expired ? AppColors.error : AppColors.primary,
          ),
        );
      },
    );
  }
}
