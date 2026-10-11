import 'package:flutter/material.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/navigation/app_route.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../seats/seat_map_screen.dart';
import 'pod_booking_screen.dart';

/// Interactive Study Spaces & Zone Explorer showcasing the real library areas:
/// - Design & Project Studio
/// - Startup & Innovation Lab
/// - Glass Study Pods (01 - 05)
/// - Knowledge Lounge & Quiet Zone
class StudyZonesScreen extends StatefulWidget {
  const StudyZonesScreen({super.key});

  @override
  State<StudyZonesScreen> createState() => _StudyZonesScreenState();
}

class _StudyZonesScreenState extends State<StudyZonesScreen> {
  String _selectedVibe = 'All';

  final List<_ZoneInfo> _zones = const [
    _ZoneInfo(
      id: 'glass-pods',
      title: 'Glass Study Pods (01 - 05)',
      subtitle: 'Private tinted sound-isolated focus rooms',
      category: 'Deep Focus',
      floor: 'Floor 2 · West Wing',
      imageAsset: 'assets/images/zone_glass_pods.png',
      capacity: '1 - 2 Persons / Pod',
      noiseLevel: 'Silent (< 25 dB)',
      rating: '9.9 Focus Score',
      amenities: ['Power Sockets', 'Acoustic Tinted Glass', 'Air Conditioning', 'LED Task Light'],
      color: Color(0xFFD3A376),
    ),
    _ZoneInfo(
      id: 'design-studio',
      title: 'Design & Project Studio',
      subtitle: 'Creative workspace for group brainstorming',
      category: 'Collaboration',
      floor: 'Floor 1 · Creative Atrium',
      imageAsset: 'assets/images/zone_design_project.jpg',
      capacity: '4 - 8 Persons / Table',
      noiseLevel: 'Discussion Allowed',
      rating: '9.7 Team Score',
      amenities: ['Wall Idea Boards', 'Hanging Lights', 'Wide Oak Tables', 'Charging Strip'],
      color: Color(0xFFE56A2B),
    ),
    _ZoneInfo(
      id: 'startup-lab',
      title: 'Startup & Innovation Lab',
      subtitle: 'Agile team tables with idea wall graphics',
      category: 'Workshops',
      floor: 'Floor 1 · Innovation Hub',
      imageAsset: 'assets/images/zone_startup_hub.png',
      capacity: '6 - 10 Persons',
      noiseLevel: 'Active Collaboration',
      rating: '9.8 Energy Score',
      amenities: ['Idea Process Wall', 'U-Couch Seating', 'Dual Monitors', 'Ethernet Ports'],
      color: Color(0xFF0D7EE8),
    ),
    _ZoneInfo(
      id: 'quiet-lounge',
      title: 'The Knowledge Line & Quiet Zone',
      subtitle: 'Hexagonal desks & yellow organic couches',
      category: 'Quiet Study',
      floor: 'Floor 3 · Panorama Deck',
      imageAsset: 'assets/images/zone_quiet_lounge.jpg',
      capacity: '1 - 4 Persons',
      noiseLevel: 'Whisper Only',
      rating: '10.0 Serene Deal',
      amenities: ['Kiosk Stand Access', 'Hexagonal Geometry Desks', 'Curved Sofas', 'Panoramic Lighting'],
      color: Color(0xFFD4A017),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    final filtered = _selectedVibe == 'All'
        ? _zones
        : _zones.where((z) => z.category == _selectedVibe).toList();

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
          'Campus Study Spaces',
          style: AppText.display(20, w: FontWeight.w700),
        ),
        centerTitle: false,
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
            'Explore real university study zones, private pods, and creative lounges.',
            style: AppText.body(13.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),

          // Vibe Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final vibe in ['All', 'Deep Focus', 'Collaboration', 'Workshops', 'Quiet Study']) ...[
                  PressScale(
                    onTap: () {
                      AppFeedback.tap();
                      setState(() => _selectedVibe = vibe);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedVibe == vibe
                            ? AppColors.primary
                            : (isDark ? const Color(0xFF111827) : Colors.white),
                        borderRadius: BorderRadius.circular(AppRadii.full),
                        border: Border.all(
                          color: _selectedVibe == vibe
                              ? Colors.transparent
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        vibe,
                        style: AppText.label(
                          12,
                          w: FontWeight.w700,
                          color: _selectedVibe == vibe ? (isDark ? const Color(0xFF0F172A) : Colors.white) : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          for (final zone in filtered) ...[
            _ZoneCard(zone: zone),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _ZoneInfo {
  const _ZoneInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.floor,
    required this.imageAsset,
    required this.capacity,
    required this.noiseLevel,
    required this.rating,
    required this.amenities,
    required this.color,
  });

  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String floor;
  final String imageAsset;
  final String capacity;
  final String noiseLevel;
  final String rating;
  final List<String> amenities;
  final Color color;
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({required this.zone});

  final _ZoneInfo zone;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo Header
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
            child: Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Image.asset(
                    zone.imageAsset,
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
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(color: zone.color),
                    ),
                    child: Text(
                      zone.category.toUpperCase(),
                      style: AppText.overline(
                        10.5,
                        ls: 1.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Text(
                      zone.rating,
                      style: AppText.label(
                        11,
                        w: FontWeight.w700,
                        color: const Color(0xFFFFE0B2),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Text(
                    zone.title,
                    style: AppText.title(18, w: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Details Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zone.subtitle,
                  style: AppText.body(13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFFD3A376)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        zone.floor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label(12, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.people_alt_outlined, size: 16, color: Color(0xFFD3A376)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        zone.capacity,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label(12, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.volume_down_outlined, size: 16, color: Color(0xFFD3A376)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        zone.noiseLevel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label(12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Amenities
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final a in zone.amenities)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          a,
                          style: AppText.label(10.5, color: AppColors.textSecondary),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: zone.id == 'glass-pods' ? 'Book a Pod' : 'View Seats & Desks',
                        icon: zone.id == 'glass-pods' ? Icons.meeting_room_rounded : Icons.event_seat_rounded,
                        onPressed: () {
                          AppFeedback.tap();
                          if (zone.id == 'glass-pods') {
                            AppRoute.push(context, const PodBookingScreen());
                          } else {
                            AppRoute.push(context, const SeatMapScreen());
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

