import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ledger_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/mock/mock_data.dart';
import '../../features/qr/qr_scan_screen.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookings = MockData.activeBookings;
    final timeFmt = DateFormat('h:mm a');

    return Scaffold(
      appBar: AppBar(title: Text('My seat bookings', style: AppText.serif(22))),
      body: bookings.isEmpty
          ? const EmptyState(
              icon: Icons.event_seat_outlined,
              title: 'No active bookings',
              message: 'Browse the reading room and book a seat.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final b = bookings[index];
                final grace = b.gracePeriodEndsAt;

                return TicketCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const IconBadge(
                            icon: Icons.event_seat_rounded,
                            color: AppColors.inkSoft,
                            size: 48,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Seat ${b.seat.label}',
                                    style: AppText.serif(17, ls: -0.2)),
                                Text(
                                  'Floor ${b.seat.floor} · ${b.seat.section}',
                                  style: AppText.sans(12.5,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const StatusChip(
                            label: 'Active',
                            color: AppColors.stampGreen,
                            pulse: true,
                            compact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      InfoRow(
                        icon: Icons.schedule_rounded,
                        label: 'Session',
                        value:
                            '${timeFmt.format(b.startTime)} – ${timeFmt.format(b.endTime)}',
                      ),
                      if (grace != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _GraceCountdown(deadline: grace),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QrScanScreen(
                                mode: QrScanMode.seatCheckIn,
                                referenceCode: b.qrCode,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          label: const Text('Check in with QR'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

/// Live-ticking grace-period banner. Safe with a periodic timer because this
/// screen is only reachable via navigation — the root tab shell never mounts it.
class _GraceCountdown extends StatefulWidget {
  const _GraceCountdown({required this.deadline});

  final DateTime deadline;

  @override
  State<_GraceCountdown> createState() => _GraceCountdownState();
}

class _GraceCountdownState extends State<_GraceCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
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
    final diff = widget.deadline.difference(DateTime.now());
    final minutes = diff.isNegative ? 0 : diff.inMinutes;
    final seconds = diff.isNegative ? 0 : diff.inSeconds % 60;
    return AlertBanner(
      tone: AlertTone.warning,
      icon: Icons.timer_outlined,
      message:
          'Check in within $minutes:${seconds.toString().padLeft(2, '0')} or '
          'this seat will be released.',
    );
  }
}
