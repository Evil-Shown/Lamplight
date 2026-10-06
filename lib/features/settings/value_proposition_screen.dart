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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          StaggeredEntrance(
            child: Text(
              'SYSTEM VALUE PROPOSITION',
              style: AppText.overline(11, color: AppColors.textFaint),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Core feature capabilities, business rules and architectural highlights',
            style: AppText.body(13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 22),
          for (var i = 0; i < MockData.featureHighlights.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            StaggeredEntrance(
              index: i,
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
          const Icon(Icons.check_circle_rounded,
              size: 19, color: AppColors.success),
          const SizedBox(width: 12),
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
