import 'package:flutter/material.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';

/// Evening Lamplight Sanctuary screen inspired by Image 5 (Pagoda & vertical glowing lantern pillars).
///
/// Features community lantern lighting, extended evening hours, night owl
/// focus streaks, and silent library atmosphere.
class NightSanctuaryScreen extends StatefulWidget {
  const NightSanctuaryScreen({super.key});

  @override
  State<NightSanctuaryScreen> createState() => _NightSanctuaryScreenState();
}

class _NightSanctuaryScreenState extends State<NightSanctuaryScreen> {
  int _activeLanterns = 42;
  bool _hasLitLantern = false;

  void _lightLantern() {
    if (_hasLitLantern) return;
    AppFeedback.success();
    setState(() {
      _hasLitLantern = true;
      _activeLanterns++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071116),
      body: CustomScrollView(
        slivers: [
          // Scenic Night Lake & Lanterns Hero
          SliverToBoxAdapter(
            child: _NightLanternsHero(
              activeLanterns: _activeLanterns,
              hasLitLantern: _hasLitLantern,
              onLightLantern: _lightLantern,
              onBack: () => Navigator.pop(context),
            ),
          ),

          // Community Presence Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin,
                vertical: AppSpacing.md,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1E24),
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(
                    color: const Color(0xFFD99246).withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD99246).withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD99246).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.light_mode_rounded,
                        color: Color(0xFFFFAA2A),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_activeLanterns Reading in Silence',
                            style: AppText.title(
                              15,
                              w: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Night owls studying across 3 sanctuary floors',
                            style: AppText.body(
                              12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Extended Night Hours Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin,
              ),
              child: _NightScheduleCard(),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.md),
          ),

          // Night Owl Badges
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin,
              ),
              child: _NightAchievements(),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.scrollBottomInset),
          ),
        ],
      ),
    );
  }
}

class _NightLanternsHero extends StatelessWidget {
  const _NightLanternsHero({
    required this.activeLanterns,
    required this.hasLitLantern,
    required this.onLightLantern,
    required this.onBack,
  });

  final int activeLanterns;
  final bool hasLitLantern;
  final VoidCallback onLightLantern;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Art image container
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(36),
          ),
          child: SizedBox(
            height: 380,
            width: double.infinity,
            child: Image.asset(
              'assets/images/night_lanterns.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF071116), Color(0xFF162E35)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Gradient overlay
        Positioned.fill(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(36),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    const Color(0xFF071116).withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.4, 0.95],
                ),
              ),
            ),
          ),
        ),

        // Content overlay
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenMargin,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PressScale(
                      onTap: () {
                        AppFeedback.tap();
                        onBack();
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFD99246).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(AppRadii.full),
                            border: Border.all(
                              color: const Color(0xFFFFAA2A)
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.nights_stay_rounded,
                                size: 14,
                                color: Color(0xFFFFAA2A),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'NIGHT SANCTUARY',
                                style: AppText.overline(
                                  11,
                                  ls: 1.2,
                                  color: const Color(0xFFFFAA2A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 120),
                Text(
                  'Lamplight by Night',
                  style: AppText.display(
                    30,
                    w: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Peaceful evening hours • Open until 02:00 AM',
                  style: AppText.body(
                    14,
                    color: const Color(0xFFDAF1DE).withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 20),
                PressScale(
                  onTap: onLightLantern,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: hasLitLantern
                              ? [const Color(0xFF163832), const Color(0xFF235347)]
                              : [const Color(0xFFD99246), const Color(0xFFFFAA2A)],
                        ),
                        borderRadius: BorderRadius.circular(AppRadii.full),
                        boxShadow: [
                          BoxShadow(
                            color: (hasLitLantern
                                    ? const Color(0xFF8EB69B)
                                    : const Color(0xFFFFAA2A))
                                .withValues(alpha: 0.4),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasLitLantern
                                ? Icons.check_circle_rounded
                                : Icons.local_fire_department_rounded,
                            color: hasLitLantern
                                ? const Color(0xFFDAF1DE)
                                : const Color(0xFF071116),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hasLitLantern
                                ? 'Your Lantern is Burning'
                                : 'Light My Study Lantern',
                            style: AppText.label(
                              13.5,
                              w: FontWeight.w800,
                              color: hasLitLantern
                                  ? const Color(0xFFDAF1DE)
                                  : const Color(0xFF071116),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NightScheduleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E24),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.access_time_filled_rounded,
                size: 18,
                color: Color(0xFF8EB69B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'EVENING SCHEDULE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.overline(
                    11.5,
                    ls: 1.0,
                    color: const Color(0xFF8EB69B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _scheduleRow('20:00 - 22:00', 'Whisper Floor Active', 'Soft discussion permitted in East Wing'),
          const Divider(color: Colors.white12, height: 20),
          _scheduleRow('22:00 - 02:00', 'Absolute Silence', 'All floors transition to deep focus'),
          const Divider(color: Colors.white12, height: 20),
          _scheduleRow('01:30', 'Safe Escort Service', 'Campus security escort available at Main Desk'),
        ],
      ),
    );
  }

  Widget _scheduleRow(String time, String title, String sub) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF163832),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            time,
            style: AppText.label(
              11,
              w: FontWeight.w700,
              color: const Color(0xFFDAF1DE),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.title(13.5, w: FontWeight.w700, color: Colors.white),
              ),
              Text(
                sub,
                style: AppText.body(11.5, color: Colors.white60),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NightAchievements extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E24),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.military_tech_rounded,
                size: 18,
                color: Color(0xFFFFAA2A),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'LANTERN BADGES & STREAKS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.overline(
                    11.5,
                    ls: 1.0,
                    color: const Color(0xFFFFAA2A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _badgeItem(Icons.auto_stories_rounded, 'Midnight Scholar', '5 late night sessions', true),
              const SizedBox(width: 12),
              _badgeItem(Icons.shield_moon_rounded, 'Lantern Keeper', 'Focus past 00:00', true),
              const SizedBox(width: 12),
              _badgeItem(Icons.star_half_rounded, 'Dawn Sentinel', 'Study until 02:00', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badgeItem(IconData icon, String title, String sub, bool unlocked) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: unlocked
              ? const Color(0xFF163832).withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: unlocked
                ? const Color(0xFF8EB69B).withValues(alpha: 0.4)
                : Colors.white10,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: unlocked ? const Color(0xFFFFAA2A) : Colors.white30,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label(
                11,
                w: FontWeight.w700,
                color: unlocked ? Colors.white : Colors.white38,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                9.5,
                color: unlocked ? Colors.white70 : Colors.white24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
