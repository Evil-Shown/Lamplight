import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/navigation/app_route.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/shared_widgets.dart';
import '../zones/pod_booking_screen.dart';

/// Interactive Radial Floor & Seat Scout screen directly inspired by Image 1:
/// Circular map with color-coded nodes, Focus/Deal score ranking,
/// filter pills, and a floating VIP fast-track booking pill.
class SeatScoutScreen extends StatefulWidget {
  const SeatScoutScreen({super.key});

  @override
  State<SeatScoutScreen> createState() => _SeatScoutScreenState();
}

class _SeatScoutScreenState extends State<SeatScoutScreen> {
  String _selectedSort = 'Focus Score';
  int? _selectedSeatIndex;

  final List<_ScoutSeat> _seats = const [
    _ScoutSeat(
      section: 'Section 01 · Glass Pods',
      rowSeat: 'Pod 02 · Desk A',
      score: '10.0',
      scoreLabel: 'Serene Deal',
      category: 'Quiet Isolated',
      floor: 2,
      isAvailable: true,
      color: Color(0xFF0D7EE8),
    ),
    _ScoutSeat(
      section: 'Section 02 · Design Studio',
      rowSeat: 'Table 4 · Chair 2',
      score: '9.9',
      scoreLabel: 'Team Deal',
      category: 'Active Creative',
      floor: 1,
      isAvailable: true,
      color: Color(0xFFE56A2B),
    ),
    _ScoutSeat(
      section: 'Section 03 · Knowledge Line',
      rowSeat: 'Hex Desk 08 · Window',
      score: '9.9',
      scoreLabel: 'Sunlit Deal',
      category: 'Natural Light',
      floor: 3,
      isAvailable: true,
      color: Color(0xFFD4A017),
    ),
    _ScoutSeat(
      section: 'Section 04 · Startup Lab',
      rowSeat: 'U-Couch Seat 3',
      score: '9.8',
      scoreLabel: 'Project Deal',
      category: 'Tech Workshop',
      floor: 1,
      isAvailable: true,
      color: Color(0xFF6366F1),
    ),
    _ScoutSeat(
      section: 'Section 05 · East Stacks',
      rowSeat: 'Desk D-14 · Outlet',
      score: '9.7',
      scoreLabel: 'Power Deal',
      category: 'Deep Silence',
      floor: 2,
      isAvailable: true,
      color: Color(0xFF10B981),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          color: AppColors.textPrimary,
          onPressed: () {
            AppFeedback.tap();
            Navigator.of(context).maybePop();
          },
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Library Floor Scout',
                style: AppText.display(18, w: FontWeight.w700),
              ),
              Text(
                'Live Occupancy & Focus Deals',
                style: AppText.body(11.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F1714) : Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.full),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  '3 FLOORS',
                  style: AppText.overline(10, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenMargin,
              0,
              AppSpacing.screenMargin,
              100, // Room for floating banner
            ),
            children: [
              // Top Notification Banner inspired by "CA residents only" pill in Image 1
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE56A2B), Color(0xFFD3A376)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Verified Student & Faculty Pass Only',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label(12, w: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              // Radial Campus Map (Inspired by circular stadium map in Image 1)
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F1714) : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring of seats
                    CustomPaint(
                      size: const Size(220, 220),
                      painter: _RadialCampusMapPainter(
                        isDark: isDark,
                        selectedIndex: _selectedSeatIndex,
                      ),
                    ),
                    // Center Atrium Garden
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF140F0D) : const Color(0xFF1E293B),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD3A376).withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.park_rounded, color: Color(0xFFFFE0B2), size: 20),
                          const SizedBox(height: 2),
                          Text(
                            'ATRIUM',
                            style: AppText.overline(8.5, color: const Color(0xFFFFE0B2)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Filter & Sort Bar (Sort by Deal Score, Any, Filter Icon)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Sort by',
                    style: AppText.body(13, color: AppColors.textSecondary),
                  ),
                  PressScale(
                    onTap: () {
                      AppFeedback.tap();
                      setState(() {
                        _selectedSort = _selectedSort == 'Focus Score' ? 'Quietness' : 'Focus Score';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F1714) : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedSort,
                            style: AppText.label(12, w: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.textPrimary),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F1714) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.confirmation_number_outlined, size: 14, color: Color(0xFF0D7EE8)),
                        const SizedBox(width: 4),
                        Text('Any Zone', style: AppText.label(12, color: const Color(0xFF0D7EE8))),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Seat Cards List (Directly styled like the stadium deals in Image 1)
              for (var i = 0; i < _seats.length; i++) ...[
                _ScoutSeatTile(
                  seat: _seats[i],
                  isSelected: _selectedSeatIndex == i,
                  onTap: () {
                    AppFeedback.tap();
                    setState(() => _selectedSeatIndex = i);
                    _showSeatDetailModal(context, _seats[i]);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),

          // Floating Action Pill (Inspired by "VIP Packages Available" in Image 1)
          Positioned(
            left: AppSpacing.screenMargin,
            right: AppSpacing.screenMargin,
            bottom: 24,
            child: PressScale(
              onTap: () {
                AppFeedback.success();
                AppRoute.push(context, const PodBookingScreen());
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE56A2B), Color(0xFFD3A376)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE56A2B).withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Private Glass Pods Available (Pods 01 - 05)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label(13.5, w: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSeatDetailModal(BuildContext context, _ScoutSeat seat) {
    AppFeedback.select();
    final isDark = AppColors.isDark;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F1714) : Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.lg + 4),
            ),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: seat.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(color: seat.color.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      seat.section,
                      style: AppText.label(11.5, w: FontWeight.w700, color: seat.color),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D7EE8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '★ ${seat.score} ${seat.scoreLabel}',
                      style: AppText.label(11, w: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                seat.rowSeat,
                style: AppText.display(20, w: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Floor ${seat.floor} · ${seat.category}',
                style: AppText.body(13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ModalPill(icon: Icons.power_rounded, label: 'Dual AC Sockets'),
                  _ModalPill(icon: Icons.wifi_rounded, label: 'Wi-Fi 6E (480 Mbps)'),
                  _ModalPill(icon: Icons.volume_mute_rounded, label: '<25 dB Quiet'),
                  _ModalPill(icon: Icons.wb_sunny_rounded, label: 'Natural Daylight'),
                ],
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Reserve This Desk Now',
                icon: Icons.check_circle_outline_rounded,
                onPressed: () {
                  AppFeedback.success();
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reserved ${seat.rowSeat} on Floor ${seat.floor}!'),
                      backgroundColor: isDark ? const Color(0xFF140F0D) : const Color(0xFF1E293B),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScoutSeat {
  const _ScoutSeat({
    required this.section,
    required this.rowSeat,
    required this.score,
    required this.scoreLabel,
    required this.category,
    required this.floor,
    required this.isAvailable,
    required this.color,
  });

  final String section;
  final String rowSeat;
  final String score;
  final String scoreLabel;
  final String category;
  final int floor;
  final bool isAvailable;
  final Color color;
}

class _ScoutSeatTile extends StatelessWidget {
  const _ScoutSeatTile({
    required this.seat,
    required this.isSelected,
    required this.onTap,
  });

  final _ScoutSeat seat;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;

    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF4A2810) : const Color(0xFFFEF3C7))
              : (isDark ? const Color(0xFF1F1714) : Colors.white),
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.border,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            // Score Badge (Inspired by blue pricing bubble in Image 1)
            Container(
              width: 58,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : const Color(0xFF0D7EE8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '★ ${seat.score}',
                style: AppText.label(13, w: FontWeight.w800, color: Colors.white),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    seat.section,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title(14.5, w: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          seat.scoreLabel,
                          style: AppText.label(10.5, w: FontWeight.w700, color: const Color(0xFF2E7D32)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          seat.rowSeat,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _ModalPill extends StatelessWidget {
  const _ModalPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF241B17)
            : AppColors.scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label(11.5, w: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadialCampusMapPainter extends CustomPainter {
  _RadialCampusMapPainter({required this.isDark, required this.selectedIndex});

  final bool isDark;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Track paints
    final trackPaint = Paint()
      ..color = (isDark
          ? Colors.white.withValues(alpha: 0.12)
          : const Color(0xFFCBD5E1))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw concentric radar tracks
    canvas.drawCircle(center, 94, trackPaint);
    canvas.drawCircle(center, 70, trackPaint);
    canvas.drawCircle(center, 46, trackPaint);

    // Colored Sector Arcs
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final sectorColors = [
      const Color(0xFF0D7EE8), // Sector 01: Glass Pods (Cyan)
      const Color(0xFFE56A2B), // Sector 02: Design Studio (Tangerine)
      const Color(0xFFD4A017), // Sector 03: Knowledge Line (Gold)
      const Color(0xFF10B981), // Sector 04: Startup Lab (Emerald)
    ];

    const double arcGap = 0.18; // gap between sector arcs in radians
    const double sectorSpan = (2 * math.pi / 4) - arcGap;

    for (var s = 0; s < 4; s++) {
      arcPaint.color = sectorColors[s].withValues(alpha: 0.85);
      final startAngle = -math.pi / 2 + (s * (math.pi / 2)) + (arcGap / 2);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 94),
        startAngle,
        sectorSpan,
        false,
        arcPaint,
      );
    }

    // Radial spokes
    final spokePaint = Paint()
      ..color = (isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var s = 0; s < 4; s++) {
      final angle = -math.pi / 2 + (s * (math.pi / 2));
      final p1 = Offset(center.dx + 48 * math.cos(angle), center.dy + 48 * math.sin(angle));
      final p2 = Offset(center.dx + 98 * math.cos(angle), center.dy + 98 * math.sin(angle));
      canvas.drawLine(p1, p2, spokePaint);
    }

    // Outer & inner seat nodes
    final nodeFillPaint = Paint()..style = PaintingStyle.fill;
    final nodeStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    // 16 outer seats
    const totalOuterSeats = 16;
    for (var i = 0; i < totalOuterSeats; i++) {
      final angle = -math.pi / 2 + (i * (2 * math.pi / totalOuterSeats));
      final pos = Offset(center.dx + 82 * math.cos(angle), center.dy + 82 * math.sin(angle));
      final sector = (i / (totalOuterSeats / 4)).floor().clamp(0, 3);
      final isSeatAvailable = i % 3 != 0;
      final isSelected = selectedIndex != null && selectedIndex == sector;

      if (isSelected && i % 4 == 0) {
        // Halo for selected seat
        final haloPaint = Paint()
          ..color = sectorColors[sector].withValues(alpha: 0.35)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, 11, haloPaint);

        nodeStrokePaint.color = Colors.white;
        canvas.drawCircle(pos, 7, nodeStrokePaint);

        nodeFillPaint.color = sectorColors[sector];
        canvas.drawCircle(pos, 6, nodeFillPaint);
      } else {
        nodeFillPaint.color = isSeatAvailable
            ? sectorColors[sector].withValues(alpha: 0.9)
            : (isDark ? Colors.white24 : Colors.black26);
        canvas.drawCircle(pos, 4.5, nodeFillPaint);
      }
    }

    // 8 inner ring seats
    const totalInnerSeats = 8;
    for (var j = 0; j < totalInnerSeats; j++) {
      final angle = -math.pi / 4 + (j * (2 * math.pi / totalInnerSeats));
      final pos = Offset(center.dx + 58 * math.cos(angle), center.dy + 58 * math.sin(angle));
      final isSeatAvailable = j % 2 == 0;

      nodeFillPaint.color = isSeatAvailable
          ? const Color(0xFFD3A376)
          : (isDark ? Colors.white12 : Colors.black12);
      canvas.drawCircle(pos, 3.5, nodeFillPaint);
    }
  }

  @override
  bool shouldRepaint(_RadialCampusMapPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.selectedIndex != selectedIndex;
}
