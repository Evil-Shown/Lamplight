import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/mock/mock_data.dart';
import '../../models/models.dart';

/// The filter state the seat map applies, and the sheet that edits it.
class SeatFilters {
  const SeatFilters({
    this.floor = 'Floor 2',
    this.categories = const {},
    this.powerOutlet = false,
    this.monitor = false,
    this.standingDesk = false,
  });

  final String floor;
  final Set<SeatCategory> categories;
  final bool powerOutlet;
  final bool monitor;
  final bool standingDesk;

  bool get isDefault =>
      floor == 'Floor 2' &&
      categories.isEmpty &&
      !powerOutlet &&
      !monitor &&
      !standingDesk;

  bool matches(Seat seat) {
    final floorNumber = int.tryParse(floor.replaceAll(RegExp(r'[^0-9]'), ''));
    if (floorNumber != null && seat.floor != floorNumber) return false;
    if (categories.isNotEmpty && !categories.contains(seat.category)) {
      return false;
    }
    if (powerOutlet && !seat.hasPowerOutlet) return false;
    if (monitor && !seat.hasMonitor) return false;
    if (standingDesk && !seat.standingDesk) return false;
    return true;
  }

  SeatFilters copyWith({
    String? floor,
    Set<SeatCategory>? categories,
    bool? powerOutlet,
    bool? monitor,
    bool? standingDesk,
  }) =>
      SeatFilters(
        floor: floor ?? this.floor,
        categories: categories ?? this.categories,
        powerOutlet: powerOutlet ?? this.powerOutlet,
        monitor: monitor ?? this.monitor,
        standingDesk: standingDesk ?? this.standingDesk,
      );
}

/// P-06A Seat Filters.
///
/// A glass sheet over the seat map: floor selector, study-area and
/// facility chips, with reset and apply.
class SeatFilterSheet extends StatefulWidget {
  const SeatFilterSheet({super.key, required this.initial});

  final SeatFilters initial;

  static Future<SeatFilters?> show(BuildContext context, SeatFilters initial) {
    return showGlassSheet<SeatFilters>(
      context,
      opaque: true,
      builder: (_) => SeatFilterSheet(initial: initial),
    );
  }

  @override
  State<SeatFilterSheet> createState() => _SeatFilterSheetState();
}

class _SeatFilterSheetState extends State<SeatFilterSheet> {
  late SeatFilters _filters = widget.initial;

  void _toggleCategory(SeatCategory category) {
    final next = Set<SeatCategory>.from(_filters.categories);
    if (!next.remove(category)) next.add(category);
    setState(() => _filters = _filters.copyWith(categories: next));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filters',
                style: AppText.display(22, w: FontWeight.w700, ls: -0.3)),
            const SizedBox(height: AppSpacing.lg),
            SectionLabel('Floor', color: AppColors.textSecondary),
            const SizedBox(height: 10),
            SegmentedTabs(
              options: MockData.floors,
              selected: _filters.floor,
              onSelected: (value) =>
                  setState(() => _filters = _filters.copyWith(floor: value)),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionLabel('Study area', color: AppColors.textSecondary),
            const SizedBox(height: 10),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _ToggleChip(
                  label: 'Quiet Zone',
                  icon: Icons.volume_off_rounded,
                  value: _filters.categories.contains(SeatCategory.quietZone),
                  onChanged: (_) => _toggleCategory(SeatCategory.quietZone),
                ),
                _ToggleChip(
                  label: 'Collaborative Space',
                  icon: Icons.groups_rounded,
                  value:
                      _filters.categories.contains(SeatCategory.collaborative),
                  onChanged: (_) => _toggleCategory(SeatCategory.collaborative),
                ),
                _ToggleChip(
                  label: 'Individual Pod',
                  icon: Icons.person_rounded,
                  value:
                      _filters.categories.contains(SeatCategory.individualPod),
                  onChanged: (_) => _toggleCategory(SeatCategory.individualPod),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionLabel('Facilities', color: AppColors.textSecondary),
            const SizedBox(height: 10),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _ToggleChip(
                  label: 'Power Outlet',
                  icon: Icons.power_rounded,
                  value: _filters.powerOutlet,
                  onChanged: (v) => setState(
                      () => _filters = _filters.copyWith(powerOutlet: v)),
                ),
                _ToggleChip(
                  label: 'Monitor Screen',
                  icon: Icons.monitor_rounded,
                  value: _filters.monitor,
                  onChanged: (v) =>
                      setState(() => _filters = _filters.copyWith(monitor: v)),
                ),
                _ToggleChip(
                  label: 'Standing Desk',
                  icon: Icons.height_rounded,
                  value: _filters.standingDesk,
                  onChanged: (v) => setState(
                      () => _filters = _filters.copyWith(standingDesk: v)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Reset',
                    tone: ButtonTone.neutral,
                    onPressed: () =>
                        setState(() => _filters = const SeatFilters()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    label: 'Apply Filters',
                    onPressed: () => Navigator.of(context).pop(_filters),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A pill that toggles a filter: filled with the primary colour and a
/// check when on, so the
/// state never rests on colour alone. Fires a toggle cue itself.
class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: value,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        feedback: PressFeedback.toggle,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.enter,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: value
                ? AppColors.primary.withValues(alpha: 0.14)
                : AppGlass.cardFill,
            borderRadius: BorderRadius.circular(AppRadii.full),
            border: Border.all(
              color: value ? AppColors.primary : AppGlass.border,
              width: value ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(value ? Icons.check_rounded : icon,
                  size: 16,
                  color:
                      value ? AppColors.textInverse : AppColors.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: AppText.label(
                    13.5,
                    w: value ? FontWeight.w700 : FontWeight.w500,
                    color: value ? AppColors.textInverse : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
