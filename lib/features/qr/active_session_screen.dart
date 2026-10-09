import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../reservations/live_widgets.dart';

/// HF-S05 Active Session.
///
/// Shown after a successful check-in: a live timer, the allocated desk,
/// the session window, and the three network entitlements the prototype
/// advertises.
class ActiveSessionScreen extends StatefulWidget {
  const ActiveSessionScreen({super.key, required this.booking});

  final SeatBooking booking;

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  late final DateTime _checkedInAt =
      widget.booking.checkedInAt ?? DateTime.now();
  int _extendedMinutes = 0;

  // Ticks every second so the remaining time and elapsed timer stay live.
  @override
  Widget build(BuildContext context) => LiveClock(builder: _content);

  Widget _content(BuildContext context, DateTime now) {
    final booking = widget.booking;
    final elapsed = now.difference(_checkedInAt);
    final endsAt = booking.endTime.add(Duration(minutes: _extendedMinutes));
    final total = endsAt.difference(booking.startTime).inMinutes;
    final used = now.difference(booking.startTime).inMinutes;
    final progress = total <= 0 ? 0.0 : (used / total).clamp(0.0, 1.0);
    final remaining = endsAt.difference(now);
    final remainingLabel = remaining.isNegative
        ? 'Session window ended'
        : '${formatRemaining(remaining)} left';
    final window = '${DateFormat('h:mm a').format(booking.startTime)} – '
        '${DateFormat('h:mm a').format(endsAt)}';

    return AppScaffold(
      title: 'Active Session',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
        children: [
          StaggeredEntrance(
            child: GradientHero(
              padding: const EdgeInsets.all(AppSpacing.lg + 4),
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.textInverse.withValues(alpha: 0.22),
                    ),
                    child: Icon(Icons.verified_rounded,
                        size: 32, color: AppColors.textInverse),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md - 2, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.textInverse.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Text(
                      'STATE: VERIFIED',
                      style: AppText.label(10.5,
                          w: FontWeight.w700,
                          ls: 1.2,
                          color: AppColors.textInverse),
                    ),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    'Check-in Successful',
                    textAlign: TextAlign.center,
                    style: AppText.display(22,
                        w: FontWeight.w800,
                        ls: -0.4,
                        color: AppColors.textInverse),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You are officially checked in. Desk power & Wi-Fi priority '
                    'enabled.',
                    textAlign: TextAlign.center,
                    style: AppText.body(
                      13,
                      color: AppColors.textInverse.withValues(alpha: 0.84),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Glanceable countdown: time left and how far through.
                  Semantics(
                    label: '$remainingLabel, ${(progress * 100).round()} '
                        'percent of the session used',
                    excludeSemantics: true,
                    child: Column(
                      children: [
                        Text(
                          remainingLabel,
                          textAlign: TextAlign.center,
                          style: AppText.display(26,
                              w: FontWeight.w800,
                              ls: -0.6,
                              color: AppColors.textInverse),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        MeterBar(
                          value: progress,
                          height: 8,
                          color: AppColors.textInverse,
                          background:
                              AppColors.textInverse.withValues(alpha: 0.25),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          StaggeredEntrance(
            index: 1,
            child: SurfaceCard(
              child: Row(
                children: [
                  Flexible(
                    child: StatusPill(
                      label: 'Active Session',
                      color: AppColors.success,
                      pulse: true,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.timer_outlined,
                      size: 15, color: AppColors.textFaint),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      _formatElapsed(elapsed),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label(
                        13,
                        w: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          StaggeredEntrance(
            index: 2,
            child: SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Desk allocation'),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('A-12',
                          style: AppText.display(30,
                              w: FontWeight.w800,
                              ls: -0.8,
                              color: AppColors.primary)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            'Floor ${booking.seat.floor}, Quiet Wing',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(
                              13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  InfoRow(
                    label: 'Check-in time',
                    value: DateFormat('h:mm a').format(_checkedInAt),
                  ),
                  const Divider(height: 1),
                  InfoRow(label: 'Duration window', value: window),
                  const Divider(height: 1),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Token ID',
                          style: AppText.body(
                            13.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        AppScope.of(context).activeProfile.studentId,
                        style: AppText.title(
                          14,
                          w: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.copy_rounded,
                            size: 15, color: AppColors.primary),
                        onPressed: () {
                          AppFeedback.tap();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Token ID copied'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const StaggeredEntrance(
            index: 3,
            child: Row(
              children: [
                Expanded(
                  child: _EntitlementTile(
                    icon: Icons.power_rounded,
                    value: 'Port 12 DN',
                    label: 'BGN 1000-C',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _EntitlementTile(
                    icon: Icons.wifi_rounded,
                    value: 'Wi-Fi Security',
                    label: 'Priority Band',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _EntitlementTile(
                    icon: Icons.volume_down_rounded,
                    value: 'Seat Zone Z2',
                    label: '≤ 25 dB',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'Back to Home',
            trailingIcon: Icons.arrow_forward_rounded,
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: _extendedMinutes > 0
                ? 'Extended $_extendedMinutes min'
                : 'Extend Time (+30 min)',
            icon: Icons.add_alarm_rounded,
            tone: ButtonTone.secondary,
            onPressed: () => setState(() => _extendedMinutes += 30),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'End session',
            icon: Icons.task_alt_rounded,
            tone: ButtonTone.secondary,
            onPressed: () async {
              // M01: ending a session confirms with the consequence first.
              final confirmed = await showConfirmDialog(
                context,
                title: 'End your session now?',
                body:
                    'Seat ${booking.seat.label} will be released and the next person waiting may be offered it.',
                confirmLabel: 'End session',
                cancelLabel: 'Keep session',
              );
              if (confirmed && context.mounted) {
                AppScope.read(context).cancelSeatBooking(booking.id);
                if (context.mounted) {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h h $m m $s s';
  }
}

class _EntitlementTile extends StatelessWidget {
  const _EntitlementTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.base - 2, horizontal: AppSpacing.md - 2),
      tint: AppColors.cyan.withValues(alpha: 0.24),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppText.title(12, w: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.body(10.5, color: AppColors.textFaint),
          ),
        ],
      ),
    );
  }
}
