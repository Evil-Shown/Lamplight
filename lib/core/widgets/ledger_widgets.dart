import 'package:flutter/material.dart';

import '../constants/app_constants.dart' hide AppSpacing;
import '../theme/app_theme.dart';

class CampusMark extends StatelessWidget {
  const CampusMark({super.key, this.size = 56, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.28);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: radius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.38),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      // Glass sheen across the top-left of the tile.
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0, 0.5],
          colors: [
            Colors.white.withValues(alpha: 0.30),
            Colors.white.withValues(alpha: 0),
          ],
        ),
      ),
      child: Text(
        AppStrings.appName.substring(0, 1).toUpperCase(),
        style: AppText.display(
          size * 0.42,
          w: FontWeight.w700,
          color: Colors.white,
          ls: -0.5,
        ),
      ),
    );
  }
}

/// Compact status pill used on check-in screens.
class StatePill extends StatelessWidget {
  const StatePill({
    super.key,
    required this.label,
    this.color,
    this.background,
    this.pulse = true,
  });

  final String label;
  final Color? color;
  final Color? background;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background ?? effectiveColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse) ...[
            Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: effectiveColor),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppText.label(
              11,
              w: FontWeight.w700,
              ls: 0.6,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
