import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
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
/// A modal sheet over the seat map: floor selector, study-area checkboxes,
/// and facility toggles, with reset and apply.
class SeatFilterSheet extends StatefulWidget {
  const SeatFilterSheet({super.key, required this.initial});

  final SeatFilters initial;

  static Future<SeatFilters?> show(BuildContext context, SeatFilters initial) {
    return showModalBottomSheet<SeatFilters>(
      context: context,
      isScrollControlled: true,
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Filters',
                    style: AppText.display(20, w: FontWeight.w700, ls: -0.3)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, size: 20),
                  onPressed: () => setState(
                    () => _filters = const SeatFilters(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SectionLabel('Floor'),
            const SizedBox(height: 10),
            SegmentedTabs(
              options: MockData.floors,
              selected: _filters.floor,
              onSelected: (value) =>
                  setState(() => _filters = _filters.copyWith(floor: value)),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 22),
            const SectionLabel('Study area'),
            const SizedBox(height: 6),
            _CheckRow(
              label: 'Quiet Zone',
              value: _filters.categories.contains(SeatCategory.quietZone),
              onChanged: (_) => _toggleCategory(SeatCategory.quietZone),
            ),
            _CheckRow(
              label: 'Collaborative Space',
              value: _filters.categories.contains(SeatCategory.collaborative),
              onChanged: (_) => _toggleCategory(SeatCategory.collaborative),
            ),
            _CheckRow(
              label: 'Individual Pod',
              value: _filters.categories.contains(SeatCategory.individualPod),
              onChanged: (_) => _toggleCategory(SeatCategory.individualPod),
            ),
            const SizedBox(height: 18),
            const SectionLabel('Facilities'),
            const SizedBox(height: 6),
            _CheckRow(
              label: 'Power Outlet',
              value: _filters.powerOutlet,
              onChanged: (v) =>
                  setState(() => _filters = _filters.copyWith(powerOutlet: v)),
            ),
            _CheckRow(
              label: 'Monitor Screen',
              value: _filters.monitor,
              onChanged: (v) =>
                  setState(() => _filters = _filters.copyWith(monitor: v)),
            ),
            _CheckRow(
              label: 'Standing Desk',
              value: _filters.standingDesk,
              onChanged: (v) => setState(
                  () => _filters = _filters.copyWith(standingDesk: v)),
            ),
            const SizedBox(height: 24),
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

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      activeColor: AppColors.primary,
      title: Text(label, style: AppText.body(14)),
    );
  }
}
