import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/book_model.dart';
import '../models/reservation_model.dart';

const Color _bookFlowBackground = Color(0xFF141518);
const Color _bookFlowSurface = Color(0xFF22242A);
const Color _bookFlowBorder = Color(0xFF2E313A);
const Color _bookFlowAccent = Color(0xFFE8A838);
const Color _bookFlowTextPrimary = Colors.white;
final Color _bookFlowTextSecondary = Colors.grey[400]!;
const Color _bookFlowTextInverse = Color(0xFF141518);

class BookDetailsScreen extends StatefulWidget {
  const BookDetailsScreen({super.key, required this.book});

  final BookModel book;

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  bool _bookmarked = false;
  int? _availableCopies;
  bool _isSubmittingReservation = false;
  ReservationModel? _lastReservation;

  int get _copiesAvailable => _availableCopies ?? widget.book.availableCopies;

  @override
  void initState() {
    super.initState();
    _availableCopies = widget.book.availableCopies;
  }

  Future<void> _openReservationSheet() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _bookFlowSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (sheetContext) {
        var isSubmitting = false;

        Future<void> submitReservation(StateSetter setSheetState) async {
          if (isSubmitting) return;
          setSheetState(() => isSubmitting = true);
          await Future<void>.delayed(const Duration(milliseconds: 700));
          if (!mounted) return;
          Navigator.of(sheetContext).pop(true);
        }

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final deadline = DateTime.now().add(const Duration(hours: 24));
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Confirm Book Reservation',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 14),
                  _ReservationSummary(
                    book: widget.book,
                    copiesAvailable: _copiesAvailable,
                    deadline: deadline,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.of(sheetContext).pop(false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () => submitReservation(setSheetState),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _bookFlowAccent,
                            foregroundColor: _bookFlowTextInverse,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.md),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Confirm Reservation'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmed == true) {
      await _finalizeReservation();
    }
  }

  Future<void> _finalizeReservation() async {
    if (!mounted || _copiesAvailable <= 0) return;

    setState(() => _isSubmittingReservation = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final now = DateTime.now();
    final reservation = ReservationModel(
      id: 'RSV-${now.millisecondsSinceEpoch}',
      bookId: widget.book.id,
      userId: 'mock-user',
      bookTitle: widget.book.title,
      pickupLocation: widget.book.shelfLocation,
      reservedAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
      status: 'confirmed',
    );

    if (!mounted) return;

    setState(() {
      _lastReservation = reservation;
      _availableCopies = (_copiesAvailable - 1).clamp(0, widget.book.availableCopies);
      _isSubmittingReservation = false;
    });

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reservation Confirmed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reservation ID: ${reservation.id}'),
              const SizedBox(height: 8),
              Text('Pickup location: ${reservation.pickupLocation}'),
              const SizedBox(height: 8),
              const Text(
                'Please pick up your book within 24 hours. Bring your student ID when collecting the reservation.',
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Return to Search'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final canReserve = _copiesAvailable > 0;
    final availabilityColor = canReserve ? AppColors.success : AppColors.error;
    final availabilityLabel = canReserve
        ? '+ Available ($_copiesAvailable copies)'
        : '• Unavailable';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _bookFlowBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Book Details'),
        actions: [
          IconButton(
            tooltip: _bookmarked ? 'Remove favorite' : 'Add favorite',
            icon: Icon(
              _bookmarked ? Icons.bookmark : Icons.bookmark_outline,
            ),
            onPressed: () => setState(() => _bookmarked = !_bookmarked),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 160,
                  height: 230,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    boxShadow: AppShadows.raised,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    child: _BookCoverImage(book: book),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                book.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                book.author,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _bookFlowTextSecondary,
                    ),
              ),
              const SizedBox(height: 14),
              Center(
                child: _AvailabilityPill(
                  label: availabilityLabel,
                  color: availabilityColor,
                ),
              ),
              const SizedBox(height: 22),
              _MetadataCard(book: book),
              const SizedBox(height: 24),
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                book.description.isNotEmpty
                    ? book.description
                    : 'No description is available for this book yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _bookFlowTextSecondary,
                      height: 1.6,
                    ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _bookFlowAccent,
              foregroundColor: _bookFlowTextInverse,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
            ),
            onPressed: canReserve
                ? _openReservationSheet
                : null,
            child: Text(
              canReserve ? 'Reserve book' : 'Unavailable',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookCoverImage extends StatelessWidget {
  const _BookCoverImage({required this.book});

  final BookModel book;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      decoration: BoxDecoration(
        color: _bookFlowSurface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: _bookFlowBorder),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.menu_book_rounded,
        size: 42,
        color: _bookFlowAccent,
      ),
    );

    if (book.coverUrl.trim().isEmpty) {
      return placeholder;
    }

    return Image.network(
      book.coverUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => placeholder,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return placeholder;
      },
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.book});

  final BookModel book;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bookFlowSurface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: _bookFlowBorder),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _TagChip(label: book.category, icon: Icons.local_library_outlined),
          _TagChip(label: book.isbn, icon: Icons.confirmation_number_outlined),
          _TagChip(
            label: 'Shelf ${book.shelfLocation}',
            icon: Icons.location_on_outlined,
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _bookFlowSurface,
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(color: _bookFlowBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _bookFlowAccent),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _bookFlowTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservationSummary extends StatelessWidget {
  const _ReservationSummary({
    required this.book,
    required this.copiesAvailable,
    required this.deadline,
  });

  final BookModel book;
  final int copiesAvailable;
  final DateTime deadline;

  @override
  Widget build(BuildContext context) {
    final deadlineText = 'Must pick up within 24 hours · ${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bookFlowSurface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: _bookFlowBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            book.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '$copiesAvailable copies currently available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _bookFlowTextSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            deadlineText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _bookFlowTextSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pickup location: Shelf ${book.shelfLocation}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _bookFlowTextSecondary,
                ),
          ),
        ],
      ),
    );
  }
}