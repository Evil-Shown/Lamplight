import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

/// ─────────────────────────────────────────────────────────────────────
///  "The Ledger" signature components — see UI-mockup.md §5–§7.
/// ─────────────────────────────────────────────────────────────────────

/// Archive-mono uppercase eyebrow line.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color, this.textAlign});

  final String text;
  final Color? color;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      textAlign: textAlign,
      style: AppText.mono(10.5, w: FontWeight.w600, ls: 3, color: color),
    );
  }
}

/// Ink-world surface: ledger gradient, deep shadow, optional hairline.
class InkPanel extends StatelessWidget {
  const InkPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadii.xl,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        gradient: AppGradients.ledger,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.22)),
        boxShadow: AppShadows.ink,
      ),
      child: child,
    );
    if (onTap == null) return panel;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(radius), child: panel),
    );
  }
}

/// Foil-gold smartcard chip used on the member card.
class GoldChip extends StatelessWidget {
  const GoldChip({super.key, this.width = 44, this.height = 33});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: AppGradients.foil,
        borderRadius: BorderRadius.circular(6),
        boxShadow: AppShadows.glow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(height: 1.4, color: AppColors.inkDeep.withValues(alpha: 0.45)),
          Container(height: 1.4, color: AppColors.inkDeep.withValues(alpha: 0.45)),
        ],
      ),
    );
  }
}

/// Dashed stroke painter for stamps, banners and ticket perforations.
class DashedRRectPainter extends CustomPainter {
  DashedRRectPainter({
    required this.color,
    this.radius = 14,
    this.strokeWidth = 1.3,
    this.dash = 4,
    this.gap = 3.5,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
    for (final metric in path.computeMetrics()) {
      var drawn = 0.0;
      while (drawn < metric.length) {
        final end = math.min(drawn + dash, metric.length);
        canvas.drawPath(metric.extractPath(drawn, end), paint);
        drawn = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRRectPainter old) => old.color != color;
}

/// Horizontal dashed rule (ticket dividers, seat-map row separators).
class DashedRule extends StatelessWidget {
  const DashedRule({super.key, this.color, this.height = 1.4});

  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) => CustomPaint(
          size: Size(constraints.maxWidth, height),
          painter: _DashedRulePainter(
            color: color ?? AppColors.gold.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

class _DashedRulePainter extends CustomPainter {
  _DashedRulePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color;
    const dash = 4.0;
    const gap = 3.5;
    var drawn = 0.0;
    while (drawn < size.width) {
      final end = (drawn + dash).clamp(0.0, size.width);
      canvas.drawLine(Offset(drawn, 0), Offset(end, 0), paint);
      drawn = end + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRulePainter old) => old.color != color;
}

/// Vertical dashed perforation line (ticket stubs).
class DashedLineVertical extends StatelessWidget {
  const DashedLineVertical({super.key, this.color, this.height});

  final Color? color;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1.4,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) => CustomPaint(
          size: Size(1.4, constraints.maxHeight),
          painter: _DashedLinePainter(
            color: color ?? AppColors.gold.withValues(alpha: 0.55),
            vertical: true,
          ),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.vertical, required this.color});

  final bool vertical;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color;
    const dash = 4.0;
    const gap = 3.5;
    final extent = vertical ? size.height : size.width;
    var drawn = 0.0;
    while (drawn < extent) {
      final end = math.min(drawn + dash, extent);
      final p = Path();
      if (vertical) {
        p.moveTo(0, drawn);
        p.lineTo(0, end);
      } else {
        p.moveTo(drawn, 0);
        p.lineTo(end, 0);
      }
      canvas.drawPath(p, paint);
      drawn = end + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}

/// Cream ticket-stub card with a gold perforation and punched notches.
class TicketCard extends StatelessWidget {
  const TicketCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 16, 16),
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.paperCard,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.lineStrong.withValues(alpha: 0.7)),
        boxShadow: AppShadows.soft,
      ),
      child: child,
    );

    final stack = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Stack(
        children: [
          card,
          const Positioned(
            left: 12,
            top: 14,
            bottom: 14,
            child: DashedLineVertical(),
          ),
          const Positioned(left: -6, top: 8, child: _TicketNotch()),
          const Positioned(left: -6, bottom: 8, child: _TicketNotch()),
        ],
      ),
    );

    Widget result = stack;
    if (onTap != null) {
      result = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: stack,
        ),
      );
    }
    if (margin == null) return result;
    return Padding(padding: margin!, child: result);
  }
}

class _TicketNotch extends StatelessWidget {
  const _TicketNotch();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(
        color: AppColors.paper,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// The Library+ member card — ink gradient, foil chip, archive-mono details.
class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.name,
    required this.studentId,
    required this.email,
    required this.validThru,
  });

  final String name;
  final String studentId;
  final String email;
  final String validThru;

  @override
  Widget build(BuildContext context) {
    return InkPanel(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Eyebrow('✦ LIBRARY+ MEMBER', color: AppColors.gold),
              ),
              GoldChip(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(name, style: AppText.serif(25, color: AppColors.paper)),
          const SizedBox(height: 5),
          Text(
            studentId.replaceAll('-', ' · ').toUpperCase(),
            style: AppText.mono(12, w: FontWeight.w600, ls: 3, color: AppColors.goldSoft),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  email,
                  style: AppText.sans(12.5, color: AppColors.paper.withValues(alpha: 0.55)),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('VALID', style: AppText.mono(10, ls: 2, color: AppColors.gold)),
                  const SizedBox(height: 2),
                  Text(validThru.toUpperCase(),
                      style: AppText.mono(10, ls: 2, color: AppColors.gold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Best match" recommendation strip on the seat map.
class BestMatchCard extends StatelessWidget {
  const BestMatchCard({
    super.key,
    required this.seatLabel,
    required this.description,
    this.onTap,
  });

  final String seatLabel;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkPanel(
      radius: AppRadii.lg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Icon(Icons.star_rounded, color: AppColors.gold, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Best match: $seatLabel',
                    style: AppText.serif(16.5, color: AppColors.paper, ls: -0.2)),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppText.sans(12.5, color: AppColors.paper.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: AppColors.paper.withValues(alpha: 0.3)),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────
///  Splash — "The Opening" (UI-mockup.md §6.1)
/// ─────────────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  late final CurvedAnimation _ring =
      CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.24, curve: Curves.easeOutCubic));
  late final CurvedAnimation _emblem =
      CurvedAnimation(parent: _c, curve: const Interval(0.10, 0.34, curve: Curves.easeOutBack));
  late final CurvedAnimation _wordmark =
      CurvedAnimation(parent: _c, curve: const Interval(0.26, 0.48, curve: Curves.easeOutCubic));
  late final CurvedAnimation _shimmer =
      CurvedAnimation(parent: _c, curve: const Interval(0.34, 0.60, curve: Curves.easeInOut));
  late final CurvedAnimation _tagline =
      CurvedAnimation(parent: _c, curve: const Interval(0.44, 0.64, curve: Curves.easeOut));
  late final CurvedAnimation _fade =
      CurvedAnimation(parent: _c, curve: const Interval(0.86, 1.0, curve: Curves.easeInCubic));

  @override
  void initState() {
    super.initState();
    _c.addStatusListener(_onStatus);
    _c.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.onDone();
  }

  @override
  void dispose() {
    _c.removeStatusListener(_onStatus);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (reducedMotion && _c.duration != const Duration(milliseconds: 500)) {
      _c.duration = const Duration(milliseconds: 500);
      _c.forward();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: GestureDetector(
          onTap: widget.onDone,
          behavior: HitTestBehavior.opaque,
          child: FadeTransition(
            opacity: Tween<double>(begin: 1, end: 0).animate(_fade),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Foil ring + etched book emblem
                  AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) {
                      return SizedBox(
                        width: 148,
                        height: 148,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(148, 148),
                              painter: _FoilRingPainter(progress: _ring.value),
                            ),
                            Transform.scale(
                              scale: 0.7 + 0.3 * _emblem.value,
                              child: Opacity(
                                opacity: _emblem.value.clamp(0, 1),
                                child: const Icon(
                                  Icons.auto_stories_rounded,
                                  size: 46,
                                  color: AppColors.goldDeep,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Wordmark with foil shimmer sweep
                  AnimatedBuilder(
                    animation: _wordmark,
                    builder: (context, child) => _FoilShimmer(
                      progress: _shimmer.value,
                      child: Opacity(
                        opacity: _wordmark.value.clamp(0, 1),
                        child: Transform.translate(
                          offset: Offset(0, 12 * (1 - _wordmark.value)),
                          child: child!,
                        ),
                      ),
                    ),
                    child: Text('Library+',
                        style: AppText.serif(36, w: FontWeight.w800)),
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  AnimatedBuilder(
                    animation: _tagline,
                    builder: (context, _) => Opacity(
                      opacity: _tagline.value.clamp(0, 1),
                      child: const Eyebrow('EST. 2024 · CAMPUS READING ROOM'),
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

class _FoilRingPainter extends CustomPainter {
  _FoilRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final rect = Offset.zero & size;
    const inset = 5.0;
    final arcRect = rect.deflate(inset);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..shader = AppGradients.foil.createShader(arcRect);
    canvas.drawArc(arcRect, -math.pi / 2, 2 * math.pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(covariant _FoilRingPainter old) => old.progress != progress;
}

/// One-shot foil sheen sweeping across a text child (React Bits Shimmer analog).
class _FoilShimmer extends StatelessWidget {
  const _FoilShimmer({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = progress;
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        final x = -1.5 + 3.0 * t;
        return LinearGradient(
          begin: Alignment(x - 0.5, 0),
          end: Alignment(x + 0.5, 0),
          colors: const [
            AppColors.textPrimary,
            AppColors.gold,
            AppColors.textPrimary,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}
