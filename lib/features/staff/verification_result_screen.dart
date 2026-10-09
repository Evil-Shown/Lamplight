import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart' show AppStrings;
import '../../core/feedback/app_feedback.dart';
import '../../core/navigation/app_route.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/firebase/firestore_service.dart';
import '../../models/models.dart';
import '../qr/active_session_screen.dart';

/// What a scanned pass turned out to be.
enum PassOutcome { valid, alreadyUsed, tooEarly, expired, cancelled, notFound }

/// Maps the verification map onto a [PassOutcome]. A null map means the
/// code matched nothing (the service returns null for notFound/malformed).
/// Maps without the server's `result` key (demo, query fallback) are
/// judged by their `status`.
PassOutcome passOutcomeOf(Map<String, dynamic>? r) {
  if (r == null) return PassOutcome.notFound;
  switch (r['result']) {
    case 'valid':
      return PassOutcome.valid;
    case 'alreadyUsed':
      return PassOutcome.alreadyUsed;
    case 'tooEarly':
      return PassOutcome.tooEarly;
    case 'expired':
      return PassOutcome.expired;
    case 'cancelled':
      return PassOutcome.cancelled;
    case 'notFound':
    case 'malformed':
      return PassOutcome.notFound;
  }
  final isSeat = r['kind'] == 'seat';
  final status = r['status'] as String?;
  if (status == 'cancelled') return PassOutcome.cancelled;
  if (status == 'expired' || status == 'no_show' || status == 'noShow') {
    return PassOutcome.expired;
  }
  if (status == 'completed' || (isSeat && r['checkedInAt'] != null)) {
    return PassOutcome.alreadyUsed;
  }
  final open = isSeat
      ? status == ReservationStatus.active.name
      : status == ReservationStatus.ready.name ||
          status == ReservationStatus.active.name;
  return open ? PassOutcome.valid : PassOutcome.expired;
}

/// P-15 Verification Result.
///
/// The outcome of a staff scan, resolved by the server (`verifyQrPass`) and
/// rendered as one of six distinct results. A valid book pass can be turned
/// into a loan from here.
class VerificationResultScreen extends StatefulWidget {
  const VerificationResultScreen({
    super.key,
    required this.code,
    this.result,
  });

  final String code;
  final Map<String, dynamic>? result;

  @override
  State<VerificationResultScreen> createState() =>
      _VerificationResultScreenState();
}

class _VerificationResultScreenState extends State<VerificationResultScreen> {
  bool _busy = false;
  String? _error;

  late final PassOutcome _outcome = passOutcomeOf(widget.result);

  @override
  void initState() {
    super.initState();
    // One cue per outcome. The valid cue fires from SuccessCheck.
    switch (_outcome) {
      case PassOutcome.valid:
        break;
      case PassOutcome.alreadyUsed:
      case PassOutcome.tooEarly:
        AppFeedback.warning();
      case PassOutcome.expired:
      case PassOutcome.cancelled:
      case PassOutcome.notFound:
        AppFeedback.error();
    }
  }

  bool get _isSeat => widget.result?['kind'] == 'seat';

  DateTime? _time(String key) {
    final v = widget.result?[key];
    return v is DateTime ? v : (v is String ? DateTime.tryParse(v) : null);
  }

  String get _headline => switch (_outcome) {
        PassOutcome.valid =>
          _isSeat ? 'Valid reservation' : 'Valid book reservation',
        PassOutcome.alreadyUsed => 'This pass was already used',
        PassOutcome.tooEarly => 'Too early to check in',
        PassOutcome.expired => 'Pass has expired',
        PassOutcome.cancelled => 'Reservation cancelled',
        PassOutcome.notFound => 'Not a ${AppStrings.appName} code',
      };

  String get _detail {
    final fmt = DateFormat('d MMM · h:mm a');
    switch (_outcome) {
      case PassOutcome.valid:
        return 'Identity and booking details matched.';
      case PassOutcome.alreadyUsed:
        final at = _time('checkedInAt');
        return at == null
            ? 'Code ${widget.code} has been used before.'
            : 'Used on ${fmt.format(at)}.';
      case PassOutcome.tooEarly:
        final start = _time('startTime');
        return start == null
            ? 'Check-in has not opened for this booking yet.'
            : 'The booking starts ${fmt.format(start)}. Ask the student to come back then.';
      case PassOutcome.expired:
        return 'This pass is past its time and cannot be accepted.';
      case PassOutcome.cancelled:
        return 'The student cancelled this reservation.';
      case PassOutcome.notFound:
        return 'No reservation matches "${widget.code}".';
    }
  }

  (IconData, Color, String) get _look => switch (_outcome) {
        PassOutcome.valid =>
          (Icons.check_circle_rounded, AppColors.success, 'Verified'),
        PassOutcome.alreadyUsed =>
          (Icons.history_rounded, AppColors.warning, 'Already used'),
        PassOutcome.tooEarly =>
          (Icons.schedule_rounded, AppColors.warning, 'Too early'),
        PassOutcome.expired =>
          (Icons.timer_off_rounded, AppColors.error, 'Expired'),
        PassOutcome.cancelled =>
          (Icons.cancel_rounded, AppColors.error, 'Cancelled'),
        PassOutcome.notFound =>
          (Icons.help_outline_rounded, AppColors.error, 'Unknown'),
      };

  /// The reservation id is the last segment of the server's document path.
  String? get _reservationId {
    final path = widget.result?['docPath'] as String?;
    if (path == null || path.isEmpty) return null;
    return path.split('/').last;
  }

  String? get _ownerUid => widget.result?['ownerUid'] as String?;
  String? get _bookId => widget.result?['bookId'] as String?;

  /// A loan needs the student's uid and the book id, which only the server
  /// result carries.
  bool get _canLend =>
      !_isSeat && _ownerUid != null && _bookId != null && _bookId!.isNotEmpty;

  Future<void> _confirmSeat() async {
    if (widget.result == null || _busy) return;
    setState(() => _busy = true);
    await FirestoreService.instance
        .consumeVerifiedCode(widget.result!['docPath'] as String,
            widget.result!['kind'] as String)
        .catchError((_) {});
    if (!mounted) return;

    final booking = _seatBookingForPass();
    if (booking != null) {
      AppRoute.pushReplacement(
        context,
        ActiveSessionScreen(booking: booking),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seat check-in confirmed.')),
    );
    Navigator.of(context).pop();
  }

  Future<void> _lend(String title, String owner) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lend this book?'),
        content: Text('$title will be checked out to $owner.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Lend book'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final state = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await state.checkout(
        userId: _ownerUid!,
        bookId: _bookId!,
        reservationId: _reservationId,
      );
      if (!mounted) return;
      AppFeedback.success();
      messenger.showSnackBar(SnackBar(content: Text('$title lent to $owner.')));
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      AppFeedback.error();
      setState(() {
        _busy = false;
        _error = 'Could not record the loan. Check the connection and try again.';
      });
    }
  }

  /// The signed-in staff view may not hold the student's booking in state;
  /// fall back to a constructed booking from the live seat map.
  SeatBooking? _seatBookingForPass() {
    final state = AppScope.read(context);
    for (final booking in state.bookings) {
      if (booking.qrCode == widget.code) return booking;
    }
    final seatId = widget.result?['seatId'] as String?;
    final seat = state.seats.where((s) => s.id == seatId).firstOrNull;
    if (seat == null) return null;
    final start = _time('startTime');
    final end = _time('endTime');
    return SeatBooking(
      id: widget.code,
      seat: seat,
      date: start ?? DateTime.now(),
      startTime: start ?? DateTime.now(),
      endTime: end ?? (start ?? DateTime.now()).add(const Duration(hours: 3)),
      qrCode: widget.code,
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final notFound = _outcome == PassOutcome.notFound;
    final valid = _outcome == PassOutcome.valid;
    final (icon, bannerColor, pillLabel) = _look;
    final ownerName = r?['ownerName'] as String? ?? 'Unknown';
    final ownerId = r?['ownerId'] as String? ?? '—';
    final state = AppScope.of(context);

    // Resolve the friendly resource label.
    String resourceLabel = '—';
    String locationLabel = '—';
    DateTime? start;
    DateTime? end;
    if (r != null && _isSeat) {
      final seatId = r['seatId'] as String?;
      final seat = state.seats.where((s) => s.id == seatId).firstOrNull;
      if (seat != null) {
        resourceLabel = seat.label;
        locationLabel = 'Floor ${seat.floor} – ${seat.section}';
      }
      start = _time('startTime');
      end = _time('endTime');
    } else if (r != null) {
      final bookId = r['bookId'] as String?;
      final book = state.books.where((b) => b.id == bookId).firstOrNull;
      resourceLabel = (r['bookTitle'] as String?) ?? book?.title ?? 'Book';
      if (book != null) {
        locationLabel = 'Shelf ${book.shelfLocation} · Main Library';
      }
      start = _time('pickupBy');
    }

    return AppScaffold(
      title: 'Verification Result',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
        children: [
          StaggeredEntrance(
            child: GlassSurface(
              radius: AppRadii.xl,
              tint: bannerColor.withValues(alpha: 0.14),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
              child: Column(
                children: [
                  if (valid)
                    SuccessCheck(size: 96, color: bannerColor)
                  else
                    Icon(icon, size: 88, color: bannerColor),
                  const SizedBox(height: AppSpacing.base),
                  Text(
                    _headline,
                    textAlign: TextAlign.center,
                    style: AppText.display(
                      AppText.displayMd,
                      w: FontWeight.w800,
                      color: bannerColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _detail,
                    textAlign: TextAlign.center,
                    style: AppText.body(15,
                        w: FontWeight.w500, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          if (!notFound)
            StaggeredEntrance(
              index: 1,
              child: SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary,
                            borderRadius:
                                BorderRadius.circular(AppRadii.sm),
                          ),
                          child: Text(
                            _isSeat
                                ? resourceLabel
                                : resourceLabel.characters.first,
                            textAlign: TextAlign.center,
                            style: AppText.title(
                              _isSeat ? 15 : 20,
                              w: FontWeight.w800,
                              color: AppColors.textInverse,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ownerName,
                                style:
                                    AppText.title(17, w: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ownerId,
                                style: AppText.body(
                                    12.5, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    if (!_isSeat) ...[
                      InfoRow(label: 'Book', value: resourceLabel),
                      const Divider(height: 1),
                    ],
                    InfoRow(label: 'Location', value: locationLabel),
                    const Divider(height: 1),
                    InfoRow(
                      label: _isSeat ? 'Time' : 'Pickup by',
                      value: start == null
                          ? '—'
                          : end == null
                              ? DateFormat('d MMM · h:mm a').format(start)
                              : '${DateFormat('d MMM · h:mm a').format(start)} – '
                                  '${DateFormat('h:mm a').format(end)}',
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Code ${widget.code}',
                              style: AppText.body(
                                  14, color: AppColors.textSecondary),
                            ),
                          ),
                          StatusPill(
                            label: pillLabel,
                            color: bannerColor,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.base),
            Callout(
              tone: CalloutTone.danger,
              icon: Icons.error_outline_rounded,
              message: _error!,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (valid && _isSeat)
            PrimaryButton(
              label: 'Confirm Check-in',
              onPressed: _busy ? null : _confirmSeat,
            )
          else if (valid && _canLend) ...[
            PrimaryButton(
              label: 'Lend this book',
              icon: Icons.menu_book_rounded,
              onPressed:
                  _busy ? null : () => _lend(resourceLabel, ownerName),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Done',
              tone: ButtonTone.secondary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ] else if (valid)
            PrimaryButton(
              label: 'Done',
              onPressed: () => Navigator.of(context).pop(),
            )
          else
            PrimaryButton(
              label: 'Scan Again',
              icon: Icons.qr_code_scanner_rounded,
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }
}
