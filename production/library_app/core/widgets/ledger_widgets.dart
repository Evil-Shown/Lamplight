import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

/// ─────────────────────────────────────────────────────────────────────
///  Brand pieces: the animated splash and the campus mark. The Ledger
///  vocabulary (ticket stubs, foil chips, ink panels) is gone — the
///  prototype has no use for it.
/// ─────────────────────────────────────────────────────────────────────

/// The rounded "LP" app mark used on the splash, login, and staff header.
class CampusMark extends StatelessWidget {
  const CampusMark({super.key, this.size = 56, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: AppShadows.primary,
      ),
      child: Text(
        AppStrings.appName.substring(0, 1).toUpperCase(),
        style: AppText.display(
          size * 0.42,
          w: FontWeight.w800,
          color: AppColors.textInverse,
          ls: -0.5,
        ),
      ),
    );
  }
}

/// The animated opening. A brand ring draws itself, the mark lands, and
/// the wordmark fades up — the same choreography as before, retuned to
/// the new blue palette and shortened a little.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2100),
  )..addStatusListener(_onStatus);

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Shorten the choreography when the platform asks for reduced motion.
    _controller.duration =
        MediaQuery.disableAnimationsOf(context)
            ? const Duration(milliseconds: 400)
            : const Duration(milliseconds: 2100);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.onDone();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ring = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.42, curve: Curves.easeOutCubic),
    );
    final mark = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.18, 0.52, curve: Curves.easeOutBack),
    );
    final word = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.42, 0.72, curve: Curves.easeOut),
    );
    final fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.86, 1.0, curve: Curves.easeInCubic),
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: GestureDetector(
        onTap: () {
          _controller.stop();
          widget.onDone();
        },
        behavior: HitTestBehavior.opaque,
        child: FadeTransition(
          opacity: fade,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 132,
                  height: 132,
                  child: AnimatedBuilder(
                    animation: ring,
                    builder: (context, _) =>
                        CustomPaint(painter: _BrandRingPainter(ring.value)),
                  ),
                ),
                const SizedBox(height: 22),
                ScaleTransition(
                  scale: mark,
                  child: const CampusMark(size: 62),
                ),
                const SizedBox(height: 18),
                FadeTransition(
                  opacity: word,
                  child: Column(
                    children: [
                      Text(
                        AppStrings.appName,
                        style: AppText.display(
                          24,
                          w: FontWeight.w800,
                          ls: -0.6,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'UNIVERSITY LIBRARY & STUDY SEATS',
                        style: AppText.label(
                          11.5,
                          w: FontWeight.w600,
                          ls: 2.4,
                          color: AppColors.textFaint,
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
    );
  }
}

class _BrandRingPainter extends CustomPainter {
  _BrandRingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final centre = rect.center;
    final radius = size.width / 2 - 5;

    // Soft halo behind the sweeping arc.
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = AppColors.primary.withValues(alpha: 0.10 * progress),
    );

    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..shader = AppGradients.brand.createShader(
          Rect.fromCircle(center: centre, radius: radius),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _BrandRingPainter old) =>
      old.progress != progress;
}

/// The "STATE: VERIFIED" style pill used on the check-in screens.
class StatePill extends StatelessWidget {
  const StatePill({
    super.key,
    required this.label,
    this.color,
    this.background,
    this.pulse = true,
  });

  final String label;
  final Color? color;
  final Color? background;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background ?? effectiveColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse) ...[
            Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: effectiveColor),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppText.label(
                11, w: FontWeight.w700, ls: 0.6, color: effectiveColor),
          ),
        ],
      ),
    );
  }
}
