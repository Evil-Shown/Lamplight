import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Centers the app in a phone-sized column on wide screens (web/desktop).
class AppFrame extends StatelessWidget {
  const AppFrame({super.key, required this.child});

  final Widget child;

  static const maxWidth = 430.0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= maxWidth + 32) return child;

    return ColoredBox(
      color: AppColors.surfaceSunken,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.raised,
            ),
            child: ClipRect(child: child),
          ),
        ),
      ),
    );
  }
}
