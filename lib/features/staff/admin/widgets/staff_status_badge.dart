import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Semantic tones available to [StaffStatusBadge].
enum StaffBadgeTone { success, warning, danger, info, neutral }

/// Small status pill used across staff admin screens. Maps a semantic tone
/// to the app's semantic palette so labels stay color-consistent everywhere.
class StaffStatusBadge extends StatelessWidget {
  const StaffStatusBadge({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
    this.compact = false,
  });

  final String label;
  final StaffBadgeTone tone;
  final IconData? icon;
  final bool compact;

  Color get _color => switch (tone) {
        StaffBadgeTone.success => AppColors.success,
        StaffBadgeTone.warning => AppColors.warning,
        StaffBadgeTone.danger => AppColors.error,
        StaffBadgeTone.info => AppColors.info,
        StaffBadgeTone.neutral => AppColors.neutral,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 12 : 14, color: color),
            SizedBox(width: compact ? 3 : 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11 : 12,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
