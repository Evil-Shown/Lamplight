import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/test_env.dart';
import '../theme/app_theme.dart';

/// Liquid-glass primitives: the aurora backdrop and the glass surfaces.
///
/// Which surface to use:
/// - [GlassSurface] runs a real `BackdropFilter`. Use it for chrome and
///   hero panels that sit over the aurora or scrolling content: the app
///   bar, the dock, the bottom action bar, sheets, and at most one or two
///   panels per screen.
/// - [FrostedCard] has the same look (translucent fill, rim light, border,
///   shadow) with NO blur. Use it for anything that repeats in a scrolling
///   list or grid. Stacked BackdropFilters make scrolling janky on
///   mid-range Android, and over the soft aurora the blur is barely
///   visible anyway.
///
/// Text on either stays at about 4.5:1 or better because the fills are
/// 58-78% opaque over a pale (light) or very dark (dark) canvas.

/// Marks that an [AuroraBackground] is already painted above, so nested
/// ones (e.g. an `AppScaffold` inside the tab shell) pass through instead
/// of painting a second backdrop.
class _AuroraScope extends InheritedWidget {
  const _AuroraScope({required super.child});

  @override
  bool updateShouldNotify(_AuroraScope oldWidget) => false;
}

/// Full-bleed backdrop of large soft colour blobs that drift very slowly.
///
/// Painted in a single `RepaintBoundary` with radial gradients: no layout
/// per frame, no blur filters. Static when animations are disabled (or in
/// tests). Nested instances pass through to their child.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key, required this.child, this.animate = true});

  final Widget child;

  /// Set false to force a static backdrop.
  final bool animate;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  bool get _wantsMotion =>
      widget.animate &&
      !isRunningInTest &&
      !MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(AuroraBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final nested =
        context.getInheritedWidgetOfExactType<_AuroraScope>() != null;
    if (_wantsMotion && !nested) {
      _controller ??= AnimationController(
        vsync: this,
        duration: const Duration(seconds: 80),
      )..repeat();
    } else {
      _controller?.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.getInheritedWidgetOfExactType<_AuroraScope>() != null) {
      return widget.child;
    }
    return _AuroraScope(
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              painter: _AuroraPainter(
                colors: AppAurora.colors,
                sky: AppAurora.sky,
                progress: _controller,
              ),
            ),
          ),
          _NatureBackdrop(dark: AppColors.isDark),
          widget.child,
        ],
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({
    required this.colors,
    required this.sky,
    required this.progress,
  }) : super(repaint: progress);

  final List<Color> colors;
  final List<Color> sky;
  final Animation<double>? progress;

  // Anchor (fraction of size), radius (fraction of the longer side),
  // drift amplitude and phase per blob.
  static const _blobs = <(double, double, double, double, double)>[
    (0.15, 0.08, 0.62, 0.06, 0.0),
    (0.95, 0.30, 0.55, 0.07, 0.25),
    (0.10, 0.72, 0.58, 0.06, 0.5),
    (0.85, 0.95, 0.50, 0.05, 0.75),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: sky,
        ).createShader(rect),
    );
    final t = progress?.value ?? 0.0;
    final longest = math.max(size.width, size.height);
    for (var i = 0; i < _blobs.length; i++) {
      final (ax, ay, r, amp, phase) = _blobs[i];
      final angle = 2 * math.pi * (t + phase);
      final centre = Offset(
        size.width * (ax + amp * math.sin(angle)),
        size.height * (ay + amp * math.cos(angle * 1.0)),
      );
      final radius = longest * r;
      final color = colors[i % colors.length];
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: centre, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) =>
      old.sky != sky || old.colors != colors || old.progress != progress;
}

/// An arid dusk scene at the bottom of the backdrop: a low sun, flat-topped
/// buttes and layered sand dunes with a lit and a shadowed side, and a
/// saguaro in the foreground. Painted once inside its own repaint boundary
/// with no blur, so it stays crisp and costs nothing while scrolling.
class _NatureBackdrop extends StatelessWidget {
  const _NatureBackdrop({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: _NaturePainter(dark: dark),
          ),
        ),
      );
}

class _NaturePainter extends CustomPainter {
  const _NaturePainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (dark) {
      _nightSky(canvas, w, h);
    } else {
      _morningSun(canvas, w, h);
    }

    // 1. Distant misty mountains
    _mountains(canvas, w, h);

    // 2. Midground pine treeline
    _pineTreeline(canvas, w, h);

    // 3. Foreground rolling forest hills
    _foregroundHills(canvas, w, h);

    // 4. Foreground framing pine silhouettes
    _pineTree(
      canvas,
      w * 0.10,
      h * 0.88,
      h * 0.12,
      (dark ? const Color(0xFF160F0C) : const Color(0xFF64748B))
          .withValues(alpha: dark ? 0.28 : 0.15),
    );
    _pineTree(
      canvas,
      w * 0.88,
      h * 0.86,
      h * 0.14,
      (dark ? const Color(0xFF160F0C) : const Color(0xFF64748B))
          .withValues(alpha: dark ? 0.28 : 0.15),
    );

    // 5. Subtle bottom depth scrim
    final foot = Rect.fromLTWH(0, h * 0.80, w, h * 0.20);
    canvas.drawRect(
      foot,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (dark ? const Color(0xFF160F0C) : const Color(0xFFF1F5F9))
                .withValues(alpha: 0),
            (dark ? const Color(0xFF160F0C) : const Color(0xFFF1F5F9))
                .withValues(alpha: dark ? 0.65 : 0.45),
          ],
        ).createShader(foot),
    );
  }

  void _morningSun(Canvas canvas, double w, double h) {
    final c = Offset(w * 0.72, h * 0.58);
    final glowR = w * 0.48;

    canvas.drawCircle(
      c,
      glowR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFEF3C7).withValues(alpha: 0.45),
            const Color(0xFFE0F2FE).withValues(alpha: 0.20),
            const Color(0xFFE0F2FE).withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromCircle(center: c, radius: glowR)),
    );

    canvas.drawCircle(
      c,
      w * 0.068,
      Paint()..color = const Color(0xFFFFFBEB).withValues(alpha: 0.85),
    );
  }

  void _nightSky(Canvas canvas, double w, double h) {
    final glow = Rect.fromLTWH(0, h * 0.46, w, h * 0.28);
    canvas.drawRect(
      glow,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0B0F19).withValues(alpha: 0),
            const Color(0xFFF59E0B).withValues(alpha: 0.10),
          ],
        ).createShader(glow),
    );

    var seed = 42;
    double next() {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed / 0x80000000;
    }

    final starPaint = Paint();
    for (var i = 0; i < 85; i++) {
      final x = next() * w;
      final y = next() * h * 0.58;
      final fade = 1 - (y / (h * 0.58)) * 0.5;
      final r = 0.5 + next() * 1.0;
      starPaint.color = const Color(0xFFF8FAFC)
          .withValues(alpha: (0.35 + next() * 0.55) * fade);
      canvas.drawCircle(Offset(x, y), r, starPaint);
    }

    final bright = Paint()
      ..color = const Color(0xFFF8FAFC).withValues(alpha: 0.9)
      ..strokeWidth = 0.8;
    for (final (x, y) in const [
      (0.18, 0.12),
      (0.38, 0.22),
      (0.84, 0.14),
      (0.60, 0.32),
    ]) {
      final sc = Offset(w * x, h * y);
      canvas.drawCircle(sc, 1.4, bright);
      canvas.drawLine(sc.translate(-4, 0), sc.translate(4, 0), bright);
      canvas.drawLine(sc.translate(0, -4), sc.translate(0, 4), bright);
    }

    final mc = Offset(w * 0.74, h * 0.54);
    final moonR = w * 0.055;
    final haloR = w * 0.32;

    canvas.drawCircle(
      mc,
      haloR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFF59E0B).withValues(alpha: 0.18),
            const Color(0xFFF59E0B).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: mc, radius: haloR)),
    );

    final moonPath = Path()
      ..addOval(Rect.fromCircle(center: mc, radius: moonR));
    final cutPath = Path()
      ..addOval(Rect.fromCircle(center: mc.translate(-moonR * 0.45, -moonR * 0.35), radius: moonR * 0.95));
    final crescent = Path.combine(PathOperation.difference, moonPath, cutPath);
    canvas.drawPath(crescent, Paint()..color = const Color(0xFFF8FAFC));
  }

  void _mountains(Canvas canvas, double w, double h) {
    final backColor = dark ? const Color(0xFF111827) : const Color(0xFFE2E8F0);
    final backPath = Path()
      ..moveTo(0, h * 0.69)
      ..cubicTo(w * 0.22, h * 0.63, w * 0.38, h * 0.66, w * 0.58, h * 0.61)
      ..cubicTo(w * 0.76, h * 0.57, w * 0.90, h * 0.64, w, h * 0.62)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(backPath, Paint()..color = backColor);

    final midColor = dark ? const Color(0xFF0D121F) : const Color(0xFFCBD5E1);
    final midPath = Path()
      ..moveTo(0, h * 0.73)
      ..cubicTo(w * 0.18, h * 0.68, w * 0.35, h * 0.74, w * 0.52, h * 0.69)
      ..cubicTo(w * 0.72, h * 0.64, w * 0.88, h * 0.71, w, h * 0.68)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(midPath, Paint()..color = midColor);
  }

  void _pineTreeline(Canvas canvas, double w, double h) {
    final treelineColor = dark
        ? const Color(0xFF090D16)
        : const Color(0xFF94A3B8).withValues(alpha: 0.45);
    final ridgePath = Path()
      ..moveTo(0, h * 0.78)
      ..cubicTo(w * 0.3, h * 0.75, w * 0.65, h * 0.79, w, h * 0.76)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(ridgePath, Paint()..color = treelineColor);

    final count = 18;
    for (var i = 0; i < count; i++) {
      final tx = w * (i / (count - 1));
      final ty = h * (0.755 + 0.025 * math.sin(i * 1.3));
      final th = h * 0.040 + (i % 3) * 6.0;
      _pineTree(canvas, tx, ty, th, treelineColor);
    }
  }

  void _foregroundHills(Canvas canvas, double w, double h) {
    final hillColor = dark
        ? const Color(0xFF060910)
        : const Color(0xFFCBD5E1).withValues(alpha: 0.35);
    final hillPath = Path()
      ..moveTo(0, h * 0.84)
      ..cubicTo(w * 0.35, h * 0.81, w * 0.70, h * 0.86, w, h * 0.83)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hillPath, Paint()..color = hillColor);
  }

  void _pineTree(Canvas canvas, double x, double base, double height, Color color) {
    final paint = Paint()..color = color;
    final trunkW = height * 0.12;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(x, base - height * 0.12),
        width: trunkW,
        height: height * 0.24,
      ),
      Paint()..color = color.withValues(alpha: 0.85),
    );

    for (var i = 0; i < 3; i++) {
      final tierBase = base - height * (0.18 + i * 0.24);
      final tierWidth = height * (0.52 - i * 0.12);
      final tierHeight = height * 0.38;

      final path = Path()
        ..moveTo(x - tierWidth / 2, tierBase)
        ..lineTo(x, tierBase - tierHeight)
        ..lineTo(x + tierWidth / 2, tierBase)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NaturePainter old) => old.dark != dark;
}

/// Shared glass look. [blur] null = frosted (no BackdropFilter).
class _GlassBox extends StatelessWidget {
  const _GlassBox({
    required this.child,
    required this.borderRadius,
    required this.padding,
    required this.blur,
    required this.fill,
    required this.tint,
    required this.shadows,
    required this.highlight,
    required this.border,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? blur;
  final Color? fill;
  final Color? tint;
  final bool shadows;
  final bool highlight;
  final bool border;

  @override
  Widget build(BuildContext context) {
    var fillColor = fill ??
        (blur != null && blur! >= AppGlass.blurChrome
            ? AppGlass.chromeFill
            : AppGlass.cardFill);
    if (tint != null) {
      fillColor = Color.alphaBlend(tint!, fillColor);
    }

    Widget inner = DecoratedBox(
      decoration: BoxDecoration(
        color: fillColor,
        gradient: highlight ? AppGlass.highlight : null,
        borderRadius: borderRadius,
      ),
      position: DecorationPosition.background,
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );

    if (border) {
      inner = CustomPaint(
        foregroundPainter: _RimPainter(
          radius: borderRadius,
          rim: AppGlass.rim,
          line: AppGlass.border,
        ),
        child: inner,
      );
    }

    inner = ClipRRect(
      borderRadius: borderRadius,
      child: blur == null
          ? inner
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur!, sigmaY: blur!),
              child: inner,
            ),
    );

    if (!shadows) return inner;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: AppGlass.shadows,
      ),
      child: inner,
    );
  }
}

/// A glass panel with a real backdrop blur. Chrome and hero panels only;
/// use [FrostedCard] for list items.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = AppRadii.card,
    this.borderRadius,
    this.padding,
    this.blur = AppGlass.blurChrome,
    this.fill,
    this.tint,
    this.shadows = true,
    this.highlight = true,
    this.border = true,
  });

  final Widget child;

  /// Uniform corner radius, ignored when [borderRadius] is set.
  final double radius;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  /// Blur sigma; see [AppGlass.blurChrome] / [AppGlass.blurCard].
  final double blur;

  /// Overrides the translucent fill.
  final Color? fill;

  /// Colour washed over the fill (e.g. `AppColors.primary.withValues(alpha: .12)`).
  final Color? tint;
  final bool shadows;

  /// Top-left sheen.
  final bool highlight;

  /// Rim + hairline outline.
  final bool border;

  @override
  Widget build(BuildContext context) {
    return _GlassBox(
      borderRadius: borderRadius ?? BorderRadius.circular(radius),
      padding: padding,
      blur: blur,
      fill: fill,
      tint: tint,
      shadows: shadows,
      highlight: highlight,
      border: border,
      child: child,
    );
  }
}

/// The glass look without a backdrop blur: the default for anything in a
/// scrolling list. Wraps its child in a transparent [Material] so ink
/// splashes and `ListTile`s still work.
class FrostedCard extends StatelessWidget {
  const FrostedCard({
    super.key,
    required this.child,
    this.radius = AppRadii.card,
    this.borderRadius,
    this.padding,
    this.fill,
    this.tint,
    this.shadows = true,
    this.highlight = true,
    this.border = true,
  });

  final Widget child;
  final double radius;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? fill;
  final Color? tint;
  final bool shadows;
  final bool highlight;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return _GlassBox(
      borderRadius: borderRadius ?? BorderRadius.circular(radius),
      padding: null,
      blur: null,
      fill: fill,
      tint: tint,
      shadows: shadows,
      highlight: highlight,
      border: border,
      child: Material(
        type: MaterialType.transparency,
        child:
            padding == null ? child : Padding(padding: padding!, child: child),
      ),
    );
  }
}

/// 1px outline: bright rim on the top-left fading to a hairline.
class _RimPainter extends CustomPainter {
  const _RimPainter({
    required this.radius,
    required this.rim,
    required this.line,
  });

  final BorderRadius radius;
  final Color rim;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    canvas.drawRRect(
      radius.toRRect(rect),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [rim, line, line],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RimPainter old) =>
      old.radius != radius || old.rim != rim || old.line != line;
}

/// Blurred app bar. Pair with `Scaffold(extendBodyBehindAppBar: true)` so
/// content scrolls under it (add [contentTopPadding] to the scrollable).
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.centerTitle = true,
  });

  final String? title;

  /// Replaces [title] when set.
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  /// Space a scrollable needs at its top so its first item starts below
  /// the bar: status bar + toolbar.
  static double contentTopPadding(BuildContext context) =>
      MediaQuery.paddingOf(context).top + kToolbarHeight;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppGlass.blurChrome,
          sigmaY: AppGlass.blurChrome,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppGlass.chromeFill,
            border: Border(bottom: BorderSide(color: AppGlass.border)),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: centerTitle,
            automaticallyImplyLeading: false,
            leading: leading,
            title: titleWidget ??
                (title == null
                    ? null
                    : Text(title!,
                        style: AppText.title(17, w: FontWeight.w600))),
            actions: actions,
            systemOverlayStyle: AppColors.isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
          ),
        ),
      ),
    );
  }
}

/// Shows [builder] inside a glass bottom sheet (blurred, rounded top, drag
/// handle). The sheet's own route background is transparent. [opaque]
/// swaps the translucent fill for the solid surface colour, for sheets that
/// carry dense controls over a busy backdrop.
Future<T?> showGlassSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool showDragHandle = true,
  bool isDismissible = true,
  bool opaque = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: AppColors.isDark ? 0.5 : 0.28),
    elevation: 0,
    builder: (sheetContext) {
      const top = BorderRadius.vertical(top: Radius.circular(AppRadii.xl));
      return GlassSurface(
        borderRadius: top,
        fill: opaque ? AppColors.surface : null,
        shadows: false,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDragHandle)
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textFaint.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              Flexible(child: builder(sheetContext)),
            ],
          ),
        ),
      );
    },
  );
}
