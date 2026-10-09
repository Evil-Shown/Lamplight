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
          _DesertBackdrop(dark: AppColors.isDark),
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
class _DesertBackdrop extends StatelessWidget {
  const _DesertBackdrop({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: _DesertPainter(dark: dark),
          ),
        ),
      );
}

class _DesertPainter extends CustomPainter {
  const _DesertPainter({required this.dark});

  final bool dark;

  // Lit top, base, and shadow colour for each dune, back to front.
  static const _litLight = [
    Color(0xFFF6CB98),
    Color(0xFFEFB67F),
    Color(0xFFE3A167),
    Color(0xFFD38C55),
  ];
  static const _baseLight = [
    Color(0xFFE6AE78),
    Color(0xFFDA9A64),
    Color(0xFFC7824F),
    Color(0xFFA96A3F),
  ];
  static const _shadeLight = [
    Color(0xFFB8733E),
    Color(0xFFA5643A),
    Color(0xFF8D4F2E),
    Color(0xFF6E3C22),
  ];

  static const _litDark = [
    Color(0xFF7A5238),
    Color(0xFF68442E),
    Color(0xFF55372A),
    Color(0xFF432B20),
  ];
  static const _baseDark = [
    Color(0xFF4A301F),
    Color(0xFF3D2819),
    Color(0xFF301F15),
    Color(0xFF24170F),
  ];
  static const _shadeDark = [
    Color(0xFF1D120C),
    Color(0xFF170E09),
    Color(0xFF120A06),
    Color(0xFF0C0604),
  ];

  // Per dune: left y, crest x, crest y, right y (all fractions).
  static const _dunes = [
    (0.70, 0.80, 0.645, 0.725),
    (0.755, 0.22, 0.695, 0.785),
    (0.83, 0.68, 0.765, 0.845),
    (0.91, 0.30, 0.85, 0.915),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final lit = dark ? _litDark : _litLight;
    final base = dark ? _baseDark : _baseLight;
    final shade = dark ? _shadeDark : _shadeLight;

    _sun(canvas, w, h);
    _buttes(canvas, w, h);

    for (var i = 0; i < _dunes.length; i++) {
      final (ly, cx, cy, ry) = _dunes[i];
      _dune(canvas, w, h, ly, cx, cy, ry, lit[i], base[i], shade[i], i);
    }

    _cactus(canvas, w, h);

    // Foreground depth: the page darkens slightly toward the bottom edge.
    final foot = Rect.fromLTWH(0, h * 0.82, w, h * 0.18);
    canvas.drawRect(
      foot,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2A1408).withValues(alpha: 0),
            const Color(0xFF2A1408).withValues(alpha: dark ? 0.55 : 0.3),
          ],
        ).createShader(foot),
    );
  }

  void _sun(Canvas canvas, double w, double h) {
    final c = Offset(w * 0.7, h * 0.625);
    final glowR = w * 0.5;
    canvas.drawCircle(
      c,
      glowR,
      Paint()
        ..shader = RadialGradient(colors: [
          (dark ? const Color(0xFFF0A35E) : const Color(0xFFFFF0D0))
              .withValues(alpha: dark ? 0.32 : 0.8),
          (dark ? const Color(0xFFF0A35E) : const Color(0xFFFFD79A))
              .withValues(alpha: dark ? 0.1 : 0.28),
          (dark ? const Color(0xFFF0A35E) : const Color(0xFFFFD79A))
              .withValues(alpha: 0),
        ], stops: const [
          0,
          0.35,
          1
        ]).createShader(Rect.fromCircle(center: c, radius: glowR)),
    );
    canvas.drawCircle(
      c,
      w * 0.072,
      Paint()
        ..color = (dark ? const Color(0xFFF5B574) : const Color(0xFFFFF4DC))
            .withValues(alpha: dark ? 0.7 : 0.95),
    );
  }

  /// Flat-topped rock buttes on the horizon, lit on the left, shaded on the
  /// right.
  void _buttes(Canvas canvas, double w, double h) {
    Path poly(List<(double, double)> pts) {
      final path = Path()..moveTo(w * pts.first.$1, h * pts.first.$2);
      for (final pt in pts.skip(1)) {
        path.lineTo(w * pt.$1, h * pt.$2);
      }
      return path..close();
    }

    final body = dark ? const Color(0xFF2E1D14) : const Color(0xFFC98A58);
    final side = dark ? const Color(0xFF1A0F0A) : const Color(0xFFA56A3E);

    final big = [
      (0.02, 0.73),
      (0.045, 0.655),
      (0.075, 0.645),
      (0.185, 0.645),
      (0.215, 0.665),
      (0.235, 0.73),
    ];
    canvas.drawPath(poly(big), Paint()..color = body);
    canvas.drawPath(
      poly([
        (0.14, 0.645),
        (0.185, 0.645),
        (0.215, 0.665),
        (0.235, 0.73),
        (0.15, 0.73),
      ]),
      Paint()..color = side,
    );

    final small = [
      (0.25, 0.73),
      (0.265, 0.685),
      (0.285, 0.678),
      (0.34, 0.678),
      (0.355, 0.7),
      (0.37, 0.73),
    ];
    canvas.drawPath(poly(small), Paint()..color = body);
    canvas.drawPath(
      poly([
        (0.315, 0.678),
        (0.34, 0.678),
        (0.355, 0.7),
        (0.37, 0.73),
        (0.31, 0.73),
      ]),
      Paint()..color = side,
    );
  }

  /// One dune: a lit windward slope, then a crisp crest and a shadowed lee.
  void _dune(Canvas canvas, double w, double h, double ly, double cx, double cy,
      double ry, Color lit, Color base, Color shade, int index) {
    final left = Offset(-w * 0.1, h * ly);
    final crest = Offset(w * cx, h * cy);
    final right = Offset(w * 1.1, h * ry);
    final rise = crest.dx - left.dx;
    final fall = right.dx - crest.dx;

    // The dune body.
    final body = Path()
      ..moveTo(left.dx, left.dy)
      ..cubicTo(left.dx + rise * 0.4, left.dy, crest.dx - rise * 0.32, crest.dy,
          crest.dx, crest.dy)
      ..cubicTo(crest.dx + fall * 0.05, crest.dy + (right.dy - crest.dy) * 0.55,
          right.dx - fall * 0.45, right.dy, right.dx, right.dy)
      ..lineTo(right.dx, h)
      ..lineTo(left.dx, h)
      ..close();
    final bounds = Rect.fromLTWH(0, h * (cy - 0.02), w, h);
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lit, base],
        ).createShader(bounds),
    );

    // The lee side in shadow: sharp along the crest, fading into the dune.
    final lee = Path()
      ..moveTo(crest.dx, crest.dy)
      ..cubicTo(crest.dx + fall * 0.05, crest.dy + (right.dy - crest.dy) * 0.55,
          right.dx - fall * 0.45, right.dy, right.dx, right.dy)
      ..lineTo(right.dx, right.dy + h * 0.1)
      ..cubicTo(right.dx - fall * 0.35, right.dy + h * 0.1, crest.dx + fall * 0.1,
          crest.dy + h * 0.1, crest.dx, crest.dy)
      ..close();
    final leeBox = Rect.fromLTRB(crest.dx, crest.dy, right.dx, right.dy + h * 0.1);
    canvas.drawPath(
      lee,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            shade.withValues(alpha: dark ? 0.85 : 0.7),
            shade.withValues(alpha: 0),
          ],
        ).createShader(leeBox),
    );

    // A thin warm rim along the crest where the sun grazes it.
    final rim = Path()
      ..moveTo(left.dx + rise * 0.45, left.dy + (crest.dy - left.dy) * 0.3)
      ..cubicTo(left.dx + rise * 0.6, left.dy + (crest.dy - left.dy) * 0.62,
          crest.dx - rise * 0.15, crest.dy + 0.5, crest.dx, crest.dy);
    canvas.drawPath(
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..color = (dark ? const Color(0xFFF0A35E) : const Color(0xFFFFE9C4))
            .withValues(alpha: dark ? 0.22 : 0.55),
    );
  }

  /// A saguaro on the nearest dune: dark body with a thin lit edge.
  void _cactus(Canvas canvas, double w, double h) {
    final x = w * 0.86;
    final base = h * 0.915;
    final ht = h * 0.1;
    final body = dark ? const Color(0xFF0C0604) : const Color(0xFF3D2314);
    final edge = (dark ? const Color(0xFFF0A35E) : const Color(0xFFFFD9A8))
        .withValues(alpha: dark ? 0.35 : 0.5);

    void shape(Paint paint, double dx) {
      final trunk = w * 0.026;
      final arm = w * 0.017;
      canvas.drawLine(
        Offset(x + dx, base),
        Offset(x + dx, base - ht),
        paint
          ..strokeWidth = trunk
          ..strokeCap = StrokeCap.round,
      );
      paint
        ..strokeWidth = arm
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(
        Path()
          ..moveTo(x + dx, base - ht * 0.42)
          ..lineTo(x + dx - w * 0.052, base - ht * 0.42)
          ..lineTo(x + dx - w * 0.052, base - ht * 0.7),
        paint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(x + dx, base - ht * 0.58)
          ..lineTo(x + dx + w * 0.046, base - ht * 0.58)
          ..lineTo(x + dx + w * 0.046, base - ht * 0.84),
        paint,
      );
    }

    shape(
      Paint()
        ..style = PaintingStyle.stroke
        ..color = edge,
      -1.6,
    );
    shape(
      Paint()
        ..style = PaintingStyle.stroke
        ..color = body,
      0,
    );
  }

  @override
  bool shouldRepaint(covariant _DesertPainter old) => old.dark != dark;
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
    var fillColor = fill ?? (blur != null && blur! >= AppGlass.blurChrome
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
        child: padding == null
            ? child
            : Padding(padding: padding!, child: child),
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
/// handle). The sheet's own route background is transparent.
Future<T?> showGlassSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool showDragHandle = true,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: AppColors.isDark ? 0.5 : 0.28),
    elevation: 0,
    builder: (sheetContext) {
      const top = BorderRadius.vertical(top: Radius.circular(AppRadii.xl));
      return GlassSurface(
        borderRadius: top,
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
