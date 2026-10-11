import 'package:flutter/material.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';

/// Group Collaboration Room Reservation screen representing:
/// - Design & Project Studio (`zone_design_project.jpg`)
/// - Startup & Innovation Hub (`zone_startup_hub.png`)
class GroupRoomBookingScreen extends StatefulWidget {
  const GroupRoomBookingScreen({super.key});

  @override
  State<GroupRoomBookingScreen> createState() => _GroupRoomBookingScreenState();
}

class _GroupRoomBookingScreenState extends State<GroupRoomBookingScreen> {
  int _selectedRoom = 0;
  int _teamSize = 4;
  final _idController = TextEditingController();
  final List<String> _members = ['ST-9482 (Host)'];
  bool _booked = false;

  final List<({String title, String floor, String imageAsset, String capacity})> _rooms = const [
    (title: 'Design Studio 1A', floor: 'Floor 1 · Creative Atrium', imageAsset: 'assets/images/zone_design_project.jpg', capacity: 'Up to 8 members'),
    (title: 'Startup Hub Room B', floor: 'Floor 1 · Innovation Lab', imageAsset: 'assets/images/zone_startup_hub.png', capacity: 'Up to 10 members'),
    (title: 'Knowledge Circle 3', floor: 'Floor 3 · Quiet Panorama', imageAsset: 'assets/images/zone_quiet_lounge.jpg', capacity: 'Up to 6 members'),
  ];

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  void _addMember() {
    final text = _idController.text.trim();
    if (text.isEmpty) return;
    AppFeedback.tap();
    setState(() {
      _members.add(text.toUpperCase());
      _idController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    final active = _rooms[_selectedRoom];

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
        title: Text(
          'Group Room Booking',
          style: AppText.display(19, w: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          0,
          AppSpacing.screenMargin,
          AppSpacing.scrollBottomInset,
        ),
        children: [
          Text(
            'Reserve team tables in the Design & Startup studios for project work.',
            style: AppText.body(13.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),

          // Room Selector Carousel
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _rooms.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final r = _rooms[i];
                final isSelected = _selectedRoom == i;
                return PressScale(
                  onTap: () {
                    AppFeedback.tap();
                    setState(() {
                      _selectedRoom = i;
                      _booked = false;
                    });
                  },
                  child: Container(
                    width: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFE56A2B) : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              r.imageAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppColors.surfaceMuted,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.15),
                                    Colors.black.withValues(alpha: 0.8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  r.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.title(15, w: FontWeight.w700, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  r.capacity,
                                  style: AppText.body(11, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Team Size Stepper ([- 04 +])
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Team Members Attending',
                        style: AppText.title(14.5, w: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Minimum 2 required for studio reservation',
                        style: AppText.body(11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      onPressed: _teamSize > 2
                          ? () {
                              AppFeedback.tap();
                              setState(() => _teamSize--);
                            }
                          : null,
                    ),
                    Text(
                      '$_teamSize',
                      style: AppText.title(16, w: FontWeight.w800),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      onPressed: _teamSize < 8
                          ? () {
                              AppFeedback.tap();
                              setState(() => _teamSize++);
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Member Student ID inputs
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Teammates by Student ID',
                  style: AppText.title(14.5, w: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _idController,
                        decoration: InputDecoration(
                           hintText: 'e.g. IT-20491',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 90,
                      child: PrimaryButton(
                        label: 'Add',
                        onPressed: _addMember,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final m in _members)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          m,
                          style: AppText.label(11, w: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          if (!_booked) ...[
            PrimaryButton(
              label: 'Confirm Studio Reservation',
              icon: Icons.check_circle_outline_rounded,
              onPressed: () {
                AppFeedback.success();
                setState(() => _booked = true);
              },
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF7EE0C3), size: 36),
                  const SizedBox(height: 8),
                  Text(
                    '${active.title} Confirmed!',
                    style: AppText.title(18, w: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A notification has been sent to ${_members.length} team members.',
                    textAlign: TextAlign.center,
                    style: AppText.body(12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

