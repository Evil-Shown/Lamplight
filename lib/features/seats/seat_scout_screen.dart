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
      color: Color(0xFF163832),
    ),
    _ScoutSeat(
      section: 'Section 05 · East Stacks',
      rowSeat: 'Desk D-14 · Outlet',
      score: '9.7',
      scoreLabel: 'Power Deal',
      category: 'Deep Silence',
      floor: 2,
      isAvailable: true,
      color: Color(0xFF235347),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF051F20) : const Color(0xFFF5F0E8),
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
              color: isDark ? const Color(0xFF0B2B26) : Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.full),
              border: Border.all(color: const Color(0xFF8EB69B)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF163832)),
                const SizedBox(width: 4),
                Text(
                  '3 FLOORS',
                  style: AppText.overline(10, color: const Color(0xFF163832)),
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
                    colors: [Color(0xFFE56A2B), Color(0xFFD99246)],
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
                  color: isDark ? const Color(0xFF0B2B26) : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(
                    color: isDark ? const Color(0xFF163832) : const Color(0xFFD8C9B6),
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
                        color: const Color(0xFF163832),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8EB69B).withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.park_rounded, color: Color(0xFFDAF1DE), size: 20),
                          const SizedBox(height: 2),
                          Text(
                            'ATRIUM',
                            style: AppText.overline(8.5, color: const Color(0xFFDAF1DE)),
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
                        color: isDark ? const Color(0xFF0B2B26) : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF163832)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedSort,
                            style: AppText.label(12, w: FontWeight.w700, color: const Color(0xFF163832)),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down_rounded, size: 18, color: Color(0xFF163832)),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0B2B26) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? const Color(0xFF163832) : const Color(0xFFD8C9B6),
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
                    colors: [Color(0xFFE56A2B), Color(0xFFD99246)],
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
              ? (isDark ? const Color(0xFF163832) : const Color(0xFFE4F0E8))
              : (isDark ? const Color(0xFF0B2B26) : Colors.white),
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8EB69B)
                : (isDark ? const Color(0xFF163832) : const Color(0xFFD8C9B6).withValues(alpha: 0.7)),
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
                color: isSelected ? const Color(0xFF163832) : const Color(0xFF0D7EE8),
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

class _RadialCampusMapPainter extends CustomPainter {
  _RadialCampusMapPainter({required this.isDark, required this.selectedIndex});

  final bool isDark;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final trackPaint = Paint()
      ..color = (isDark ? Colors.white12 : Colors.black12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, 90, trackPaint);
    canvas.drawCircle(center, 65, trackPaint);

    final nodePaint = Paint()..style = PaintingStyle.fill;

    // Outer ring nodes (Seats)
    for (var i = 0; i < 16; i++) {
      final angle = (i * 22.5) * 3.14159 / 180;
      final x = center.dx + 90 * (3.14159 * 0 + (i.isEven ? 1 : 1)) * 0 + 90 * (i == 0 ? 1 : (i == 4 ? 0 : -1));
      final offset = Offset(center.dx + 90 * (angle < 3.14 ? 1 : -1) * 0.7, center.dy + 90 * 0.7);

      final isAvailable = i % 3 != 0;
      nodePaint.color = isAvailable ? const Color(0xFF4CAF50) : const Color(0xFFE53935);
      canvas.drawCircle(Offset(center.dx + 90 * (angle - 1.57).abs() / 3, center.dy + 90 * (i % 2 == 0 ? 0.8 : -0.8)), 5, nodePaint);
    }
  }

  @override
  bool shouldRepaint(_RadialCampusMapPainter oldDelegate) => false;
}
