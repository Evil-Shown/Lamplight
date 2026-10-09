import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/mock/mock_data.dart';
import '../../models/models.dart';

/// container-10 System Value Proposition.
///
/// The six capability cards the prototype uses to summarise what the
/// system does.
class ValuePropositionScreen extends StatelessWidget {
  const ValuePropositionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'About',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          AppSpacing.sm,
          AppSpacing.screenMargin,
          AppSpacing.xxl,
        ),
        children: [
          StaggeredEntrance(
            child: DepthHero(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WHAT LIBRARY+ DOES',
                    style: AppText.overline(
                      11,
                      color: AppColors.textInverse.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'One app for your seat, your books and your check-in.',
                    style: AppText.title(
                      24,
                      w: FontWeight.w800,
                      color: AppColors.textInverse,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          for (var i = 0; i < MockData.featureHighlights.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            StaggeredEntrance(
              index: i + 1,
              child: _FeatureCard(feature: MockData.featureHighlights[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final FeatureHighlight feature;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(
            icon: Icons.check_rounded,
            color: AppColors.success,
            background: AppColors.success.withValues(alpha: 0.12),
            size: 36,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: AppText.title(14.5, w: FontWeight.w700, height: 1.3),
                ),
                const SizedBox(height: 5),
                Text(
                  feature.body,
                  style: AppText.body(
                    13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
