import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

/// Brand pieces: the Nordic splash and the campus mark.
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
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        AppStrings.appName.substring(0, 1).toUpperCase(),
        style: AppText.display(
          size * 0.42,
          w: FontWeight.w700,
          color: AppColors.textInverse,
          ls: -0.5,
        ),
      ),
    );
  }
}

/// Opening: ring draws, mark lands, wordmark fades. Tap skips. Reduce-motion shortens it.
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
    duration: const Duration(milliseconds: 1800),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduced = MediaQuery.disableAnimationsOf(context);
    _controller.duration = reduced
        ? const Duration(milliseconds: 400)
        : const Duration(milliseconds: 1800);
    _controller.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
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
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );
    final mark = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.16, 0.50, curve: Curves.easeOutCubic),
    );
    final word = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.40, 0.72, curve: Curves.easeOutCubic),
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: () {
          _controller.stop();
          widget.onDone();
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 148,
                height: 148,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: ring,
                      builder: (context, _) => CustomPaint(
                        size: const Size(148, 148),
                        painter: _BrandRingPainter(ring.value),
                      ),
                    ),
                    ScaleTransition(
                      scale: mark,
                      child: const CampusMark(size: 64),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: word,
                child: Column(
                  children: [
                    Text(
                      AppStrings.appName,
                      style: AppText.title(28, w: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Campus library & study seats',
                      style: AppText.body(14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
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
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
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
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _BrandRingPainter old) =>
      old.progress != progress;
}

/// Compact status pill used on check-in screens.
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
              11,
              w: FontWeight.w700,
              ls: 0.6,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
