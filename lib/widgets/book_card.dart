import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/book_model.dart';

const Color _bookFlowBackground = Color(0xFF141518);
const Color _bookFlowSurface = Color(0xFF22242A);
const Color _bookFlowBorder = Color(0xFF2E313A);
const Color _bookFlowAccent = Color(0xFFE8A838);
const Color _bookFlowTextPrimary = Colors.white;
final Color _bookFlowTextSecondary = Colors.grey[400]!;

class BookCard extends StatelessWidget {
  const BookCard({super.key, required this.book, required this.onTap});

  final BookModel book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAvailable = book.availableCopies > 0;
    final badgeColor = isAvailable ? AppColors.success : AppColors.error;
    final badgeLabel = isAvailable
        ? '+ Available (${book.availableCopies} copies)'
        : '• Unavailable';

    return Material(
      color: _bookFlowSurface,
      elevation: 0,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: _bookFlowBorder),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BookCover(
                title: book.title,
                coverUrl: book.coverUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _bookFlowTextPrimary,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _bookFlowTextSecondary,
                          ),
                    ),
                    const SizedBox(height: 10),
                    _AvailabilityBadge(
                      label: badgeLabel,
                      color: badgeColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    'Shelf ${book.shelfLocation}',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _bookFlowTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'VIEW DETAILS',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _bookFlowAccent,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: _bookFlowAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover({required this.title, required this.coverUrl});

  final String title;
  final String coverUrl;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      decoration: BoxDecoration(
        color: _bookFlowBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _bookFlowBorder),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.menu_book_outlined,
        size: 32,
        color: _bookFlowAccent,
      ),
    );

    Widget cover = placeholder;
    if (coverUrl.trim().isNotEmpty) {
      cover = Image.network(
        coverUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return placeholder;
        },
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 75,
        height: 105,
        decoration: BoxDecoration(
          color: _bookFlowBackground,
          border: Border.all(color: _bookFlowBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: cover,
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}