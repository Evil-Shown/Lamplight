import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_constants.dart' show AppStrings;
import 'auth_style.dart';
import 'library_scenes.dart';

/// Opening screen: a dimmed bookcase glows behind a dark glass card. The
/// mark rises in, a lamp-light ring pulses, the name and tagline fade in,
/// and a slim bar fills. Tap skips. Reduce-motion shows the final state.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _total = Duration(milliseconds: 2000);
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
    final card = _interval(0.0, 0.40, Curves.easeOutCubic);
    final glow = _interval(0.20, 0.85, Curves.easeOutCubic);
    final word = _interval(0.30, 0.62, Curves.easeOutCubic);
    final bar = _interval(0.10, 1.0, Curves.easeInOutCubic);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AuthPalette.espresso,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _controller.stop();
            _finish();
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ShelfScene(),
              // Dim the shelves and pull the eye to the middle.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 1.05,
                    colors: [
                      AuthPalette.espresso.withValues(alpha: 0.55),
                      AuthPalette.espresso.withValues(alpha: 0.92),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: FadeTransition(
                            opacity: card,
                            child: _GlassCard(glow: glow, word: word),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: FadeTransition(
                        opacity: word,
                        child: Semantics(
                          label: 'Loading',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: SizedBox(
                              width: 120,
                              height: 4,
                              child: AnimatedBuilder(
                                animation: bar,
                                builder: (context, _) => CustomPaint(
                                  painter: _BarPainter(bar.value),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.glow, required this.word});

  final Animation<double> glow;
  final Animation<double> word;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AuthPalette.walnut.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: AuthPalette.cream.withValues(alpha: 0.14),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 34, 28, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 132,
                    height: 132,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: glow,
                          builder: (context, _) => CustomPaint(
                            size: const Size(132, 132),
                            painter: _GlowPainter(glow.value),
                          ),
                        ),
                        const _Mark(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
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
                            style: GoogleFonts.fraunces(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              color: AuthPalette.cream,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const _Ornament(),
                          const SizedBox(height: 10),
                          Text(
                            'Campus library & study seats',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              color: AuthPalette.cream.withValues(alpha: 0.72),
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
      ),
    );
  }
}

/// Amber rounded-square mark with an open book.
class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0B565), Color(0xFFB8702C)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AuthPalette.accent.withValues(alpha: 0.45),
            blurRadius: 28,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_stories_rounded,
        size: 36,
        color: AuthPalette.espresso,
      ),
    );
  }
}

/// A thin rule with a diamond in the middle, like the reference cards.
class _Ornament extends StatelessWidget {
  const _Ornament();

  @override
  Widget build(BuildContext context) {
    final line = Container(
      width: 44,
      height: 1,
      color: AuthPalette.accent.withValues(alpha: 0.55),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        line,
        const SizedBox(width: 8),
        Transform.rotate(
          angle: 0.785398,
          child: Container(width: 6, height: 6, color: AuthPalette.accent),
        ),
        const SizedBox(width: 8),
        line,
      ],
    );
  }
}

/// Lamp-light halo that expands and settles behind the mark.
class _GlowPainter extends CustomPainter {
  _GlowPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final c = Offset(size.width / 2, size.height / 2);
    final r = 40 + 26 * t;
    canvas.drawCircle(
      c,
      r + 22,
      Paint()
        ..shader = RadialGradient(colors: [
          AuthPalette.accent.withValues(alpha: 0.34 * (1 - t * 0.4)),
          AuthPalette.accent.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: c, radius: r + 22)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AuthPalette.accent.withValues(alpha: 0.75 * (1 - t) + 0.15),
    );
  }

  @override
  bool shouldRepaint(covariant _GlowPainter old) => old.t != t;
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AuthPalette.cream.withValues(alpha: 0.14),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * progress, size.height),
      Paint()..color = AuthPalette.accent,
    );
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) => old.progress != progress;
}
