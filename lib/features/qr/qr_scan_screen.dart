import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

enum QrScanMode { seatCheckIn, bookPickup }

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({
    super.key,
    required this.mode,
    this.referenceCode,
  });

  final QrScanMode mode;
  final String? referenceCode;

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen>
    with SingleTickerProviderStateMixin {
  bool _scanned = false;

  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  String get _title => switch (widget.mode) {
        QrScanMode.seatCheckIn => 'Seat check-in',
        QrScanMode.bookPickup => 'Book pickup',
      };

  String get _instruction => switch (widget.mode) {
        QrScanMode.seatCheckIn =>
          'Point your camera at the QR code on your reading room seat to check in.',
        QrScanMode.bookPickup =>
          'Scan the pickup QR at the desk, or show this screen to library staff.',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(_title),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text(
              _instruction,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A2A20),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: AppShadows.glow,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (!_scanned) ...[
                          Icon(
                            Icons.qr_code_2_rounded,
                            size: 120,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          Positioned(top: 28, left: 28, child: _corner()),
                          Positioned(
                            top: 28,
                            right: 28,
                            child: Transform.rotate(angle: 1.5708, child: _corner()),
                          ),
                          Positioned(
                            bottom: 28,
                            left: 28,
                            child: Transform.rotate(angle: -1.5708, child: _corner()),
                          ),
                          Positioned(
                            bottom: 28,
                            right: 28,
                            child: Transform.rotate(angle: 3.14159, child: _corner()),
                          ),
                          AnimatedBuilder(
                            animation: _sweep,
                            builder: (context, _) {
                              final t =
                                  Curves.easeInOut.transform(_sweep.value);
                              return Align(
                                alignment: Alignment(0, -0.78 + 1.56 * t),
                                child: Container(
                                  height: 2.5,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        AppColors.accent,
                                        Colors.transparent,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.6),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ] else
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 48,
                                  color: AppColors.accent,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Verified',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              if (widget.referenceCode != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  widget.referenceCode!,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (widget.referenceCode != null)
              Text(
                'Reference: ${widget.referenceCode}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
                onPressed: () {
                  _sweep.stop();
                  setState(() => _scanned = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$_title successful')),
                  );
                },
                icon: Icon(_scanned ? Icons.check_rounded : Icons.qr_code_scanner_rounded),
                label: Text(_scanned ? 'Done' : 'Simulate scan'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Camera connects here when the backend is ready.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _corner() {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.accent, width: 4),
          left: BorderSide(color: AppColors.accent, width: 4),
        ),
      ),
    );
  }
}
