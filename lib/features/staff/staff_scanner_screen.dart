import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import 'verification_result_screen.dart';

/// P-14 Staff QR Scanner.
///
/// The scan surface with a viewfinder and sweep, plus the manual code
/// entry escape hatch. Camera capture is still stubbed — the prototype
/// notes that too.
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

  @override
  void dispose() {
    _sweep.dispose();
    _manualController.dispose();
    super.dispose();
  }

  void _scan() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VerificationResultScreen()),
    );
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
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.qr_code_2_rounded,
                        size: 168,
                        color: Colors.white.withValues(alpha: 0.07)),
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
            decoration: const InputDecoration(
              hintText: 'Enter reservation code instead',
              prefixIcon: Icon(Icons.keyboard_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Scan Reservation QR',
            icon: Icons.qr_code_scanner_rounded,
            onPressed: _scan,
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

/// The four corner brackets that frame the scan area.
class _ViewfinderFrame extends StatelessWidget {
  const _ViewfinderFrame();

  @override
  Widget build(BuildContext context) {
    const length = 34.0;
    const thickness = 3.5;
    const color = AppColors.primary;
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
              decoration: const BoxDecoration(
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
              decoration: const BoxDecoration(
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
              decoration: const BoxDecoration(
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
              decoration: const BoxDecoration(
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
