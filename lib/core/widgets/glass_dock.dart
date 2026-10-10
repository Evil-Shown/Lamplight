import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass.dart';
import 'shared_widgets.dart';

/// Floating glass bottom navigation dock (Liquid Glass Campus): a blurred
/// pill with a spring-driven active indicator that slides behind the
/// selected item.
class GlassDock extends StatelessWidget {
  const GlassDock({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<GlassDockDestination> destinations;

  static const height = 72.0;
  static const bottomInset = 12.0;
  static const horizontalInset = 16.0;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final dark = AppColors.isDark;
    final accent = dark ? AppColors.scheme.primary : AppColors.primary;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalInset,
        0,
        horizontalInset,
        bottomInset + bottom,
      ),
      child: GlassSurface(
        radius: 28,
        fill: AppGlass.dockFillFor(dark),
        child: SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / destinations.length;
              return Stack(
                children: [
                  // Sliding / morphing active pill.
                  AnimatedPositioned(
                    duration: reduced ? Duration.zero : AppMotion.entranceSettle,
                    curve: AppMotion.springEntrance,
                    left: selectedIndex * itemWidth + 4,
                    width: itemWidth - 8,
                    top: 8,
                    bottom: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: dark ? 0.30 : 0.26),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: accent.withValues(alpha: dark ? 0.55 : 0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: dark ? 0.30 : 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < destinations.length; i++)
                        Expanded(
                          child: _DockItem(
                            destination: destinations[i],
                            selected: i == selectedIndex,
                            accent: accent,
                            onTap: () {
                              if (i != selectedIndex) onSelected(i);
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class GlassDockDestination {
  const GlassDockDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.destination,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final GlassDockDestination destination;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final inactive =
        AppColors.isDark ? AppColors.textSecondary : AppColors.textPrimary;
    return PressScale(
      onTap: onTap,
      scale: 0.94,
      feedback: selected ? PressFeedback.none : PressFeedback.select,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: selected ? 1.12 : 1.0),
            duration: reduced ? Duration.zero : AppMotion.entranceSettle,
            curve: AppMotion.springEntrance,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Icon(
              selected ? destination.selectedIcon : destination.icon,
              size: 22,
              color: selected ? accent : inactive,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: AppMotion.fast,
            curve: Curves.easeOutCubic,
            style: AppText.label(
              10,
              w: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? AppColors.textPrimary : inactive,
            ),
            child: Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
