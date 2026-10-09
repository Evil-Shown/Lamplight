import 'package:flutter/material.dart';

import '../constants/app_constants.dart' hide AppSpacing;
import '../theme/app_theme.dart';
import 'glass.dart';

class CampusMark extends StatelessWidget {
  const CampusMark({super.key, this.size = 56, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.28);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: radius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.38),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      // Glass sheen across the top-left of the tile.
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0, 0.5],
          colors: [
            Colors.white.withValues(alpha: 0.30),
            Colors.white.withValues(alpha: 0),
          ],
        ),
      ),
      child: Text(
        AppStrings.appName.substring(0, 1).toUpperCase(),
        style: AppText.display(
          size * 0.42,
          w: FontWeight.w700,
          color: Colors.white,
          ls: -0.5,
        ),
      ),
    );
  }
}

/// Opening: the logo rises in on a glass panel, a soft ring pulses, the name
/// and tagline fade in, and a slim progress bar fills. Tap skips.
/// Reduce-motion shows the final state straight away.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _total = Duration(milliseconds: 1700);
  static const _reducedHold = Duration(milliseconds: 400);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _total,
  );

  bool _started = false;
  bool _finished = false;

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    widget.onDone();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      Future<void>.delayed(_reducedHold, _finish);
    } else {
      _controller.forward().whenComplete(_finish);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _interval(double a, double b, Curve curve) =>
      CurvedAnimation(parent: _controller, curve: Interval(a, b, curve: curve));

  @override
  Widget build(BuildContext context) {
    final logoIn = _interval(0.0, 0.50, AppMotion.springEntrance);
    final logoFade = _interval(0.0, 0.25, Curves.easeOut);
    final pulse = _interval(0.25, 0.80, Curves.easeOutCubic);
    final word = _interval(0.35, 0.65, Curves.easeOutCubic);
    final bar = _interval(0.10, 1.0, Curves.easeInOutCubic);

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          onTap: () {
            _controller.stop();
            _finish();
          },
          behavior: HitTestBehavior.opaque,
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 168,
                            height: 168,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                AnimatedBuilder(
                                  animation: pulse,
                                  builder: (context, _) => CustomPaint(
                                    size: const Size(168, 168),
                                    painter: _PulseRingPainter(pulse.value),
                                  ),
                                ),
                                AnimatedBuilder(
                                  animation: _controller,
                                  builder: (context, child) => Opacity(
                                    opacity: logoFade.value.clamp(0.0, 1.0),
                                    child: Transform.translate(
                                      offset: Offset(
                                        0,
                                        AppSpacing.xxl * (1 - logoIn.value),
                                      ),
                                      child: Transform.scale(
                                        scale: 0.7 + 0.3 * logoIn.value,
                                        child: child,
                                      ),
                                    ),
                                  ),
                                  child: const GlassSurface(
                                    radius: AppRadii.xl,
                                    padding: EdgeInsets.all(AppSpacing.lg),
                                    child: CampusMark(size: 64),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          FadeTransition(
                            opacity: word,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.25),
                                end: Offset.zero,
                              ).animate(word),
                              child: Column(
                                children: [
                                  Text(
                                    AppStrings.appName,
                                    textAlign: TextAlign.center,
                                    style: AppText.title(
                                      28,
                                      w: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Campus library & study seats',
                                    textAlign: TextAlign.center,
                                    style: AppText.body(
                                      14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                  child: FadeTransition(
                    opacity: word,
                    child: Semantics(
                      label: 'Loading',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                        child: SizedBox(
                          width: 120,
                          height: 4,
                          child: AnimatedBuilder(
                            animation: bar,
                            builder: (context, _) => CustomPaint(
                              painter: _ProgressBarPainter(bar.value),
                            ),
                          ),
                        ),
                      ),
                    ),
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

/// Soft brand-gradient halo that expands and settles.
class _PulseRingPainter extends CustomPainter {
  _PulseRingPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20 + 12 * t;
    final rect = Rect.fromCircle(center: centre, radius: radius);
    final alpha = (1 - t) * 0.9 + 0.1;
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = AppColors.primary.withValues(alpha: 0.10 * alpha),
    );
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = AppGradients.brand.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _PulseRingPainter old) => old.t != t;
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.primary.withValues(alpha: 0.14),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * progress, size.height),
      Paint()..shader = AppGradients.brand.createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressBarPainter old) =>
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
