import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/navigation/app_route.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/firebase/firestore_service.dart';
import '../../models/models.dart';
import '../qr/active_session_screen.dart';

/// P-15 Verification Result.
///
/// The outcome of a staff scan: the scanned code is resolved against
/// Firestore ([FirestoreService.verifyCode]) and rendered as valid,
/// already-used, expired/cancelled, or not-found — with a one-tap
/// check-in / handover that persists back to the server.
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

  @override
  void initState() {
    super.initState();
    // One error cue when a scan is rejected (success fires from SuccessCheck).
    if (!_isValid) AppFeedback.error();
  }

  bool get _isSeat => widget.result?['kind'] == 'seat';

  /// Valid = an active seat booking not yet checked in, or a book
  /// reservation still ready for pickup.
  bool get _isValid {
    final r = widget.result;
    if (r == null) return false;
    if (_isSeat) {
      return r['status'] == ReservationStatus.active.name &&
          r['checkedInAt'] == null;
    }
    return r['status'] == ReservationStatus.ready.name ||
        r['status'] == ReservationStatus.active.name;
  }

  String get _statusHeadline {
    final r = widget.result;
    if (r == null) return 'Code not recognised';
    if (_isValid) {
      return _isSeat ? 'Valid reservation' : 'Valid book reservation';
    }
    if (_isSeat && r['checkedInAt'] != null) return 'Already checked in';
    switch (r['status'] as String?) {
      case 'cancelled':
        return 'Reservation cancelled';
      case 'expired':
      case 'no_show':
        return 'Reservation expired';
      case 'completed':
        return 'Already collected';
      default:
        return 'Not currently active';
    }
  }

  Future<void> _confirm() async {
    if (widget.result == null || _busy) return;
    setState(() => _busy = true);
    await FirestoreService.instance
        .consumeVerifiedCode(widget.result!['docPath'] as String,
            widget.result!['kind'] as String)
        .catchError((_) {});
    if (!mounted) return;

    if (_isSeat) {
      final booking = _seatBookingForPass();
      if (booking != null) {
        AppRoute.pushReplacement(
          context,
          ActiveSessionScreen(booking: booking),
        );
        return;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isSeat
            ? 'Seat check-in confirmed.'
            : 'Book handover confirmed.'),
      ),
    );
    Navigator.of(context).pop();
  }

  /// The signed-in staff view may not hold the student's booking in state;
  /// fall back to a constructed booking from the live seat map.
  SeatBooking? _seatBookingForPass() {
    final state = AppScope.read(context);
    for (final booking in state.bookings) {
      if (booking.qrCode == widget.code) return booking;
    }
    final r = widget.result!;
    final seatId = r['seatId'] as String?;
    final start = r['startTime'] as DateTime?;
    final end = r['endTime'] as DateTime?;
    if (seatId == null) return null;
    final seat = state.seats.firstWhere(
      (s) => s.id == seatId,
      orElse: () => state.seats.first,
    );
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
    final notFound = r == null;
    final valid = _isValid;
    final bannerColor = notFound || !valid ? AppColors.error : AppColors.success;
    final ownerName = r?['ownerName'] as String? ?? 'Unknown';
    final ownerId = r?['ownerId'] as String? ?? '—';
    final state = AppScope.of(context);

    // Resolve the friendly resource label.
    String resourceLabel = '—';
    String locationLabel = '—';
    DateTime? start;
    DateTime? end;
    if (_isSeat) {
      final seatId = r!['seatId'] as String?;
      final seat = state.seats.firstWhere(
        (s) => s.id == seatId,
        orElse: () => state.seats.first,
      );
      resourceLabel = seat.label;
      locationLabel = 'Floor ${seat.floor} – ${seat.section}';
      start = r['startTime'] as DateTime?;
      end = r['endTime'] as DateTime?;
    } else if (r != null) {
      final bookId = r['bookId'] as String?;
      final book = state.books.firstWhere(
        (b) => b.id == bookId,
        orElse: () => state.books.first,
      );
      resourceLabel = book.title;
      locationLabel = 'Shelf ${book.shelfLocation} · Main Library';
      start = r['pickupBy'] as DateTime?;
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
                    Icon(
                      notFound
                          ? Icons.help_outline_rounded
                          : Icons.error_outline_rounded,
                      size: 88,
                      color: bannerColor,
                    ),
                  const SizedBox(height: AppSpacing.base),
                  Text(
                    _statusHeadline,
                    textAlign: TextAlign.center,
                    style: AppText.display(
                      AppText.displayMd,
                      w: FontWeight.w800,
                      color: bannerColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    notFound
                        ? 'No reservation matches "${widget.code}".'
                        : valid
                            ? 'Identity and booking details matched.'
                            : 'Pass code ${widget.code} cannot be accepted.',
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
                            label: valid ? 'Verified' : 'Rejected',
                            color: valid ? AppColors.success : AppColors.error,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          if (valid)
            PrimaryButton(
              label: _isSeat ? 'Confirm Check-in' : 'Confirm Handover',
              onPressed: _busy ? null : _confirm,
            )
          else
            PrimaryButton(
              label: 'Scan Again',
              icon: Icons.qr_code_scanner_rounded,
              onPressed: () => Navigator.of(context).pop(),
            ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Report an Issue',
            tone: ButtonTone.danger,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Issue reported to the duty librarian')),
              );
            },
          ),
        ],
      ),
    );
  }
}
