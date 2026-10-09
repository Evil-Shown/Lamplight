import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/shared_widgets.dart';

/// Compact action tile used in the staff admin dashboard quick-actions grid:
/// a frosted, tinted bento cell with a springy press.
class StaffQuickAction extends StatelessWidget {
  const StaffQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: FrostedCard(
        tint: color.withValues(alpha: AppColors.isDark ? 0.18 : 0.10),
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (badge != null && badge! > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(AppRadii.full),
                      ),
                      child: Text(
                        '$badge',
                        style: AppText.label(11,
                            w: FontWeight.w800, color: AppColors.textInverse),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.title(12.5, w: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
