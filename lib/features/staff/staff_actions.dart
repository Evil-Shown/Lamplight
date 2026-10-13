import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/state/app_state.dart';
import '../../core/state/staff_logic.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import 'admin/widgets/staff_status_badge.dart';

/// Shared pieces of the staff dashboard, reservations and waiting-list
/// screens: the clock, tone mapping, action handlers and the two glass sheets
/// (details and notify).

/// Up to two letters from a name, for the avatar tile.
String staffInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  final list = parts.toList();
  final first = list.first.substring(0, 1);
  final last = list.length > 1 ? list.last.substring(0, 1) : '';
  return (first + last).toUpperCase();
}

/// "Seat 2C" -> "2C"; other titles come back unchanged.
String staffSeatName(AdminReservation r) =>
    r.itemTitle.replaceFirst(RegExp(r'^Seat\s+'), '');

/// "#01"-style running index.
String staffIndexLabel(int index, {int pad = 2}) =>
    '#${(index + 1).toString().padLeft(pad, '0')}';

Color staffStateColor(StaffResState s) => switch (s) {
      StaffResState.active => AppColors.success,
      StaffResState.pending => AppColors.warning,
      StaffResState.expired => AppColors.error,
      StaffResState.completed => AppColors.info,
      StaffResState.cancelled => AppColors.neutral,
    };

StaffBadgeTone staffStateTone(StaffResState s) => switch (s) {
      StaffResState.active => StaffBadgeTone.success,
      StaffResState.pending => StaffBadgeTone.warning,
      StaffResState.expired => StaffBadgeTone.danger,
      StaffResState.completed => StaffBadgeTone.info,
      StaffResState.cancelled => StaffBadgeTone.neutral,
    };

/// Badge word for a state; pending reads differently for seats and books.
String staffStateLabel(AdminReservation r, StaffResState s) =>
    switch (s) {
      StaffResState.pending => r.isSeat ? 'Pending Check-In' : 'Pending Pickup',
      StaffResState.active => 'Active',
      StaffResState.expired => 'Expired',
      StaffResState.completed => 'Completed',
      StaffResState.cancelled => 'Cancelled',
    };

/// Keeps `now` fresh for countdown text. Ticks every second while
/// [needsSecondTicks] (a check-in grace is on screen), else once a minute.
mixin StaffClockMixin<T extends StatefulWidget> on State<T> {
  DateTime now = DateTime.now();
  Timer? _clock;

  /// Set from `build` when a seconds-level countdown is visible.
  bool needsSecondTicks = false;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = DateTime.now();
      final changed = needsSecondTicks || next.minute != now.minute;
      now = next;
      if (changed && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }
}

/// True when [r] shows a seconds-level countdown at [now].
bool staffShowsGrace(AdminReservation r, DateTime now) =>
    staffTimeNote(r, now).endsWith('grace');

/// Runs a staff write, reporting the outcome with feedback and a snackbar.
Future<bool> _run(BuildContext context, Future<void> Function() action,
    String success) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    AppFeedback.success();
    messenger.showSnackBar(SnackBar(content: Text(success)));
    return true;
  } on StaffActionException catch (e) {
    AppFeedback.error();
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
    return false;
  }
}

Future<bool> staffCheckInAction(BuildContext context, AdminReservation r) {
  final state = AppScope.read(context);
  return _run(context, () => state.staffCheckIn(r),
      '${r.studentName} checked in to ${r.itemTitle}');
}

/// Confirms, then cancels. Returns false when declined or failed.
Future<bool> staffCancelAction(BuildContext context, AdminReservation r) async {
  final state = AppScope.read(context);
  final ok = await showConfirmDialog(
    context,
    title: 'Cancel reservation?',
    body: r.isSeat
        ? "${r.studentName}'s booking for ${r.itemTitle} will be cancelled and "
            'the seat freed.'
        : "${r.studentName}'s reservation for ${r.itemTitle} will be cancelled.",
    confirmLabel: 'Cancel reservation',
    cancelLabel: 'Keep',
  );
  if (!ok || !context.mounted) return false;
  return _run(context, () => state.staffCancelReservation(r),
      'Reservation cancelled');
}

/// Confirms, then ends the booking and frees the seat.
Future<bool> staffReleaseAction(BuildContext context, AdminReservation r) async {
  final state = AppScope.read(context);
  final ok = await showConfirmDialog(
    context,
    title: 'Release this seat?',
    body: '${r.itemTitle} will be marked free and '
        "${r.studentName}'s booking ended.",
    confirmLabel: 'Release',
    cancelLabel: 'Keep',
  );
  if (!ok || !context.mounted) return false;
  return _run(
      context, () => state.staffReleaseSeat(r), '${r.itemTitle} released');
}

/// The default message for the Alert / Notify sheet.
String staffAlertMessage(AdminReservation r, StaffResState s) {
  if (r.isSeat) {
    final seat = staffSeatName(r);
    return s == StaffResState.expired
        ? 'Your seat booking for $seat has ended. Please release the desk or '
            'see the library desk.'
        : 'Your seat $seat is being held. Please check in soon or it will be '
            'released.';
  }
  return s == StaffResState.expired
      ? 'Your reservation for ${r.itemTitle} has passed its pickup deadline. '
          'Please see the library desk.'
      : 'Your reserved book ${r.itemTitle} is ready. Please collect it before '
          'the pickup deadline.';
}

String staffAlertTitle(AdminReservation r, StaffResState s) => r.isSeat
    ? (s == StaffResState.expired ? 'Seat booking ended' : 'Check in soon')
    : 'Book reservation';

/// Opens the notify sheet for a reservation's owner.
Future<void> staffNotifyReservation(BuildContext context, AdminReservation r,
    {DateTime? now}) {
  final s = staffReservationState(r, now ?? DateTime.now());
  return showStaffNotifySheet(
    context,
    ownerUid: r.ownerUid,
    studentName: r.studentName,
    title: staffAlertTitle(r, s),
    initialMessage: staffAlertMessage(r, s),
  );
}

/// Glass sheet with an editable, prefilled message and a Send button.
Future<void> showStaffNotifySheet(
  BuildContext context, {
  required String ownerUid,
  required String studentName,
  required String title,
  required String initialMessage,
}) {
  final messenger = ScaffoldMessenger.of(context);
  return showGlassSheet<void>(
    context,
    builder: (sheetContext) => _NotifySheet(
      ownerUid: ownerUid,
      studentName: studentName,
      title: title,
      initialMessage: initialMessage,
      onSent: () => messenger.showSnackBar(
          SnackBar(content: Text('Message sent to $studentName'))),
    ),
  );
}

class _NotifySheet extends StatefulWidget {
  const _NotifySheet({
    required this.ownerUid,
    required this.studentName,
    required this.title,
    required this.initialMessage,
    required this.onSent,
  });

  final String ownerUid;
  final String studentName;
  final String title;
  final String initialMessage;
  final VoidCallback onSent;

  @override
  State<_NotifySheet> createState() => _NotifySheetState();
}

class _NotifySheetState extends State<_NotifySheet> {
  late final _controller = TextEditingController(text: widget.initialMessage);
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    final state = AppScope.read(context);
    final navigator = Navigator.of(context);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await state.notifyStudent(widget.ownerUid,
          title: widget.title, body: text);
      AppFeedback.success();
      widget.onSent();
      if (navigator.mounted) navigator.pop();
    } on StaffActionException catch (e) {
      AppFeedback.error();
      if (mounted) {
        setState(() {
          _sending = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl,
            AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Message ${widget.studentName}',
                  style: AppText.title(20, w: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('Sent to their notifications in the app.',
                  style: AppText.body(13, color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.base),
              TextField(
                controller: _controller,
                minLines: 3,
                maxLines: 5,
                maxLength: 240,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'Message'),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Callout(
                  tone: CalloutTone.danger,
                  icon: Icons.error_outline_rounded,
                  message: _error!,
                ),
              ],
              const SizedBox(height: AppSpacing.base),
              PrimaryButton(
                label: _sending ? 'Sending…' : 'Send',
                icon: Icons.send_rounded,
                onPressed:
                    _controller.text.trim().isEmpty || _sending ? null : _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Details sheet for a reservation, with a Copy student ID action.
void showStaffReservationDetails(BuildContext context, AdminReservation r,
    {DateTime? now}) {
  final at = now ?? DateTime.now();
  final s = staffReservationState(r, at);
  final isBook = !r.isSeat;
  final end = r.isSeat ? (r.endAt ?? r.dueAt) : r.dueAt;
  String stamp(DateTime d) => DateFormat('EEE, MMM d · h:mm a').format(d);

  showGlassSheet<void>(
    context,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Reservation details',
                      style: AppText.title(20, w: FontWeight.w800)),
                ),
                const SizedBox(width: AppSpacing.sm),
                StaffStatusBadge(
                    label: staffStateLabel(r, s), tone: staffStateTone(s)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            StaffKVRow(label: 'Student', value: r.studentName),
            StaffKVRow(label: 'Student ID', value: r.studentId),
            StaffKVRow(label: 'Type', value: isBook ? 'Book' : 'Seat'),
            StaffKVRow(
                label: isBook ? 'Book reserved' : 'Seat reserved',
                value: r.itemTitle),
            StaffKVRow(label: 'Detail', value: r.itemSubtitle),
            StaffKVRow(
                label: isBook ? 'Reserved at' : 'Booked at',
                value: stamp(r.reservedAt)),
            if (r.isSeat && r.startAt != null)
              StaffKVRow(label: 'Start', value: stamp(r.startAt!)),
            if (end != null)
              StaffKVRow(
                label: isBook ? 'Pickup deadline' : 'End',
                value: stamp(end),
                valueColor: s == StaffResState.expired ? AppColors.error : null,
              ),
            if (r.isSeat)
              StaffKVRow(
                  label: 'Checked in',
                  value: r.checkedInAt == null
                      ? 'Not yet'
                      : stamp(r.checkedInAt!)),
            const SizedBox(height: AppSpacing.base),
            PrimaryButton(
              label: 'Copy student ID',
              icon: Icons.copy_rounded,
              tone: ButtonTone.secondary,
              onPressed: r.studentId.isEmpty
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await Clipboard.setData(ClipboardData(text: r.studentId));
                      AppFeedback.tap();
                      messenger.showSnackBar(
                          const SnackBar(content: Text('Student ID copied')));
                    },
            ),
          ],
        ),
      ),
    ),
  );
}

/// Label/value row used in the staff detail sheets and cards.
class StaffKVRow extends StatelessWidget {
  const StaffKVRow(
      {super.key, required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: AppText.label(12, w: FontWeight.w600)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppText.label(13,
                  w: FontWeight.w700,
                  color: valueColor ?? AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Initials tile tinted by [color].
class StaffAvatar extends StatelessWidget {
  const StaffAvatar({super.key, required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppColors.isDark ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(staffInitials(name),
          style: AppText.title(14.5, w: FontWeight.w800, color: color)),
    );
  }
}

/// Small rounded chip such as "#001".
class StaffIndexChip extends StatelessWidget {
  const StaffIndexChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      child: Text(label,
          style: AppText.label(11, w: FontWeight.w700, ls: 0.2)),
    );
  }
}

/// Compact (but 48dp-tall) action button for dense cards.
class StaffMiniButton extends StatelessWidget {
  const StaffMiniButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = ButtonTone.primary,
  });

  final String label;
  final VoidCallback onPressed;
  final ButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final filled = tone == ButtonTone.primary;
    final fg = switch (tone) {
      ButtonTone.primary =>
        AppColors.isDark ? const Color(0xFF0F172A) : AppColors.textInverse,
      ButtonTone.danger => AppColors.error,
      _ => AppColors.primary,
    };
    final outline = tone == ButtonTone.danger
        ? AppColors.error.withValues(alpha: 0.5)
        : AppColors.borderStrong;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 64),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? AppColors.primary : AppGlass.cardFill,
            borderRadius: BorderRadius.circular(AppRadii.full),
            border: filled ? null : Border.all(color: outline, width: 1.2),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.title(13.5, w: FontWeight.w700, color: fg),
          ),
        ),
      ),
    );
  }
}
