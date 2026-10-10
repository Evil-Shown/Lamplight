import 'package:flutter/material.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';

/// Private Glass Study Pods (01 to 05) booking & smart key screen,
/// directly representing the university library photo `zone_glass_pods.png`.
class PodBookingScreen extends StatefulWidget {
  const PodBookingScreen({super.key});

  @override
  State<PodBookingScreen> createState() => _PodBookingScreenState();
}

class _PodBookingScreenState extends State<PodBookingScreen> {
  int _selectedPodIndex = 1; // Pod 02 by default
  int _durationMinutes = 60;
  bool _booked = false;

  final List<({String number, String tintName, Color tintColor, bool isAvailable, String features})> _pods = const [
    (number: '01', tintName: 'Warm Amber', tintColor: Color(0xFFD3A376), isAvailable: true, features: 'Dual 27" 4K Monitors · Standing desk'),
    (number: '02', tintName: 'Ocean Cyan', tintColor: Color(0xFF0D7EE8), isAvailable: true, features: 'Quiet Mic for Presentations · Ergonomic chair'),
    (number: '03', tintName: 'Forest Mint', tintColor: Color(0xFF10B981), isAvailable: false, features: 'Natural Skylight Angle · Dual sockets'),
    (number: '04', tintName: 'Deep Cobalt', tintColor: Color(0xFF1E3A8A), isAvailable: true, features: 'High-speed Ethernet · Ultra-quiet air filter'),
    (number: '05', tintName: 'Solar Gold', tintColor: Color(0xFFD3A376), isAvailable: true, features: 'Wall whiteboard · USB-C fast charging 65W'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    final activePod = _pods[_selectedPodIndex];

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
          'Private Glass Pods',
          style: AppText.display(20, w: FontWeight.w700),
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
          // Photo Hero Container
          Container(
            constraints: const BoxConstraints(minHeight: 160),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(
                color: AppColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 12,
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
                      'assets/images/zone_glass_pods.png',
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.2),
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
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 50),
                        Text(
                          'Acoustic Glass Pods 01 — 05',
                          style: AppText.title(18, w: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sound-isolated private cubicles for individual deep study',
                          style: AppText.body(12, color: Colors.white70),
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
            'SELECT A POD',
            style: AppText.overline(11.5, ls: 1.0, color: const Color(0xFFD3A376)),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Pods Horizontal Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < _pods.length; i++) ...[
                  PressScale(
                    onTap: () {
                      if (!_pods[i].isAvailable) return;
                      AppFeedback.tap();
                      setState(() {
                        _selectedPodIndex = i;
                        _booked = false;
                      });
                    },
                    child: Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _selectedPodIndex == i
                            ? _pods[i].tintColor.withValues(alpha: isDark ? 0.35 : 0.15)
                            : (isDark ? const Color(0xFF111827) : Colors.white),
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        border: Border.all(
                          color: _selectedPodIndex == i
                              ? _pods[i].tintColor
                              : AppColors.border,
                          width: _selectedPodIndex == i ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _pods[i].number,
                            style: AppText.display(
                              22,
                              w: FontWeight.w800,
                              color: _pods[i].isAvailable
                                  ? (_selectedPodIndex == i ? _pods[i].tintColor : AppColors.textPrimary)
                                  : AppColors.textFaint,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _pods[i].isAvailable ? 'Free' : 'In use',
                            style: AppText.label(
                              11,
                              w: FontWeight.w700,
                              color: _pods[i].isAvailable ? const Color(0xFF2E7D32) : AppColors.textFaint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Selected Pod Details Card
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
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: activePod.tintColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pod ${activePod.number} · ${activePod.tintName}',
                        style: AppText.title(16, w: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Max 2 hrs',
                        style: AppText.label(11, w: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  activePod.features,
                  style: AppText.body(12.5, color: AppColors.textSecondary),
                ),
                const Divider(height: 24),

                // Duration Selector
                Text(
                  'RESERVATION DURATION',
                  style: AppText.overline(11, ls: 1.0, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final d in [30, 60, 90, 120]) ...[
                      Expanded(
                        child: PressScale(
                          onTap: () {
                            AppFeedback.tap();
                            setState(() => _durationMinutes = d);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _durationMinutes == d
                                  ? AppColors.primary
                                  : (isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.scheme.surfaceContainer),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _durationMinutes == d ? AppColors.primary : Colors.transparent,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${d}m',
                              style: AppText.label(
                                12,
                                w: FontWeight.w700,
                                color: _durationMinutes == d ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (d != 120) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          if (!_booked) ...[
            PrimaryButton(
              label: 'Reserve Pod ${activePod.number}',
              icon: Icons.key_rounded,
              onPressed: () {
                AppFeedback.success();
                setState(() => _booked = true);
              },
            ),
          ] else ...[
            // Digital Smart Key Issued Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: const [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(color: const Color(0xFF7EE0C3)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7EE0C3).withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF7EE0C3), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pod ${activePod.number} Reserved!',
                          style: AppText.title(16, w: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7EE0C3).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(AppRadii.full),
                        ),
                        child: Text(
                          'ACTIVE NOW',
                          style: AppText.overline(10, color: const Color(0xFFFFE0B2)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'SMART DIGITAL PASSCODE',
                    style: AppText.overline(11, ls: 1.5, color: const Color(0xFFD3A376)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '7 4 9 2',
                    style: AppText.display(36, w: FontWeight.w800, color: const Color(0xFFFFE0B2), ls: 8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter this 4-digit PIN on the Pod ${activePod.number} glass keypad or hold your phone to unlock via NFC.',
                    textAlign: TextAlign.center,
                    style: AppText.body(11.5, color: Colors.white70),
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

