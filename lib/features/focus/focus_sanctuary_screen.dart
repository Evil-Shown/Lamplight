import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';

/// Zen Focus & Study Sanctuary screen inspired by Image 1 (Ekko and the Firefly canyon).
///
/// Provides a distraction-free Pomodoro study timer, ambient soundscapes,
/// floating fireflies, and quiet contemplative reading quotes.
class FocusSanctuaryScreen extends StatefulWidget {
  const FocusSanctuaryScreen({super.key});

  @override
  State<FocusSanctuaryScreen> createState() => _FocusSanctuaryScreenState();
}

class _FocusSanctuaryScreenState extends State<FocusSanctuaryScreen>
    with SingleTickerProviderStateMixin {
  static const int _defaultMinutes = 25;
  int _selectedDurationMinutes = _defaultMinutes;
  int _secondsRemaining = _defaultMinutes * 60;
  bool _isRunning = false;
  Timer? _timer;

  int _selectedSoundIndex = 0;
  bool _isSoundPlaying = true;

  final List<(String, IconData, String)> _soundscapes = const [
    ('Library Skylight Rain', Icons.water_drop_rounded, 'Soft droplets on glass'),
    ('Pine Forest Breeze', Icons.forest_rounded, 'Gentle canopy rustle'),
    ('Whispering Stacks', Icons.menu_book_rounded, 'Pages turning softly'),
    ('Hearth Lamplight', Icons.local_fire_department_rounded, 'Warm crackling ember'),
  ];

  final List<String> _quotes = const [
    '“In the quiet depths of study, clarity illuminates the mind.”',
    '“A room without books is like a body without a soul.” — Cicero',
    '“Stillness is where deep learning takes root.”',
    '“By the lamplight, every hour spent reading is a seed for tomorrow.”',
  ];
  int _quoteIndex = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    AppFeedback.tap();
    setState(() {
      if (_isRunning) {
        _timer?.cancel();
        _isRunning = false;
      } else {
        _isRunning = true;
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) return;
          if (_secondsRemaining > 0) {
            setState(() => _secondsRemaining--);
          } else {
            _timer?.cancel();
            _isRunning = false;
            AppFeedback.success();
            _nextQuote();
          }
        });
      }
    });
  }

  void _resetTimer() {
    AppFeedback.tap();
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsRemaining = _selectedDurationMinutes * 60;
    });
  }

  void _selectDuration(int minutes) {
    AppFeedback.tap();
    _timer?.cancel();
    setState(() {
      _selectedDurationMinutes = minutes;
      _secondsRemaining = minutes * 60;
      _isRunning = false;
    });
  }

  void _nextQuote() {
    setState(() {
      _quoteIndex = (_quoteIndex + 1) % _quotes.length;
    });
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1.0 -
        (_secondsRemaining / (_selectedDurationMinutes * 60).clamp(1, 999999));

    return Scaffold(
      backgroundColor: const Color(0xFF051014),
      body: Stack(
        children: [
          // Scenic Canyon Art Backdrop
          Positioned.fill(
            child: Opacity(
              opacity: 0.85,
              child: Image.asset(
                'assets/images/focus_canyon.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0A191E),
                        Color(0xFF051F20),
                        Color(0xFF051014),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Luminous Ambient Vignette
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                    const Color(0xFF051014).withValues(alpha: 0.92),
                  ],
                  stops: const [0.0, 0.4, 0.85],
                ),
              ),
            ),
          ),

          // Firefly Particles
          const Positioned.fill(
            child: IgnorePointer(
              child: _FireflyField(),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenMargin,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      PressScale(
                        onTap: () {
                          AppFeedback.tap();
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF163832).withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(AppRadii.full),
                          border: Border.all(
                            color: const Color(0xFF8EB69B).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF7EE0C3),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ZEN FOCUS',
                              style: AppText.overline(
                                11,
                                ls: 1.2,
                                color: const Color(0xFFDAF1DE),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // Quotes Banner
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenMargin * 1.5,
                  ),
                  child: PressScale(
                    onTap: _nextQuote,
                    child: Text(
                      _quotes[_quoteIndex],
                      textAlign: TextAlign.center,
                      style: AppText.serif(
                        14.5,
                        w: FontWeight.w400,
                        color: const Color(0xFFDAF1DE).withValues(alpha: 0.9),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // Luminous Circular Timer Dial
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Soft Glow Outer Ring
                        Container(
                          width: 210,
                          height: 210,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7EE0C3)
                                    .withValues(alpha: _isRunning ? 0.35 : 0.15),
                                blurRadius: 40,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),

                        // Dial Indicator
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 5,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.12),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF7EE0C3),
                            ),
                          ),
                        ),

                        // Time Display
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(_secondsRemaining),
                              style: AppText.display(
                                44,
                                w: FontWeight.w700,
                                color: Colors.white,
                                ls: -1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isRunning ? 'DEEP STUDY' : 'PAUSED',
                              style: AppText.overline(
                                11,
                                ls: 1.5,
                                color: const Color(0xFF8EB69B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Interval Chips (25 min, 45 min, 60 min)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final mins in [15, 25, 45, 60]) ...[
                        PressScale(
                          onTap: () => _selectDuration(mins),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedDurationMinutes == mins
                                  ? const Color(0xFF163832)
                                  : Colors.white.withValues(alpha: 0.08),
                              borderRadius:
                                  BorderRadius.circular(AppRadii.full),
                              border: Border.all(
                                color: _selectedDurationMinutes == mins
                                    ? const Color(0xFF7EE0C3)
                                    : Colors.white.withValues(alpha: 0.14),
                              ),
                            ),
                            child: Text(
                              '$mins m',
                              style: AppText.label(
                                12,
                                w: FontWeight.w700,
                                color: _selectedDurationMinutes == mins
                                    ? const Color(0xFFDAF1DE)
                                    : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                        if (mins != 60) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Play / Pause & Reset Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PressScale(
                      onTap: _resetTimer,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white70,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    PressScale(
                      onTap: _toggleTimer,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF235347), Color(0xFF7EE0C3)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7EE0C3)
                                  .withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: const Color(0xFF051014),
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    PressScale(
                      onTap: () {
                        setState(() => _isSoundPlaying = !_isSoundPlaying);
                        AppFeedback.tap();
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _isSoundPlaying
                              ? const Color(0xFF163832)
                              : Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isSoundPlaying
                                ? const Color(0xFF7EE0C3)
                                : Colors.transparent,
                          ),
                        ),
                        child: Icon(
                          _isSoundPlaying
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          color: _isSoundPlaying
                              ? const Color(0xFF7EE0C3)
                              : Colors.white70,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 1),

                // Ambient Soundscapes Carousel
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenMargin,
                    vertical: AppSpacing.sm,
                  ),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B2B26).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    border: Border.all(
                      color: const Color(0xFF163832),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.graphic_eq_rounded,
                            size: 16,
                            color: Color(0xFF7EE0C3),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'AMBIENT STUDY SOUNDSCAPE',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.overline(
                                11,
                                ls: 1.0,
                                color: const Color(0xFF8EB69B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_isSoundPlaying)
                            const _SoundWavesIndicator(),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (var i = 0; i < _soundscapes.length; i++) ...[
                              PressScale(
                                onTap: () {
                                  AppFeedback.tap();
                                  setState(() {
                                    _selectedSoundIndex = i;
                                    _isSoundPlaying = true;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedSoundIndex == i
                                        ? const Color(0xFF163832)
                                        : Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _selectedSoundIndex == i
                                          ? const Color(0xFF7EE0C3)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _soundscapes[i].$2,
                                        size: 16,
                                        color: _selectedSoundIndex == i
                                            ? const Color(0xFF7EE0C3)
                                            : Colors.white70,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _soundscapes[i].$1,
                                        style: AppText.label(
                                          12,
                                          w: _selectedSoundIndex == i
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: _selectedSoundIndex == i
                                              ? Colors.white
                                              : Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (i != _soundscapes.length - 1)
                                const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dynamic equalizer wave animation for playing ambient sound.
class _SoundWavesIndicator extends StatelessWidget {
  const _SoundWavesIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 4; i++) ...[
          Container(
            width: 3,
            height: (8 + (i % 3) * 5).toDouble(),
            decoration: BoxDecoration(
              color: const Color(0xFF7EE0C3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (i != 3) const SizedBox(width: 2.5),
        ],
      ],
    );
  }
}

/// Floating firefly glowing particles painter.
class _FireflyField extends StatefulWidget {
  const _FireflyField();

  @override
  State<_FireflyField> createState() => _FireflyFieldState();
}

class _FireflyFieldState extends State<_FireflyField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _FireflyPainter(_controller.value),
        );
      },
    );
  }
}

class _FireflyPainter extends CustomPainter {
  _FireflyPainter(this.phase);

  final double phase;

  static const _fireflies = [
    (0.2, 0.45, 0.0),
    (0.35, 0.60, 0.2),
    (0.65, 0.35, 0.5),
    (0.8, 0.50, 0.7),
    (0.48, 0.30, 0.4),
    (0.25, 0.75, 0.9),
    (0.72, 0.70, 0.3),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()..style = PaintingStyle.fill;

    for (final f in _fireflies) {
      final t = (phase + f.$3) % 1.0;
      final x = f.$1 * size.width + (t * 20 - 10);
      final y = f.$2 * size.height - (t * 40);
      final alpha = ((0.5 + 0.5 * (1.0 - (t - 0.5).abs() * 2))).clamp(0.0, 1.0);

      glowPaint.color = const Color(0xFF7EE0C3).withValues(alpha: alpha * 0.4);
      canvas.drawCircle(Offset(x, y), 6, glowPaint);

      glowPaint.color = const Color(0xFFFAFCEE).withValues(alpha: alpha * 0.85);
      canvas.drawCircle(Offset(x, y), 2.5, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_FireflyPainter oldDelegate) => true;
}
