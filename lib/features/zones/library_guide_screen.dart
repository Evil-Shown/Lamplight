import 'package:flutter/material.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/theme/app_theme.dart';

/// Library Facilities & Code of Conduct Guide screen inspired by `zone_quiet_lounge.jpg`
/// featuring "The Knowledge Line" and quiet etiquette.
class LibraryGuideScreen extends StatelessWidget {
  const LibraryGuideScreen({super.key});

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
        title: Text(
          'Library Facilities & Etiquette',
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
          // Banner featuring Knowledge Lounge
          Container(
            constraints: const BoxConstraints(minHeight: 140),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.card),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.card),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/zone_quiet_lounge.jpg',
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.3),
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.surfaceMuted,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1E293B)
                                .withValues(alpha: 0.9),
                            Colors.transparent,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          stops: const [0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'THE KNOWLEDGE LINE',
                          style: AppText.overline(10.5, ls: 1.2, color: const Color(0xFFFFAA2A)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Quiet Zones & Guidelines',
                          style: AppText.title(18, w: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Preserving harmony for every student',
                          style: AppText.body(11.5, color: const Color(0xFFFFE0B2)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            'SOUND & NOISE CODE',
            style: AppText.overline(11, ls: 1.0, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),

          _noiseTile(
            color: const Color(0xFF4CAF50),
            title: 'Green Zone · Collaboration (Floor 1)',
            subtitle: 'Group discussions and project conversations welcome. Design Studio and Startup Hub.',
          ),
          const SizedBox(height: 10),
          _noiseTile(
            color: const Color(0xFFFFAA2A),
            title: 'Amber Zone · Whispering (Floor 2)',
            subtitle: 'Soft whispers only. Phone calls strictly prohibited. Glass Pods & Desk rows.',
          ),
          const SizedBox(height: 10),
          _noiseTile(
            color: const Color(0xFFE53935),
            title: 'Red Zone · Absolute Silence (Floor 3)',
            subtitle: 'Zero noise. Headphones required at all times. Knowledge Lounge & Quiet Stacks.',
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            'CAMPUS FACILITIES',
            style: AppText.overline(11, ls: 1.0, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),

          _facilityTile(
            icon: Icons.print_rounded,
            title: 'High-Speed Printing & Scanning',
            subtitle: 'Kiosks located at Floor 1 & 2 Atrium stairs. Use your student RFID pass.',
          ),
          const SizedBox(height: 10),
          _facilityTile(
            icon: Icons.local_cafe_rounded,
            title: 'Hydration & Café Lounge',
            subtitle: 'Filtered water dispensers on every floor. Covered drinks only permitted at desks.',
          ),
          const SizedBox(height: 10),
          _facilityTile(
            icon: Icons.security_rounded,
            title: '24/7 Campus Security & Lost Items',
            subtitle: 'Main desk assistance available round the clock. Escort service past midnight.',
          ),
        ],
      ),
    );
  }

  Widget _noiseTile({required Color color, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.title(14, w: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.body(12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _facilityTile({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.title(14, w: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.body(12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

