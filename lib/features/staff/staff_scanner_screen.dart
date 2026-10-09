import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/navigation/app_route.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/firebase/firestore_service.dart';
import 'verification_result_screen.dart';

/// P-14 Staff QR Scanner.
///
/// Live camera capture with the branded viewfinder on top, plus the
/// manual-code escape hatch. Every scanned or typed code is verified
/// against Firestore before the result screen is shown.
class StaffScannerScreen extends StatefulWidget {
  const StaffScannerScreen({super.key});

  @override
  State<StaffScannerScreen> createState() => _StaffScannerScreenState();
}

class _StaffScannerScreenState extends State<StaffScannerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat(reverse: true);

  final _manualController = TextEditingController();
  MobileScannerController? _camera;
  bool _handling = false;
  bool get _cameraSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void dispose() {
    _sweep.dispose();
    _manualController.dispose();
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _handleCode(String code) async {
    if (_handling || code.trim().isEmpty) return;
    _handling = true;
    FocusScope.of(context).unfocus();
    final result = await FirestoreService.instance.verifyCode(code);
    if (!mounted) return;
    AppRoute.push(
      context,
      VerificationResultScreen(
        code: code.trim(),
        result: result,
      ),
    ).then((_) {
      if (mounted) setState(() => _handling = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Staff QR Scanner',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Text(
            'Scan a student reservation pass',
            textAlign: TextAlign.center,
            style: AppText.body(13.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 22),
          StaggeredEntrance(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    if (_cameraSupported)
                      MobileScanner(
                        controller: _camera ??= MobileScannerController(),
                        errorBuilder: (context, error) => const _CameraFallback(),
                        onDetect: (capture) {
                          final code = capture.barcodes
                              .map((b) => b.rawValue)
                              .firstWhere(
                                (v) => v != null && v.trim().isNotEmpty,
                                orElse: () => null,
                              );
                          if (code != null) _handleCode(code);
                        },
                      )
                    else
                      const _CameraFallback(),
                    const _ViewfinderFrame(),
                    AnimatedBuilder(
                      animation: _sweep,
                      builder: (context, _) => Align(
                        alignment: Alignment(0, -0.72 + 1.44 * _sweep.value),
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 46),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.primary.withValues(alpha: 0.9),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Align the QR code inside the frame',
            textAlign: TextAlign.center,
            style: AppText.body(13, color: AppColors.textFaint),
          ),
          const SizedBox(height: 28),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: SectionLabel('Manual option'),
          ),
          TextField(
            controller: _manualController,
            keyboardType: TextInputType.text,
            onSubmitted: _handleCode,
            decoration: const InputDecoration(
              hintText: 'Enter reservation code instead',
              prefixIcon: Icon(Icons.keyboard_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Verify Entered Code',
            icon: Icons.qr_code_scanner_rounded,
            onPressed: () => _handleCode(_manualController.text),
          ),
          const SizedBox(height: 14),
          Text(
            'Camera access is used only for verification.',
            textAlign: TextAlign.center,
            style: AppText.body(11.5, color: AppColors.textFaint),
          ),
        ],
      ),
    );
  }
}

/// Shown when the camera is unavailable (desktop, simulator, permission
/// denied) — the manual code path always works.
class _CameraFallback extends StatelessWidget {
  const _CameraFallback();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_2_rounded,
              size: 148, color: Colors.white.withValues(alpha: 0.07)),
          const SizedBox(height: 12),
          Text(
            'Camera unavailable — use the manual code below',
            textAlign: TextAlign.center,
            style: AppText.body(
              12.5,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

/// The four corner brackets that frame the scan area.
class _ViewfinderFrame extends StatelessWidget {
  const _ViewfinderFrame();

  @override
  Widget build(BuildContext context) {
    const length = 34.0;
    const thickness = 3.5;
    final color = AppColors.primary;
    const radius = BorderRadius.all(Radius.circular(10));

    return SizedBox(
      width: 216,
      height: 216,
      child: Stack(
        children: [
          // top-left
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: length,
              height: length,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: color, width: thickness),
                  left: BorderSide(color: color, width: thickness),
                ),
                borderRadius: radius,
              ),
            ),
          ),
          // top-right
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: length,
              height: length,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: color, width: thickness),
                  right: BorderSide(color: color, width: thickness),
                ),
                borderRadius: radius,
              ),
            ),
          ),
          // bottom-left
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: length,
              height: length,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: color, width: thickness),
                  left: BorderSide(color: color, width: thickness),
                ),
                borderRadius: radius,
              ),
            ),
          ),
          // bottom-right
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: length,
              height: length,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: color, width: thickness),
                  right: BorderSide(color: color, width: thickness),
                ),
                borderRadius: radius,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
