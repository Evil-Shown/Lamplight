import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../app_shell.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
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
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _HeroHeader(greeting: greeting, name: firstName)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppNavInset.bottom),
              sliver: SliverList(
              delegate: SliverChildListDelegate([
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatsRow(),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Quick actions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _QuickActions(),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Your library today',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ..._buildActivityCards(context),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Discover',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SoftCard(
                        elevated: true,
                        onTap: () => AppShell.switchTab(context, 1),
                        child: Row(
                          children: [
                            BookCover(
                              title: MockData.books.first.title,
                              color: MockData.books.first.coverColor,
                              width: 52,
                              height: 72,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Browse the catalog',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${MockData.books.length} titles ready · reserve in seconds',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SoftCard(
                        elevated: true,
                        onTap: () => AppShell.switchTab(context, 2),
                        child: Row(
                          children: [
                            const IconBadge(icon: Icons.event_seat_rounded, size: 52),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Find a quiet seat',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${MockData.seats.where((s) => s.status == SeatStatus.available).length} seats open right now',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
                          ],
                        ),
                      ),
                  ],
                ),
              ]),
            ),
          ),
        ],
        ),
      ),
    );
  }

  List<Widget> _buildActivityCards(BuildContext context) {
    final cards = <Widget>[];

    if (MockData.activeBookings.isNotEmpty) {
      final b = MockData.activeBookings.first;
      final grace = b.gracePeriodEndsAt;
      cards.add(
        SoftCard(
          elevated: true,
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const IconBadge(icon: Icons.event_seat_rounded, color: AppColors.secondary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seat ${b.seat.label}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        Text(
                          'Floor ${b.seat.floor} · ${b.seat.section}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const StatusChip(label: 'Active', color: AppColors.success, icon: Icons.check_circle),
                ],
              ),
              if (grace != null) ...[
                const SizedBox(height: AppSpacing.md),
                AlertBanner(
                  tone: AlertTone.warning,
                  icon: Icons.timer_outlined,
                  message:
                      'Check in within ${_remaining(grace)} or this seat will be released.',
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
        SoftCard(
          elevated: true,
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyReservationsScreen()),
          ),
          child: Row(
            children: [
              BookCover(
                title: r.book.title,
                color: r.book.coverColor,
                width: 48,
                height: 66,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.book.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pickup by ${DateFormat('MMM d').format(r.pickupBy)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const StatusChip(label: 'Reserved', color: AppColors.warning),
            ],
          ),
        ),
      );
    }

    if (MockData.waitlistEntries.isNotEmpty) {
      final w = MockData.waitlistEntries.first;
      cards.add(
        SoftCard(
          elevated: true,
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WaitlistScreen()),
          ),
          child: Row(
            children: [
              IconBadge(
                icon: w.type.name == 'book'
                    ? Icons.menu_book_rounded
                    : Icons.hourglass_top_rounded,
                color: AppColors.warning,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      'Position #${w.position} in line',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
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

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.greeting, required this.name});

  final String greeting;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F3D2E),
            Color(0xFF1B5E45),
            Color(0xFF2D6A4F),
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned(right: -52, top: -40, child: _heroCircle(180, 0.07)),
          Positioned(left: -44, bottom: -64, child: _heroCircle(170, 0.06)),
          Positioned(right: 52, bottom: -34, child: _heroCircle(96, 0.05)),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              MediaQuery.paddingOf(context).top + AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_library_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      AppStrings.appName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Scan QR',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const QrScanScreen(mode: QrScanMode.seatCheckIn),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '$greeting,',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w500,
                ),
          ),
          Text(
            name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Books, seats, and waitlists — all in one calm place.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                  height: 1.4,
                ),
          ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  Widget _heroCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final available =
        MockData.seats.where((s) => s.status == SeatStatus.available).length;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Reservations',
            value: '${MockData.activeReservations.length}',
            icon: Icons.bookmark_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            label: 'Bookings',
            value: '${MockData.activeBookings.length}',
            icon: Icons.event_available_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            label: 'Open seats',
            value: '$available',
            icon: Icons.chair_alt_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      elevated: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionPill(
            icon: Icons.search_rounded,
            label: 'Search\nBooks',
            color: AppColors.primary,
            onTap: () => AppShell.switchTab(context, 1),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ActionPill(
            icon: Icons.event_seat_rounded,
            label: 'Book\na Seat',
            color: AppColors.secondary,
            onTap: () => AppShell.switchTab(context, 2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ActionPill(
            icon: Icons.bookmark_rounded,
            label: 'My\nHolds',
            color: AppColors.warning,
            badge: MockData.activeReservations.length,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyReservationsScreen()),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ActionPill(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Scan\nQR',
            color: AppColors.info,
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

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      elevated: true,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              if (badge != null && badge! > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
