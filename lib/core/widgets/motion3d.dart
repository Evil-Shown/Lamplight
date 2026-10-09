import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A small 3D motion vocabulary: perspective tilt, card flip and idle
/// float. All three are depth cues — they explain layers and invite
/// touch, they never loop for decoration (only [Float3D] loops, and it
/// collapses to a static pose under reduce-motion).
///
/// Every widget reads `MediaQuery.disableAnimationsOf` so the system
/// reduce-motion setting stills everything, per the design spec (§3.11).

/// Perspective tilt that follows the pointer. Tilts up to [maxTilt]
/// around X/Y with a real perspective matrix and eases back to rest
/// when the pointer leaves. A no-op on touch-only devices where no
/// hover ever fires.
class Tilt3D extends StatefulWidget {
  const Tilt3D({
    super.key,
    required this.child,
    this.maxTilt = 0.10,
    this.perspective = 0.008,
    this.lift = 6,
    this.enabled = true,
  });

  final Widget child;

  /// Radians of tilt at the far edge.
  final double maxTilt;

  /// Perspective factor — smaller is deeper.
  final double perspective;

  /// Simulated z-lift in px while tilted (shadow-free depth cue).
  final double lift;

  final bool enabled;

  @override
  State<Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<Tilt3D> {
  Offset _target = Offset.zero;
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
    return MouseRegion(
      onHover: (event) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) return;
        final local = event.localPosition;
        final size = box.size;
        // Normalised -1..1 from the centre.
        _target = Offset(
          (local.dx / size.width - 0.5) * 2,
          (local.dy / size.height - 0.5) * 2,
        );
        if (!_hovering) setState(() => _hovering = true);
      },
      onExit: (_) {
        _target = Offset.zero;
        if (_hovering) setState(() => _hovering = false);
      },
      child: TweenAnimationBuilder<Offset>(
        tween: Tween(end: _target),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          final tiltX = value.dy * widget.maxTilt;
          final tiltY = -value.dx * widget.maxTilt;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, -widget.perspective)
              ..rotateX(tiltX)
              ..rotateY(tiltY)
              ..translateByDouble(0.0, -value.dy.abs() * widget.lift, 0.0, 1.0),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// A tap-to-flip card: true Y-axis rotation between a [front] and a
/// [back] child. The back face is pre-mirrored so text reads correctly
/// at 180°. Tapping anywhere flips; reduce-motion swaps instantly.
class Flip3D extends StatefulWidget {
  const Flip3D({
    super.key,
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 420),
    this.perspective = 0.006,
    this.autoFlip,
  });

  final Widget front;
  final Widget back;
  final Duration duration;
  final double perspective;

  /// When non-null the card flips itself back and forth on this interval
  /// until the user taps it once.
  final Duration? autoFlip;

  @override
  State<Flip3D> createState() => _Flip3DState();
}

class _Flip3DState extends State<Flip3D>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  bool _flipped = false;
  bool _userTookOver = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoFlip != null) {
      Future.doWhile(() async {
        await Future<void>.delayed(widget.autoFlip!);
        if (!mounted || _userTookOver) return false;
        if (!_flipped) {
          _controller.forward();
          _flipped = true;
        } else {
          _controller.reverse();
          _flipped = false;
        }
        return true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    _userTookOver = true;
    setState(() {
      _flipped = !_flipped;
      _flipped ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      return GestureDetector(
        onTap: _toggle,
        child: _flipped ? widget.back : widget.front,
      );
    }
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final showBack = t >= 0.5;
          final face = showBack ? widget.back : widget.front;
          Widget content = Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, -widget.perspective)
              ..rotateY(t * math.pi),
            child: face,
          );
          if (showBack) {
            // Pre-mirror the back face so it reads correctly at 180°.
            content = Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(math.pi),
              child: content,
            );
          }
          return content;
        },
      ),
    );
  }
}

/// A gentle idle float: the child hovers a few pixels up and down with a
/// whisper of X-rotation, as if resting on air. Only loop allowed by the
/// spec's motion tokens (used sparingly: splash mark, empty states).
class Float3D extends StatefulWidget {
  const Float3D({
    super.key,
    required this.child,
    this.distance = 5,
    this.wobble = 0.045,
    this.period = const Duration(milliseconds: 3200),
  });

  final Widget child;

  /// Vertical travel in px.
  final double distance;

  /// Radians of X-rotation wobble.
  final double wobble;
  final Duration period;

  @override
  State<Float3D> createState() => _Float3DState();
}

class _Float3DState extends State<Float3D>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, -0.01)
            ..rotateX(widget.wobble * (t - 0.5) * 2)
            ..translateByDouble(0.0, -t * widget.distance, 0.0, 1.0),
          child: child,
        );
      },
    );
  }
}
