import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/navigation/app_route.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/firebase/firestore_service.dart';
import 'verification_result_screen.dart';

/// Bracket and sweep colour: white reads over any camera image.
const Color _frameColor = Colors.white;

/// P-14 Staff QR Scanner.
///
/// Full-bleed live camera with a framed scan window, and a glass control bar
/// (torch + the manual-code escape hatch). Every scanned or typed code is
/// verified against Firestore before the result screen is shown.
class StaffScannerScreen extends StatefulWidget {
  const StaffScannerScreen({super.key, this.embedded = false});

  /// True when shown as a shell tab (no back button); false when pushed.
  final bool embedded;

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
  String? _error;
  bool get _cameraSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    if (_cameraSupported) _camera = MobileScannerController();
  }

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
    if (mounted) setState(() {});
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    Map<String, dynamic>? result;
    try {
      result = await FirestoreService.instance.verifyCodeStrict(code);
    } on QrVerifyException catch (e) {
      if (!mounted) return;
      setState(() {
        _handling = false;
        _error = switch (e.failure) {
          QrVerifyFailure.network =>
            "You're offline. Check the connection and scan again.",
          QrVerifyFailure.permissionDenied =>
            "This account can't verify passes.",
          QrVerifyFailure.other =>
            'Could not verify this pass. Try again in a moment.',
        };
      });
      AppFeedback.error();
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _handling = false;
        _error = 'Could not verify this pass. Try again in a moment.';
      });
      AppFeedback.error();
      return;
    }
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
    // Park the sweep line when the user has animations turned off.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion && _sweep.isAnimating) {
      _sweep.stop();
    } else if (!reduceMotion && !_sweep.isAnimating) {
      _sweep.repeat(reverse: true);
    }

    return AppScaffold(
      title: 'Staff QR Scanner',
      showBack: !widget.embedded,
      contentUnderBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed camera, over a dark plate for the fallback.
          ColoredBox(color: AppColors.textPrimary),
          if (_camera != null)
            MobileScanner(
              controller: _camera,
              errorBuilder: (context, error) => const _CameraFallback(),
              onDetect: (capture) {
                final code = capture.barcodes.map((b) => b.rawValue).firstWhere(
                      (v) => v != null && v.trim().isNotEmpty,
                      orElse: () => null,
                    );
                if (code != null) _handleCode(code);
              },
            )
          else
            const _CameraFallback(),
          // Scan window: corner brackets plus a sweeping line. Nothing
          // covers the preview itself.
          Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const _ViewfinderFrame(),
                  AnimatedBuilder(
                    animation: _sweep,
                    builder: (context, _) => Align(
                      alignment: Alignment(0, -0.72 + 1.44 * _sweep.value),
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 30),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              _frameColor.withValues(alpha: 0.95),
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
          // State text on a glass pill so it reads over any camera image.
          Positioned(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            top: GlassAppBar.contentTopPadding(context) + AppSpacing.base,
            child: Align(
              alignment: Alignment.topCenter,
              child: GlassSurface(
                radius: AppRadii.full,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base, vertical: AppSpacing.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _handling
                          ? Icons.hourglass_top_rounded
                          : Icons.center_focus_strong_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        _handling
                            ? 'Verifying code…'
                            : 'Align the QR code inside the frame',
                        style: AppText.label(13.5,
                            w: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Glass control bar: manual entry and torch.
          Positioned(
            left: AppSpacing.base,
            right: AppSpacing.base,
            bottom: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: AppSpacing.base),
              child: StaggeredEntrance(
                child: GlassSurface(
                  radius: AppRadii.xl,
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _manualController,
                              keyboardType: TextInputType.text,
                              onSubmitted: _handleCode,
                              decoration: const InputDecoration(
                                hintText: 'Enter reservation code',
                                prefixIcon:
                                    Icon(Icons.keyboard_rounded, size: 20),
                              ),
                            ),
                          ),
                          if (_camera != null) ...[
                            const SizedBox(width: AppSpacing.md),
                            _TorchButton(controller: _camera),
                          ],
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Callout(
                          tone: CalloutTone.danger,
                          icon: Icons.error_outline_rounded,
                          message: _error!,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      PrimaryButton(
                        label: 'Verify Entered Code',
                        icon: Icons.qr_code_scanner_rounded,
                        onPressed: () => _handleCode(_manualController.text),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Camera access is used only for verification.',
                        textAlign: TextAlign.center,
                        style: AppText.body(11.5, color: AppColors.textFaint),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Torch toggle for the control bar. The local flag only mirrors the
/// intent; the camera owns the real torch state.
class _TorchButton extends StatefulWidget {
  const _TorchButton({required this.controller});

  final MobileScannerController? controller;

  @override
  State<_TorchButton> createState() => _TorchButtonState();
}

class _TorchButtonState extends State<_TorchButton> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    if (widget.controller == null) return const SizedBox.shrink();
    return Tooltip(
      message: _on ? 'Turn torch off' : 'Turn torch on',
      child: PressScale(
        feedback: PressFeedback.toggle,
        onTap: () {
          widget.controller!.toggleTorch();
          setState(() => _on = !_on);
        },
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _on
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Icon(
            _on ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            color: _on ? AppColors.textInverse : AppColors.primary,
          ),
        ),
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
              size: 148, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 12),
          Text(
            'Camera unavailable — use the manual code below',
            textAlign: TextAlign.center,
            style: AppText.body(
              12.5,
              color: Colors.white.withValues(alpha: 0.8),
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
    const color = _frameColor;
    const radius = BorderRadius.all(Radius.circular(10));

    Widget corner({
      required Border border,
      double? left,
      double? right,
      double? top,
      double? bottom,
    }) =>
        Positioned(
          left: left,
          right: right,
          top: top,
          bottom: bottom,
          child: Container(
            width: length,
            height: length,
            decoration: BoxDecoration(border: border, borderRadius: radius),
          ),
        );

    const side = BorderSide(color: color, width: thickness);
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        children: [
          corner(left: 0, top: 0, border: const Border(top: side, left: side)),
          corner(
              right: 0, top: 0, border: const Border(top: side, right: side)),
          corner(
              left: 0,
              bottom: 0,
              border: const Border(bottom: side, left: side)),
          corner(
              right: 0,
              bottom: 0,
              border: const Border(bottom: side, right: side)),
        ],
      ),
    );
  }
}
