import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'auth_style.dart';

/// Painted hero art for the auth flow. Both scenes are decorative and
/// deterministic, so they cost no assets and never shift between rebuilds.

/// A wall of bookshelves: colourful spines on wooden boards.
class ShelfScene extends StatelessWidget {
  const ShelfScene({super.key});

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
        child: SizedBox.expand(child: CustomPaint(painter: _ShelfPainter())),
      );
}

/// Top-down reading desk: striped green baize with a couple of books.
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
    Color(0xFF6B8544),
    Color(0xFFD9A441),
    Color(0xFFB5533C),
    Color(0xFF2F5D7C),
    Color(0xFFEDE3C8),
    Color(0xFF8C3B4A),
    Color(0xFF3F7F6B),
    Color(0xFFC77D3A),
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
          colors: [Color(0xFF2A4231), Color(0xFF182619)],
        ).createShader(rect),
    );

    const rowH = 96.0;
    final rng = _Lcg(7);
    final wood = Paint()..color = const Color(0xFFB07A45);
    final woodShade = Paint()..color = Colors.black.withValues(alpha: 0.28);
    final band = Paint()..color = Colors.white.withValues(alpha: 0.35);
    final edge = Paint()..color = Colors.black.withValues(alpha: 0.14);

    for (var top = -12.0; top < size.height; top += rowH) {
      final base = top + rowH - 10;
      var x = 4 + rng.next() * 10;
      while (x < size.width) {
        final w = 11 + rng.next() * 14;
        final h = 52 + rng.next() * 30;
        if (rng.next() < 0.1) {
          x += 18 + rng.next() * 20;
          continue;
        }
        final color = _spines[(rng.next() * _spines.length).floor() %
            _spines.length];
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
      canvas.drawRect(Rect.fromLTWH(0, base + 10, size.width, 6), woodShade);
    }
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
          colors: [Color(0xFF557A2F), Color(0xFF2E4219)],
        ).createShader(rect),
    );

    // Mown-stripe baize.
    final stripe = Paint()..color = Colors.white.withValues(alpha: 0.05);
    const band = 34.0;
    for (var y = 0.0; y < size.height; y += band * 2) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, band), stripe);
    }

    // Window-grille shadow across the top, like the net in a court photo.
    final grille = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..strokeWidth = 2.2;
    final grilleH = size.height * 0.26;
    for (var x = -grilleH; x < size.width + grilleH; x += 22) {
      canvas.drawLine(Offset(x, 0), Offset(x + grilleH, grilleH), grille);
      canvas.drawLine(Offset(x + grilleH, 0), Offset(x, grilleH), grille);
    }

    _book(
      canvas,
      center: Offset(size.width * 0.66, size.height * 0.31),
      size: Size(size.width * 0.34, size.width * 0.44),
      angle: -0.34,
      cover: const Color(0xFFD9E84A),
    );
    _book(
      canvas,
      center: Offset(size.width * 0.98, size.height * 0.43),
      size: Size(size.width * 0.3, size.width * 0.4),
      angle: 0.28,
      cover: const Color(0xFFE9C34A),
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
        ..color = Colors.black.withValues(alpha: 0.35)
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
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
    // Title lines.
    final line = Paint()..color = AuthPalette.forest.withValues(alpha: 0.55);
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
      Paint()..color = const Color(0xFFB5533C),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Darkens the bottom of a hero so white copy stays readable.
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
                Colors.black.withValues(alpha: 0.28),
                AuthPalette.forest.withValues(alpha: 0),
                AuthPalette.turf.withValues(alpha: 0.96),
              ],
            ),
          ),
          child: const SizedBox.expand(),
        ),
      );
}
