import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/shared_widgets.dart';

/// Summary tile for the staff admin dashboard: icon, big counting value,
/// label, optional tap.
class StaffStatCard extends StatelessWidget {
  const StaffStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = AppText.display(30, w: FontWeight.w800, ls: -1);
    final count = int.tryParse(value);
    final card = FrostedCard(
      tint: color.withValues(alpha: AppColors.isDark ? 0.14 : 0.08),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: AppSpacing.md),
          if (count != null)
            CountUp(value: count, style: style)
          else
            Text(value, style: style),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.label(12.5, w: FontWeight.w600),
          ),
        ],
      ),
    );
    return onTap == null ? card : PressScale(onTap: onTap!, child: card);
  }
}
