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
      backgroundColor: AppColors.inkDeep,
      appBar: AppBar(
        backgroundColor: AppColors.inkDeep,
        foregroundColor: AppColors.paper,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(_title, style: AppText.serif(22, color: AppColors.paper)),
        iconTheme: const IconThemeData(color: AppColors.paper),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Text(
              _instruction,
              style: AppText.sans(
                14.5,
                color: AppColors.paper.withValues(alpha: 0.72),
                height: 1.45,
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
                      color: const Color(0xFF0E1422),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.35),
                        width: 1.6,
                      ),
                      boxShadow: AppShadows.ink,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (!_scanned) ...[
                          Icon(
                            Icons.qr_code_2_rounded,
                            size: 120,
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                          const Positioned(top: 26, left: 26, child: _Bracket()),
                          Positioned(
                            top: 26,
                            right: 26,
                            child: Transform.rotate(
                              angle: 1.5708,
                              child: const _Bracket(),
                            ),
                          ),
                          Positioned(
                            bottom: 26,
                            left: 26,
                            child: Transform.rotate(
                              angle: -1.5708,
                              child: const _Bracket(),
                            ),
                          ),
                          Positioned(
                            bottom: 26,
                            right: 26,
                            child: Transform.rotate(
                              angle: 3.14159,
                              child: const _Bracket(),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _sweep,
                            builder: (context, _) {
                              final t = Curves.easeInOut.transform(_sweep.value);
                              return Align(
                                alignment: Alignment(0, -0.78 + 1.56 * t),
                                child: Container(
                                  height: 2.5,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        AppColors.gold.withValues(alpha: 0.9),
                                        Colors.transparent,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            AppColors.gold.withValues(alpha: 0.5),
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
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  gradient: AppGradients.foil,
                                  shape: BoxShape.circle,
                                  boxShadow: AppShadows.glow,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 46,
                                  color: AppColors.inkDeep,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Verified',
                                style: AppText.serif(
                                  24,
                                  color: AppColors.paper,
                                ),
                              ),
                              if (widget.referenceCode != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  widget.referenceCode!,
                                  style: AppText.mono(
                                    12,
                                    ls: 2.5,
                                    color: AppColors.goldSoft,
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
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  'REFERENCE · ${widget.referenceCode}',
                  style: AppText.mono(10.5, ls: 2.5,
                      color: AppColors.paper.withValues(alpha: 0.5)),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.paper,
                  foregroundColor: AppColors.ink,
                ),
                onPressed: () {
                  _sweep.stop();
                  setState(() => _scanned = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$_title successful')),
                  );
                },
                icon: Icon(
                  _scanned ? Icons.check_rounded : Icons.qr_code_scanner_rounded,
                ),
                label: Text(_scanned ? 'Done' : 'Simulate scan'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Camera connects here when the backend is ready.',
              style: AppText.sans(12,
                  color: AppColors.paper.withValues(alpha: 0.42)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Bracket extends StatelessWidget {
  const _Bracket();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.gold, width: 3.5),
          left: BorderSide(color: AppColors.gold, width: 3.5),
        ),
      ),
    );
  }
}
