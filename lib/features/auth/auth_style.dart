import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fixed palette for the signed-out flow and the splash: warm dark wood,
/// cream paper and lamp-light amber. Deliberately independent of the app
/// theme, so it looks the same in light and dark mode.
class AuthPalette {
  AuthPalette._();

  /// Lamp-light amber: primary buttons, links, highlights.
  static const accent = Color(0xFFD99246);

  /// Near-black brown: text on amber, wordmark outline, deepest scrim.
  static const espresso = Color(0xFF140E0B);

  /// Dark walnut: backdrops and scrims.
  static const walnut = Color(0xFF2A1B12);

  /// Dark sheet the forms sit on.
  static const sheet = Color(0xFF1D1511);

  /// Paper cream: headlines, pills, text on the sheet.
  static const cream = Color(0xFFF3E8D6);
  static const onSheet = cream;
  static const fieldFill = Color(0xFF2B211B);
  static const muted = Color(0xFFB3A391);
  static const error = Color(0xFFFF9C8F);
  static const errorSoft = Color(0xFF3B1D19);
}

class AuthType {
  AuthType._();

  /// Heavy serif display face for headlines.
  static TextStyle headline(double size, {Color color = AuthPalette.cream}) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1.0,
        letterSpacing: -1.0,
        color: color,
      );
}

/// The "Library+" wordmark: cream serif letters with a dark outline, so it
/// reads over both the hero and the dark sheet.
class LibraryWordmark extends StatelessWidget {
  const LibraryWordmark({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.5,
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
                  ..strokeWidth = size * 0.26
                  ..strokeJoin = StrokeJoin.round
                  ..color = AuthPalette.espresso,
              ),
            ),
            Text('Library+', style: base.copyWith(color: AuthPalette.cream)),
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
      color: AuthPalette.cream,
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
                  Icon(icon, size: 19, color: AuthPalette.espresso),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AuthPalette.espresso,
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
