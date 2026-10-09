import 'package:flutter/material.dart';

/// Misty pine forest painted behind the seat map: pale fog at the top, layers
/// of pines getting darker toward the front, and mossy ground with a couple of
/// rocks at the bottom. Decorative and deterministic, so it needs no assets.
///
/// Fills whatever space it is given; the trees are sized in logical pixels
/// (not as a fraction of the height) so they look the same on a short or tall
/// card.
class ForestScene extends StatelessWidget {
  const ForestScene({super.key});

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
        child: SizedBox.expand(child: CustomPaint(painter: _ForestPainter())),
      );
}

class _Pine {
  const _Pine(this.x, this.apexY, this.halfW, this.color);

  /// Horizontal centre as a fraction of the width.
  final double x;
  final double apexY;

  /// Widest half-width of the lowest tier.
  final double halfW;
  final Color color;
}

class _ForestPainter extends CustomPainter {
  const _ForestPainter();

  static const _far = [
    _Pine(0.06, 44, 22, Color(0xFF7FA46A)),
    _Pine(0.20, 56, 20, Color(0xFF86AA70)),
    _Pine(0.34, 40, 24, Color(0xFF7BA066)),
    _Pine(0.50, 58, 20, Color(0xFF86AA70)),
    _Pine(0.64, 42, 24, Color(0xFF7BA066)),
    _Pine(0.79, 54, 21, Color(0xFF86AA70)),
    _Pine(0.93, 46, 23, Color(0xFF7FA46A)),
  ];

  static const _mid = [
    _Pine(0.14, 30, 32, Color(0xFF4E8040)),
    _Pine(0.42, 20, 34, Color(0xFF477A3C)),
    _Pine(0.70, 28, 33, Color(0xFF4E8040)),
    _Pine(0.90, 22, 34, Color(0xFF477A3C)),
  ];

  static const _near = [
    _Pine(0.045, -6, 50, Color(0xFF2F6234)),
    _Pine(0.955, 2, 46, Color(0xFF2B5C31)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Sky and fog: pale yellow-green glow fading into deep forest green.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0, 0.22, 0.5, 1],
          colors: [
            Color(0xFF9DC278),
            Color(0xFFCADD9C),
            Color(0xFF4F7F3E),
            Color(0xFF1B4328),
          ],
        ).createShader(rect),
    );
    final glow = Offset(size.width * 0.5, 60);
    canvas.drawCircle(
      glow,
      size.width * 0.75,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFEAF3BE).withValues(alpha: 0.6),
          const Color(0xFFEAF3BE).withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: glow, radius: size.width * 0.75)),
    );

    for (final pine in _far) {
      _pine(canvas, size, pine, alpha: 0.7);
    }
    _fog(canvas, size, 0.30);
    for (final pine in _mid) {
      _pine(canvas, size, pine);
    }
    _fog(canvas, size, 0.16);
    for (final pine in _near) {
      _pine(canvas, size, pine);
    }

    _ground(canvas, size);

    // Soft vignette at the sides so the eye settles in the middle.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(colors: [
          Colors.black.withValues(alpha: 0.28),
          Colors.transparent,
          Colors.transparent,
          Colors.black.withValues(alpha: 0.28),
        ], stops: const [
          0,
          0.22,
          0.78,
          1
        ]).createShader(rect),
    );
  }

  /// A band of mist across the top that the trees behind it fade into.
  void _fog(Canvas canvas, Size size, double strength) {
    final band = Rect.fromLTWH(0, 0, size.width, 150);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFDDEBB0).withValues(alpha: strength),
            const Color(0xFFDDEBB0).withValues(alpha: 0),
          ],
        ).createShader(band),
    );
  }

  /// A fir: a trunk and stacked, scalloped tiers that widen toward the base.
  /// Drawn from the apex down to the bottom edge, so only the crown shows
  /// above whatever sits in front of it.
  void _pine(Canvas canvas, Size size, _Pine p, {double alpha = 1}) {
    final cx = size.width * p.x;
    const step = 30.0;
    final bottom = size.height + step;
    final tiers = ((bottom - p.apexY) / step).ceil();
    final paint = Paint()..color = p.color.withValues(alpha: alpha);
    final light = Paint()
      ..color = Colors.white.withValues(alpha: 0.10 * alpha);

    canvas.drawRect(
      Rect.fromLTWH(cx - p.halfW * 0.08, p.apexY, p.halfW * 0.16, bottom),
      Paint()..color = const Color(0xFF4A3A28).withValues(alpha: alpha),
    );

    for (var i = 0; i < tiers; i++) {
      final y0 = p.apexY + i * step;
      final grow = ((i + 1) / 6).clamp(0.0, 1.0);
      final hw = p.halfW * (0.3 + 0.7 * grow);
      final y1 = y0 + step * 1.5;
      final skirt = Path()
        ..moveTo(cx, y0)
        ..quadraticBezierTo(cx + hw * 0.55, y0 + step * 0.7, cx + hw, y1)
        ..quadraticBezierTo(cx + hw * 0.5, y1 - step * 0.28, cx, y1 - step * 0.1)
        ..quadraticBezierTo(cx - hw * 0.5, y1 - step * 0.28, cx - hw, y1)
        ..quadraticBezierTo(cx - hw * 0.55, y0 + step * 0.7, cx, y0)
        ..close();
      canvas.drawPath(skirt, paint);
      // Lit left flank.
      final lit = Path()
        ..moveTo(cx, y0)
        ..quadraticBezierTo(cx - hw * 0.55, y0 + step * 0.7, cx - hw, y1)
        ..quadraticBezierTo(cx - hw * 0.5, y1 - step * 0.28, cx, y1 - step * 0.1)
        ..close();
      canvas.drawPath(lit, light);
    }
  }

  void _ground(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    final moss = Path()
      ..moveTo(0, h)
      ..lineTo(0, h - 46)
      ..quadraticBezierTo(w * 0.22, h - 66, w * 0.45, h - 50)
      ..quadraticBezierTo(w * 0.72, h - 36, w, h - 58)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(moss, Paint()..color = const Color(0xFF2E5A2B));
    final mossLight = Path()
      ..moveTo(0, h)
      ..lineTo(0, h - 30)
      ..quadraticBezierTo(w * 0.3, h - 44, w * 0.6, h - 28)
      ..quadraticBezierTo(w * 0.85, h - 18, w, h - 34)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(mossLight, Paint()..color = const Color(0xFF3F7432));

    _rock(canvas, Offset(w * 0.11, h - 24), 28, 15);
    _rock(canvas, Offset(w * 0.88, h - 28), 36, 19);
    _rock(canvas, Offset(w * 0.30, h - 12), 18, 10);
  }

  void _rock(Canvas canvas, Offset c, double rx, double ry) {
    final body = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
    canvas.drawOval(
      body.shift(const Offset(2, 4)),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );
    canvas.drawOval(body, Paint()..color = const Color(0xFF858A80));
    canvas.drawOval(
      Rect.fromCenter(
          center: c.translate(-rx * 0.25, -ry * 0.3),
          width: rx * 1.1,
          height: ry * 0.9),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
    // A cap of moss.
    canvas.drawOval(
      Rect.fromCenter(
          center: c.translate(rx * 0.1, -ry * 0.75),
          width: rx * 1.4,
          height: ry * 0.7),
      Paint()..color = const Color(0xFF3F7432),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
