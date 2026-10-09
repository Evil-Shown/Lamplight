import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fixed palette for the signed-out flow. Deliberately independent of the
/// app theme: the intro slides and the sheet are always the same
/// library-green look, light or dark.
class AuthPalette {
  AuthPalette._();

  static const olive = Color(0xFF6B8544);
  static const forest = Color(0xFF1F2B14);
  static const turf = Color(0xFF34491D);
  static const cream = Color(0xFFF7F4E9);
  static const field = Color(0xFFF4F4F1);
  static const ink = Color(0xFF1B1F16);
  static const muted = Color(0xFF6D7266);
  static const error = Color(0xFFB3261E);
  static const errorSoft = Color(0xFFFDECEA);
}

class AuthType {
  AuthType._();

  /// Heavy, tight display face for the slide headlines.
  static TextStyle headline(double size, {Color color = Colors.white}) =>
      GoogleFonts.outfit(
        fontSize: size,
        fontWeight: FontWeight.w900,
        height: 1.0,
        letterSpacing: -1.2,
        color: color,
      );
}

/// The "Library+" wordmark: chunky dark-green letters with a cream outline
/// so it reads over both the hero and the white sheet.
class LibraryWordmark extends StatelessWidget {
  const LibraryWordmark({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.lilitaOne(
      fontSize: size,
      letterSpacing: 0.4,
      height: 1,
    );
    return Semantics(
      label: 'Library+',
      child: ExcludeSemantics(
        child: Stack(
          children: [
            Text(
              'Library+',
              style: base.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = size * 0.3
                  ..strokeJoin = StrokeJoin.round
                  ..color = AuthPalette.cream,
              ),
            ),
            Text('Library+', style: base.copyWith(color: AuthPalette.forest)),
          ],
        ),
      ),
    );
  }
}

/// Page-position dots: the active one stretches into a pill.
class StepDots extends StatelessWidget {
  const StepDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step ${index + 1} of $count',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == index ? 20 : 8,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: i == index ? 1 : 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Full-width white pill used on the dark hero slides.
class WhitePillButton extends StatelessWidget {
  const WhitePillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const StadiumBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 19, color: AuthPalette.ink),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AuthPalette.ink,
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

/// Fades and lifts its child in once.
class Rise extends StatelessWidget {
  const Rise({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: still ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 18 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}

/// The multicolour Google "G" (drawn, so no asset is needed).
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: const CustomPaint(painter: _GooglePainter()),
      );
}

class _GooglePainter extends CustomPainter {
  const _GooglePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);

    canvas.drawArc(
        rect, -0.5, 1.8, true, Paint()..color = const Color(0xFFEA4335));
    canvas.drawArc(
        rect, 1.3, 1.2, true, Paint()..color = const Color(0xFF34A853));
    canvas.drawArc(
        rect, 2.5, 0.8, true, Paint()..color = const Color(0xFFFBBC05));
    canvas.drawArc(
        rect, 3.3, 1.5, true, Paint()..color = const Color(0xFF4285F4));
    canvas.drawCircle(
      Offset(w / 2, h / 2),
      w * 0.32,
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.45, h * 0.38, w * 0.48, h * 0.24),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
