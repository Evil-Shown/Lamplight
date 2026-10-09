import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auth_style.dart';
import 'library_scenes.dart';

/// Shared chrome for the two full-bleed intro slides.
class _IntroFrame extends StatelessWidget {
  const _IntroFrame({
    required this.scene,
    required this.scrimFrom,
    required this.body,
    required this.footer,
    this.topAction,
  });

  final Widget scene;
  final double scrimFrom;

  /// Headline and copy. Scrolls if the text size leaves no room.
  final Widget body;

  /// Dots and buttons. Always pinned to the bottom, never scrolled away.
  final Widget footer;
  final Widget? topAction;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AuthPalette.deep,
        body: Stack(
          fit: StackFit.expand,
          children: [
            scene,
            HeroScrim(from: scrimFrom),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      heightFactor: 1,
                      child: topAction ?? const SizedBox(height: 48),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) => SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(minHeight: box.maxHeight),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Rise(child: body),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    footer,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle _sub() => GoogleFonts.plusJakartaSans(
      fontSize: 13.5,
      height: 1.5,
      color: Colors.white.withValues(alpha: 0.82),
    );

/// Slide 1: the pitch, with Continue and Skip.
class IntroSlideScreen extends StatelessWidget {
  const IntroSlideScreen({
    super.key,
    required this.onContinue,
    required this.onSkip,
  });

  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return _IntroFrame(
      scene: const DeskScene(),
      scrimFrom: 0.38,
      topAction: TextButton(
        onPressed: onSkip,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
        ),
        child: Text(
          'Skip',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _TagChip(label: 'FIND YOUR STUDY SPOT'),
          const SizedBox(height: 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'STUDY\nBEYOND\nTHE SHELF',
              textAlign: TextAlign.center,
              style: AuthType.headline(46),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Reserve books, book a reading-room seat, and skip the '
            'queue. All from your phone.',
            textAlign: TextAlign.center,
            style: _sub(),
          ),
        ],
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: StepDots(count: 3, index: 0)),
          const SizedBox(height: 18),
          WhitePillButton(label: 'Continue', onPressed: onContinue),
        ],
      ),
    );
  }
}

/// Slide 2: pick sign in or register.
class IntroChooseScreen extends StatelessWidget {
  const IntroChooseScreen({
    super.key,
    required this.onSignIn,
    required this.onRegister,
    required this.onBack,
  });

  final VoidCallback onSignIn;
  final VoidCallback onRegister;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _IntroFrame(
      scene: const ShelfScene(),
      scrimFrom: 0.42,
      topAction: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          tooltip: 'Back',
          onPressed: onBack,
          color: Colors.white,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'FIND.\nBOOK.\nFOCUS.',
              textAlign: TextAlign.center,
              style: AuthType.headline(52),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Sign in to reserve seats, borrow books and check in with a '
            'QR ticket.',
            textAlign: TextAlign.center,
            style: _sub(),
          ),
        ],
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: StepDots(count: 3, index: 1)),
          const SizedBox(height: 18),
          WhitePillButton(
            label: 'Login with Email Address',
            icon: Icons.mail_outline_rounded,
            onPressed: onSignIn,
          ),
          const SizedBox(height: 12),
          WhitePillButton(
            label: 'Create a New Account',
            icon: Icons.person_add_alt_1_rounded,
            onPressed: onRegister,
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    const dots = [Color(0xFFD9A441), Color(0xFFB5533C), Color(0xFF2F5D7C)];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14.0 * dots.length + 10,
              height: 20,
              child: Stack(
                children: [
                  for (var i = 0; i < dots.length; i++)
                    Positioned(
                      left: i * 14.0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: dots[i],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.person_rounded,
                            size: 11, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
