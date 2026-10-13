import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart' show AppNavInset;
import '../../core/feedback/app_feedback.dart';
import '../../core/state/app_state.dart';
import '../../core/state/staff_logic.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import 'staff_actions.dart';

/// One selectable extension.
class _Option {
  const _Option(this.by, this.title, this.caption, this.phrase);

  final Duration by;
  final String title;
  final String caption;

  /// Used in the confirmation sentence.
  final String phrase;
}

const _options = [
  _Option(Duration(minutes: 15), '+15 mins', 'Brief finish', '+15 minutes'),
  _Option(Duration(minutes: 30), '+30 mins', 'Recommended', '+30 minutes'),
  _Option(Duration(hours: 1), '+1 hour', 'Standard block', '+1 hour'),
  _Option(Duration(hours: 2), '+2 hours', 'Maximum limit', '+2 hours'),
];

String _hm(DateTime d) => DateFormat('HH:mm').format(d);

/// Staff screen to push a seat booking's end time out, with the conflict
/// check shown before anything is confirmed.
class ExtendTimeScreen extends StatefulWidget {
  const ExtendTimeScreen({super.key, required this.reservation});

  final AdminReservation reservation;

  @override
  State<ExtendTimeScreen> createState() => _ExtendTimeScreenState();
}

class _ExtendTimeScreenState extends State<ExtendTimeScreen> {
  _Option _selected = _options[1];
  bool _busy = false;
  String? _error;

  /// Set once the extension went through; the screen then shows the result.
  _Option? _done;
  DateTime? _doneEnd;

  /// The live copy of the booking (the list may have updated since the push).
  AdminReservation _current(AppState state) {
    final r = widget.reservation;
    return state.adminReservations
            .where((o) => o.id == r.id && o.path == r.path)
            .firstOrNull ??
        r;
  }

  Future<void> _confirm(AppState state, AdminReservation r) async {
    if (_busy) return;
    final end = r.endAt ?? r.dueAt;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await state.extendSeatBooking(r, _selected.by);
      if (!mounted) return;
      AppFeedback.success();
      setState(() {
        _busy = false;
        _done = _selected;
        _doneEnd = end?.add(_selected.by);
      });
    } on StaffActionException catch (e) {
      if (!mounted) return;
      AppFeedback.error();
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final r = _current(state);
    final done = _done;

    if (done != null) {
      return _Confirmed(
        reservation: widget.reservation,
        option: done,
        newEnd: _doneEnd,
      );
    }

    final now = DateTime.now();
    final end = r.endAt ?? r.dueAt;
    final newEnd = end?.add(_selected.by);
    final clash = newEnd == null
        ? null
        : seatExtensionConflict(r, newEnd, state.adminReservations);
    final s = staffReservationState(r, now);
    final extendable = end != null &&
        r.isSeat &&
        s != StaffResState.completed &&
        s != StaffResState.cancelled;
    final seat = staffSeatName(r);

    return AppScaffold(
      title: 'Extend Time',
      contentUnderBar: true,
      bottomBar: BottomActionBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PrimaryButton(
              label: _busy ? 'Extending…' : 'Confirm Extension',
              icon: Icons.check_rounded,
              onPressed: !_busy && extendable && clash == null
                  ? () => _confirm(state, r)
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Keep Current Time',
              tone: ButtonTone.secondary,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.base,
          GlassAppBar.contentTopPadding(context) + AppSpacing.sm,
          AppSpacing.base,
          AppSpacing.xl,
        ),
        children: [
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StaffAvatar(
                        name: r.studentName, color: staffStateColor(s)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  r.studentName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      AppText.title(16, w: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              StaffIndexChip('#${r.id.split('-').last}'),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${r.studentId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(13,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(height: AppSpacing.xl, color: AppColors.border),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Fact(
                        label: 'Station',
                        value: r.itemTitle,
                        note: r.itemSubtitle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.base),
                    Expanded(
                      child: _Fact(
                        label: 'Current window',
                        value: end == null ? '—' : 'Until ${_hm(end)}',
                        note: staffTimeNote(r, now),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Text('Select extension',
                    style: AppText.title(16, w: FontWeight.w700)),
              ),
              Text('Max +2 hrs', style: AppText.label(12.5)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var row = 0; row < _options.length; row += 2) ...[
            if (row > 0) const SizedBox(height: AppSpacing.md),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = row; i < row + 2; i++) ...[
                    if (i > row) const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _OptionTile(
                        option: _options[i],
                        selected: _options[i] == _selected,
                        onTap: () => setState(() {
                          _selected = _options[i];
                          _error = null;
                        }),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          SurfaceCard(
            tint: (clash == null ? AppColors.success : AppColors.error)
                .withValues(alpha: 0.22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New end time',
                    style: AppText.overline(11.5, color: AppColors.textFaint)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  newEnd == null ? '—' : _hm(newEnd),
                  style: AppText.display(44, w: FontWeight.w700).copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (clash != null)
                  Callout(
                    tone: CalloutTone.danger,
                    icon: Icons.warning_amber_rounded,
                    message: 'Conflicts with the next booking at '
                        '${_hm(clash.startAt!)}',
                  )
                else if (!extendable)
                  const Callout(
                    tone: CalloutTone.warning,
                    icon: Icons.info_outline_rounded,
                    message: 'This booking can no longer be extended.',
                  )
                else
                  Callout(
                    tone: CalloutTone.success,
                    icon: Icons.check_circle_outline_rounded,
                    message: 'Available · No conflicts on $seat',
                  ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Callout(
              tone: CalloutTone.danger,
              icon: Icons.error_outline_rounded,
              message: _error!,
            ),
          ],
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, required this.note});

  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.overline(10.5)),
        const SizedBox(height: 4),
        Text(value, style: AppText.title(15, w: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(note, style: AppText.body(12.5, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile(
      {required this.option, required this.selected, required this.onTap});

  final _Option option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? (AppColors.isDark ? const Color(0xFF0F172A) : AppColors.textInverse)
        : AppColors.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      label: '${option.title}, ${option.caption}',
      excludeSemantics: true,
      child: PressScale(
        onTap: onTap,
        feedback: PressFeedback.select,
        child: AnimatedContainer(
          duration: AppMotion.tabFade,
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppGlass.cardFill,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.borderStrong,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.title,
                        style: AppText.title(16, w: FontWeight.w800, color: fg)),
                    const SizedBox(height: 2),
                    Text(
                      option.caption,
                      style: AppText.body(12.5,
                          color: selected
                              ? fg.withValues(alpha: 0.85)
                              : AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 4),
                Icon(Icons.check_circle_rounded, size: 20, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown after a successful extension.
class _Confirmed extends StatelessWidget {
  const _Confirmed(
      {required this.reservation, required this.option, required this.newEnd});

  final AdminReservation reservation;
  final _Option option;
  final DateTime? newEnd;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    return AppScaffold(
      title: 'Extend Time',
      showBack: false,
      contentUnderBar: true,
      bottomBar: BottomActionBar(
        child: PrimaryButton(
          label: 'Back to Reservations',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.base,
          GlassAppBar.contentTopPadding(context) + AppSpacing.xl,
          AppSpacing.base,
          AppNavInset.bottom,
        ),
        children: [
          const Center(child: SuccessCheck()),
          const SizedBox(height: AppSpacing.base),
          const Center(
            child: StatusPill(label: 'EXTENSION CONFIRMED', compact: true),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Time Extended',
              textAlign: TextAlign.center,
              style: AppText.display(30, w: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "${r.studentName}'s reservation on ${r.itemTitle} has been "
            'extended by ${option.phrase}.',
            textAlign: TextAlign.center,
            style: AppText.body(14.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          SurfaceCard(
            child: Column(
              children: [
                InfoRow(label: 'Student', value: r.studentName),
                InfoRow(label: 'Desk', value: r.itemTitle),
                InfoRow(label: 'Extension added', value: option.phrase),
                InfoRow(
                  label: 'New end time',
                  value: newEnd == null ? '—' : _hm(newEnd!),
                  valueColor: AppColors.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
