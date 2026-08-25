import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../app_shell.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ledger_widgets.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../data/mock/mock_data.dart';
import '../../models/models.dart';
import '../books/my_reservations_screen.dart';
import '../qr/qr_scan_screen.dart';
import '../seats/my_bookings_screen.dart';
import '../waitlist/waitlist_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firstName = MockData.userProfile.name.split(' ').first;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            MediaQuery.paddingOf(context).top + AppSpacing.md,
            AppSpacing.md,
            AppNavInset.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LedgerHero(greeting: greeting, name: firstName),
              const SizedBox(height: AppSpacing.xl),
              Text('Quick actions', style: AppText.serif(20)),
              const SizedBox(height: AppSpacing.md),
              const _QuickActions(),
              const SizedBox(height: AppSpacing.xl),
              Text('Today at a glance', style: AppText.serif(20)),
              const SizedBox(height: AppSpacing.md),
              ..._buildGlanceCards(context),
              const SizedBox(height: AppSpacing.xl),
              Text('Discover', style: AppText.serif(20)),
              const SizedBox(height: AppSpacing.md),
              SoftCard(
                elevated: true,
                onTap: () => AppShell.switchTab(context, 1),
                child: Row(
                  children: [
                    BookCover(
                      title: MockData.books.first.title,
                      color: MockData.books.first.coverColor,
                      isbn: MockData.books.first.isbn,
                      width: 46,
                      height: 64,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Browse the catalog', style: AppText.serif(16.5, ls: -0.2)),
                          const SizedBox(height: 3),
                          Eyebrow(
                            '${MockData.books.length} titles ready · reserve in seconds',
                          ),
                        ],
                      ),
                    ),
                    const _InkArrow(),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SoftCard(
                elevated: true,
                onTap: () => AppShell.switchTab(context, 2),
                child: Row(
                  children: [
                    const IconBadge(icon: Icons.event_seat_rounded, size: 48),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Find a quiet seat', style: AppText.serif(16.5, ls: -0.2)),
                          const SizedBox(height: 3),
                          Eyebrow(
                            '${MockData.seats.where((s) => s.status == SeatStatus.available).length} seats open right now',
                          ),
                        ],
                      ),
                    ),
                    const _InkArrow(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGlanceCards(BuildContext context) {
    final cards = <Widget>[];

    if (MockData.activeBookings.isNotEmpty) {
      final b = MockData.activeBookings.first;
      final grace = b.gracePeriodEndsAt;
      cards.add(
        TicketCard(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const IconBadge(icon: Icons.event_seat_rounded, color: AppColors.inkSoft),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seat ${b.seat.label}', style: AppText.serif(17, ls: -0.2)),
                        const SizedBox(height: 2),
                        Text(
                          'Floor ${b.seat.floor} · ${b.seat.section}',
                          style: AppText.sans(12.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const StatusChip(
                    label: 'Active',
                    color: AppColors.stampGreen,
                    pulse: true,
                  ),
                ],
              ),
              if (grace != null) ...[
                const SizedBox(height: AppSpacing.md),
                AlertBanner(
                  tone: AlertTone.warning,
                  icon: Icons.timer_outlined,
                  message:
                      'Check in within ${_remaining(grace)} or the seat returns to the floor.',
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (MockData.activeReservations.isNotEmpty) {
      final r = MockData.activeReservations.first;
      cards.add(
        TicketCard(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyReservationsScreen()),
          ),
          child: Row(
            children: [
              BookCover(
                title: r.book.title,
                color: r.book.coverColor,
                isbn: r.book.isbn,
                width: 44,
                height: 62,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.book.title,
                      style: AppText.serif(15.5, ls: -0.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Pickup by ${DateFormat('MMM d').format(r.pickupBy)}',
                      style: AppText.sans(12.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const StatusChip(label: 'Reserved', color: AppColors.stampGold),
            ],
          ),
        ),
      );
    }

    if (MockData.waitlistEntries.isNotEmpty) {
      final w = MockData.waitlistEntries.first;
      cards.add(
        TicketCard(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WaitlistScreen()),
          ),
          child: Row(
            children: [
              const IconBadge(icon: Icons.hourglass_top_rounded, color: AppColors.stampGold),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.title, style: AppText.serif(15.5, ls: -0.2)),
                    const SizedBox(height: 3),
                    Text(
                      'Position #${w.position} in line',
                      style: AppText.sans(12.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (w.estimatedWait != null)
                Text(
                  '~${w.estimatedWait!.inMinutes}m',
                  style: AppText.mono(11, ls: 1.2, color: AppColors.goldDeep),
                ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textFaint),
            ],
          ),
        ),
      );
    }

    if (cards.isEmpty) {
      cards.add(
        SoftCard(
          child: Text(
            'Nothing active yet — reserve a book or book a seat to get started.',
            style: AppText.sans(13.5, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return cards;
  }

  String _remaining(DateTime deadline) {
    final diff = deadline.difference(DateTime.now());
    if (diff.isNegative) return '0 min';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }
}

class _InkArrow extends StatelessWidget {
  const _InkArrow();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: AppColors.ink,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.arrow_forward_rounded, size: 17, color: AppColors.paper),
    );
  }
}

/// The hero ledger — ink panel, date eyebrow, serif greeting, gold stat boxes.
class _LedgerHero extends StatelessWidget {
  const _LedgerHero({required this.greeting, required this.name});

  final String greeting;
  final String name;

  @override
  Widget build(BuildContext context) {
    final available =
        MockData.seats.where((s) => s.status == SeatStatus.available).length;
    final dateLabel = DateFormat('EEEE, MMM d').format(DateTime.now());

    return InkPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
                  color: AppColors.gold.withValues(alpha: 0.08),
                ),
                child: const Eyebrow('✦ LIBRARY+', color: AppColors.gold),
              ),
              const Spacer(),
              Material(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QrScanScreen(mode: QrScanMode.seatCheckIn),
                    ),
                  ),
                  child: const SizedBox(
                    width: 46,
                    height: 46,
                    child: Icon(Icons.qr_code_scanner_rounded,
                        color: AppColors.gold, size: 22),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Eyebrow('LEDGER — $dateLabel', color: AppColors.gold.withValues(alpha: 0.8)),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(
            '$greeting,\n$name.',
            style: AppText.serif(30, w: FontWeight.w700, color: AppColors.paper, height: 1.15),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(
            'Open until 10:00 PM · quiet study & group rooms',
            style: AppText.sans(13.5, color: AppColors.paper.withValues(alpha: 0.6), height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          const DashedRule(),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  value: '${MockData.activeReservations.length}',
                  label: 'Reserved',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HeroStat(
                  value: '${MockData.activeBookings.length}',
                  label: 'Booked',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _HeroStat(value: '$available', label: 'Seats open'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppText.serif(24, w: FontWeight.w700, color: AppColors.gold, ls: 0),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppText.sans(11, w: FontWeight.w500,
                color: AppColors.paper.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.search_rounded,
            label: 'Search',
            onTap: () => AppShell.switchTab(context, 1),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ActionTile(
            icon: Icons.event_seat_rounded,
            label: 'Book Seat',
            tint: AppColors.stampGreen,
            onTap: () => AppShell.switchTab(context, 2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ActionTile(
            icon: Icons.bookmark_rounded,
            label: 'My Holds',
            tint: AppColors.stampGold,
            badge: MockData.activeReservations.length,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyReservationsScreen()),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ActionTile(
            icon: Icons.qr_code_rounded,
            label: 'Scan QR',
            tint: AppColors.inkSoft,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const QrScanScreen(mode: QrScanMode.seatCheckIn),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tint = AppColors.goldDeep,
    this.badge,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      elevated: true,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: tint, size: 21),
              ),
              if (badge != null && badge! > 0)
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.goldDeep,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.paperCard, width: 2),
                    ),
                    child: Text(
                      '$badge',
                      style: AppText.sans(9, w: FontWeight.w800, color: AppColors.paper),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          Text(label, style: AppText.sans(11.5, w: FontWeight.w600)),
        ],
      ),
    );
  }
}
