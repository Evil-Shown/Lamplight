import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'auth_style.dart';

/// Painted hero art for the signed-out flow and splash. Every scene is
/// decorative and deterministic, so it costs no assets and never shifts
/// between rebuilds.

/// A warm wooden bookcase: leather spines, brass bands, and a reading lamp
/// glowing on the second shelf.
class ShelfScene extends StatelessWidget {
  const ShelfScene({super.key});

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
        child: SizedBox.expand(child: CustomPaint(painter: _ShelfPainter())),
      );
}

/// Top-down reading desk: dark walnut planks, a coffee cup and two books in
/// the pool of lamp light.
class DeskScene extends StatelessWidget {
  const DeskScene({super.key});

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
        child: SizedBox.expand(child: CustomPaint(painter: _DeskPainter())),
      );
}

class _Lcg {
  _Lcg(this._s);

  int _s;

  double next() {
    _s = (_s * 1103515245 + 12345) & 0x7fffffff;
    return _s / 0x80000000;
  }
}

class _ShelfPainter extends CustomPainter {
  const _ShelfPainter();

  static const _spines = [
    Color(0xFF2F4A3A),
    Color(0xFF7A2E2B),
    Color(0xFFB5733A),
    Color(0xFF4B3426),
    Color(0xFFE3D2B0),
    Color(0xFF22344C),
    Color(0xFF8E4B2A),
    Color(0xFF5A5F3A),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3B2516), Color(0xFF1B0F08)],
        ).createShader(rect),
    );

    const rowH = 96.0;
    const frame = 10.0;
    final rng = _Lcg(7);
    final wood = Paint()..color = const Color(0xFF8A5530);
    final woodLight = Paint()..color = const Color(0xFFB07A4A);
    final woodShade = Paint()..color = Colors.black.withValues(alpha: 0.35);
    final band = Paint()..color = const Color(0xFFE6C48A).withValues(alpha: 0.55);
    final edge = Paint()..color = Colors.black.withValues(alpha: 0.16);
    final lampX = size.width * 0.74;
    Offset? lampBase;

    var row = 0;
    for (var top = -12.0; top < size.height; top += rowH, row++) {
      final base = top + rowH - 10;
      final hasLamp = row == 1;
      var x = frame + 4 + rng.next() * 8;
      while (x < size.width - frame) {
        final w = 11 + rng.next() * 14;
        final h = 52 + rng.next() * 30;
        if (rng.next() < 0.1) {
          x += 18 + rng.next() * 20;
          continue;
        }
        final color = _spines[(rng.next() * _spines.length).floor() %
            _spines.length];
        if (hasLamp && (x - lampX).abs() < 34) {
          x += w + 1;
          continue;
        }
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(x, base - h, w, h),
            topLeft: const Radius.circular(2),
            topRight: const Radius.circular(2),
          ),
          Paint()..color = color,
        );
        canvas.drawRect(Rect.fromLTWH(x, base - h + 8, w, 3), band);
        canvas.drawRect(Rect.fromLTWH(x, base - 14, w, 2), band);
        canvas.drawRect(Rect.fromLTWH(x + w - 2.5, base - h, 2.5, h), edge);
        x += w + 1;
      }
      canvas.drawRect(Rect.fromLTWH(0, base, size.width, 10), wood);
      canvas.drawRect(Rect.fromLTWH(0, base, size.width, 2), woodLight);
      canvas.drawRect(Rect.fromLTWH(0, base + 10, size.width, 6), woodShade);
      if (hasLamp) lampBase = Offset(lampX, base);
    }

    // Side posts of the bookcase.
    final post = Paint()..color = const Color(0xFF6B4125);
    canvas.drawRect(Rect.fromLTWH(0, 0, frame, size.height), post);
    canvas.drawRect(
        Rect.fromLTWH(size.width - frame, 0, frame, size.height), post);

    if (lampBase != null) _lamp(canvas, lampBase);
  }

  void _lamp(Canvas canvas, Offset base) {
    final glowC = Offset(base.dx, base.dy - 34);
    canvas.drawCircle(
      glowC,
      150,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFFB45A).withValues(alpha: 0.45),
          const Color(0xFFFFB45A).withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: glowC, radius: 150)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx - 10, base.dy - 7, 20, 7),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF3A2314),
    );
    canvas.drawRect(
      Rect.fromLTWH(base.dx - 2, base.dy - 24, 4, 18),
      Paint()..color = const Color(0xFF3A2314),
    );
    final shade = Path()
      ..moveTo(base.dx - 11, base.dy - 56)
      ..lineTo(base.dx + 11, base.dy - 56)
      ..lineTo(base.dx + 22, base.dy - 24)
      ..lineTo(base.dx - 22, base.dy - 24)
      ..close();
    canvas.drawPath(shade, Paint()..color = const Color(0xFFF6CE8B));
    canvas.drawPath(
      shade,
      Paint()
        ..shader = LinearGradient(colors: [
          Colors.white.withValues(alpha: 0.35),
          Colors.transparent,
        ]).createShader(Rect.fromCenter(
            center: Offset(base.dx, base.dy - 40), width: 44, height: 32)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DeskPainter extends CustomPainter {
  const _DeskPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A2D1A), Color(0xFF22130B)],
        ).createShader(rect),
    );

    // Walnut planks with a little grain.
    const plank = 64.0;
    final rng = _Lcg(11);
    final seam = Paint()
      ..color = Colors.black.withValues(alpha: 0.38)
      ..strokeWidth = 2;
    final grain = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    var i = 0;
    for (var x = 0.0; x < size.width; x += plank, i++) {
      if (i.isOdd) {
        canvas.drawRect(Rect.fromLTWH(x, 0, plank, size.height),
            Paint()..color = Colors.white.withValues(alpha: 0.03));
      }
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), seam);
      for (var g = 0; g < 5; g++) {
        final gx = x + 8 + rng.next() * (plank - 16);
        final sway = (rng.next() - 0.5) * 14;
        canvas.drawPath(
          Path()
            ..moveTo(gx, 0)
            ..cubicTo(gx + sway, size.height * 0.3, gx - sway,
                size.height * 0.65, gx + sway * 0.5, size.height),
          grain,
        );
      }
    }

    // Pool of lamp light.
    final lightC = Offset(size.width * 0.78, size.height * 0.3);
    final lightR = size.width * 0.95;
    canvas.drawCircle(
      lightC,
      lightR,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFFB45A).withValues(alpha: 0.38),
          const Color(0xFFFFB45A).withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: lightC, radius: lightR)),
    );

    _cup(canvas, Offset(size.width * 0.2, size.height * 0.2));
    _book(
      canvas,
      center: Offset(size.width * 0.64, size.height * 0.33),
      size: Size(size.width * 0.34, size.width * 0.44),
      angle: -0.34,
      cover: const Color(0xFFB5532C),
    );
    _book(
      canvas,
      center: Offset(size.width * 0.98, size.height * 0.45),
      size: Size(size.width * 0.3, size.width * 0.4),
      angle: 0.28,
      cover: const Color(0xFF2F5A45),
    );
  }

  void _cup(Canvas canvas, Offset c) {
    canvas.drawCircle(
      c.translate(6, 10),
      36,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // Handle, then the cup and the coffee.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c.translate(38, 0), width: 22, height: 14),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0xFFEFE2CC),
    );
    canvas.drawCircle(c, 34, Paint()..color = const Color(0xFFEFE2CC));
    canvas.drawCircle(c, 27, Paint()..color = const Color(0xFFCDBBA0));
    canvas.drawCircle(c, 24, Paint()..color = const Color(0xFF3A1F10));
    canvas.drawCircle(
      c.translate(-7, -7),
      7,
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );
  }

  void _book(
    Canvas canvas, {
    required Offset center,
    required Size size,
    required double angle,
    required Color cover,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final r = Rect.fromCenter(
        center: Offset.zero, width: size.width, height: size.height);
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(10));

    canvas.drawRRect(
      rr.shift(const Offset(10, 16)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    // Page block peeking out below and to the right.
    canvas.drawRRect(
      rr.shift(const Offset(5, 6)),
      Paint()..color = AuthPalette.cream,
    );
    canvas.drawRRect(rr, Paint()..color = cover);
    // Spine.
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(r.left, r.top, size.width * 0.13, size.height),
        topLeft: const Radius.circular(10),
        bottomLeft: const Radius.circular(10),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );
    // Gilt title lines.
    final line = Paint()..color = const Color(0xFFE6C48A).withValues(alpha: 0.8);
    final lx = r.left + size.width * 0.26;
    final lw = size.width * 0.52;
    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
              lx, r.top + size.height * (0.2 + i * 0.09), lw * (1 - i * 0.18), 6),
          const Radius.circular(3),
        ),
        line,
      );
    }
    // Ribbon bookmark.
    canvas.drawRect(
      Rect.fromLTWH(r.right - size.width * 0.22, r.top, 8, size.height * 0.28),
      Paint()..color = AuthPalette.accent,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Darkens the bottom of a hero so cream copy stays readable.
class HeroScrim extends StatelessWidget {
  const HeroScrim({super.key, this.from = 0.35});

  /// Fraction of the height where the fade begins.
  final double from;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, math.min(from, 0.9), 1],
              colors: [
                Colors.black.withValues(alpha: 0.35),
                AuthPalette.espresso.withValues(alpha: 0),
                AuthPalette.espresso.withValues(alpha: 0.97),
              ],
            ),
          ),
          child: const SizedBox.expand(),
        ),
      );
}
