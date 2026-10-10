import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app_shell.dart';
import '../../core/feedback/app_feedback.dart';
import '../../core/navigation/app_route.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../notifications/notifications_screen.dart';
import '../reservations/live_widgets.dart';
import '../qr/qr_ticket_screen.dart';
import '../focus/focus_sanctuary_screen.dart';
import '../journal/reading_journal_screen.dart';
import '../sanctuary/night_sanctuary_screen.dart';
import '../zones/study_zones_screen.dart';
import '../zones/pod_booking_screen.dart';
import '../zones/group_room_booking_screen.dart';
import '../zones/library_guide_screen.dart';
import '../seats/seat_scout_screen.dart';

/// Nordic Modern Campus home — greeting, session hero, bento, occupancy.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    if (!state.isHydrated) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppColors.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: syncFailed(state)
                ? syncErrorState(state)
                : const _HomeSkeleton(),
          ),
        ),
      );
    }

    final booking = state.todayBooking;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppColors.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: refreshable(
            state,
            ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                bottom: AppSpacing.scrollBottomInset,
              ),
              children: [
                ConnectivityBanner(lastSyncedAt: state.lastSyncedAt),
                const StaggeredEntrance(child: _HomeGreeting()),
                const SizedBox(height: AppSpacing.lg),
                if (state.pendingOffers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenMargin,
                    ),
                    child: OfferStack(offers: state.pendingOffers),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenMargin,
                  ),
                  child: StaggeredEntrance(
                    index: 1,
                    child: booking != null
                        ? _SessionHero(booking: booking)
                        : const _EmptySessionHero(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenMargin,
                  ),
                  child: StaggeredEntrance(index: 2, child: _GoalCard()),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenMargin,
                  ),
                  child: StaggeredEntrance(index: 3, child: _QuickCategories()),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenMargin,
                  ),
                  child: StaggeredEntrance(index: 4, child: _SanctuaryShowcase()),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenMargin,
                  ),
                  child: StaggeredEntrance(index: 5, child: _GlanceStrip()),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenMargin,
                  ),
                  child: StaggeredEntrance(
                    index: 6,
                    child: _FloorAvailability(
                      lastSyncedAt: state.lastSyncedAt,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Solid warm card used across Home so content stays crisp over the scene
/// behind it (translucent glass let the dunes show through the text).
class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = AppRadii.card,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.scheme.surfaceContainerLow.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: AppColors.scheme.outlineVariant.withValues(alpha: 0.8),
        ),
        boxShadow: AppGlass.shadows,
      ),
      child: child,
    );
    return onTap == null ? card : PressScale(onTap: onTap!, child: card);
  }
}

/// Small rounded icon on a soft tint.
class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon, required this.tint, this.size = 40});

  final IconData icon;
  final Color tint;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: AppColors.isDark ? 0.22 : 0.16),
        borderRadius: BorderRadius.circular(size * 0.36),
      ),
      child: Icon(icon, size: size * 0.52, color: tint),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: AppText.display(22, w: FontWeight.w700)),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _HomeGreeting extends StatelessWidget {
  const _HomeGreeting();

  (String, String, String) _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return ('Good morning', '👋', 'A calmer mind, a brighter day.');
    }
    if (hour < 17) {
      return ('Good afternoon', '☀️', 'Focus on what matters most.');
    }
    return ('Quiet evening', '🌙', 'Unwind and read by lamplight.');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final profile = state.activeProfile;
    final name = profile.firstName;
    final initial = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
    final (greeting, icon, tagline) = _greeting();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenMargin,
        AppSpacing.md,
        AppSpacing.screenMargin,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppGradients.brand,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppGlass.rim, width: 2),
                  boxShadow: AppGlass.shadows,
                ),
                child: Text(
                  initial,
                  style: AppText.display(
                    24,
                    w: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            greeting,
                            style: AppText.body(
                              13,
                              w: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(icon, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    Text(
                      name,
                      style: AppText.display(25, w: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      tagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        11.5,
                        w: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Semantics(
                button: true,
                label: state.unreadCount > 0
                    ? 'Notifications, ${state.unreadCount} unread'
                    : 'Notifications',
                excludeSemantics: true,
                child: PressScale(
                  onTap: () {
                    AppFeedback.tap();
                    AppRoute.push(context, const NotificationsScreen());
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                        color: AppColors.scheme.outlineVariant,
                      ),
                      boxShadow: AppGlass.shadows,
                    ),
                    alignment: Alignment.center,
                    child: Badge(
                      isLabelVisible: state.unreadCount > 0,
                      label: Text(state.unreadCount > 9
                          ? '9+'
                          : '${state.unreadCount}'),
                      backgroundColor: AppColors.error,
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 23,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(color: AppColors.scheme.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        'Campus library · open',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(
                          12,
                          w: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFD99246).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(
                    color: const Color(0xFFD99246).withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.electric_bolt_rounded,
                      size: 13,
                      color: Color(0xFFD99246),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '84 seats free',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label(
                          11,
                          w: FontWeight.w700,
                          color: const Color(0xFFD99246),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          PressScale(
            onTap: () {
              AppFeedback.tap();
              AppShell.switchTab(context, AppTab.books);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.scheme.surfaceContainerLow.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(
                  color: AppColors.scheme.outlineVariant.withValues(alpha: 0.8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: AppColors.isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Search catalog, authors, glass pods...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        13.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Filter',
                          style: AppText.label(
                            11,
                            w: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionHero extends StatelessWidget {
  const _SessionHero({required this.booking});

  final SeatBooking booking;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final demo = state.dataSource == DataSource.demo;

    return DepthHero(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Today\'s study session',
                  style: AppText.body(
                    14,
                    color: AppColors.textInverse.withValues(alpha: 0.9),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.textInverse.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: LiveClock(
                  period: const Duration(seconds: 15),
                  builder: (context, now) {
                    final endsIn = booking.endTime.difference(now);
                    return Text(
                      endsIn.isNegative
                          ? 'Session ended'
                          : '${formatRemaining(endsIn)} left',
                      style: AppText.label(
                        12,
                        w: FontWeight.w700,
                        color: AppColors.textInverse,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.textInverse.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigo.withValues(alpha: 0.45),
                      blurRadius: 16,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Text(
                  'Seat ${booking.seat.label}',
                  style: AppText.title(
                    20,
                    w: FontWeight.w700,
                    color: AppColors.textInverse,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Floor ${booking.seat.floor} · ${booking.seat.section}',
            style: AppText.body(
              13,
              color: AppColors.textInverse.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: CountdownBadge(
              prefix: 'Check in within',
              onGradient: true,
              remaining: (now) => state.graceRemaining(booking, now: now),
            ),
          ),
          if (!demo && booking.checkedInAt == null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Show this QR at the desk to check in.',
              style: AppText.body(
                12.5,
                color: AppColors.textInverse.withValues(alpha: 0.88),
              ),
            ),
          ],
          const SizedBox(height: 18),
          _HeroButton(
            label: 'View QR ticket',
            icon: Icons.qr_code_2_rounded,
            onTap: () => AppRoute.push(
              context,
              QrTicketScreen(booking: booking),
            ),
          ),
        ],
      ),
    );
  }
}

/// White pill on the hero gradient: the one primary action of the screen.
class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: () {
        AppFeedback.tap();
        onTap();
      },
      child: Container(
        height: 52,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.textInverse,
          borderRadius: BorderRadius.circular(AppRadii.md),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label(
                  15,
                  w: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_rounded,
                size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _EmptySessionHero extends StatelessWidget {
  const _EmptySessionHero();

  @override
  Widget build(BuildContext context) {
    return DepthHero(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'READY WHEN YOU ARE',
                      style: AppText.overline(
                        10.5,
                        ls: 1.2,
                        color: AppColors.textInverse.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Find your quiet corner',
                      style: AppText.display(
                        25,
                        w: FontWeight.w800,
                        color: AppColors.textInverse,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reserve a seat on Floor 2 in under a minute.',
                      style: AppText.body(
                        13.5,
                        color: AppColors.textInverse.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const ExcludeSemantics(
                child: SizedBox(width: 92, height: 104, child: _NookArt()),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _HeroButton(
                  label: 'Book a seat',
                  icon: Icons.event_seat_rounded,
                  onTap: () => AppShell.switchTab(context, AppTab.seats),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: PressScale(
                  onTap: () {
                    AppFeedback.tap();
                    AppRoute.push(context, const SeatScoutScreen());
                  },
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.radar_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Scout Map',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.label(
                              13.5,
                              w: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A tiny reading nook: a stack of books under a glowing lamp.
class _NookArt extends StatelessWidget {
  const _NookArt();

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _NookPainter());
}

class _NookPainter extends CustomPainter {
  const _NookPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Lamp glow.
    final glowC = Offset(w * 0.68, h * 0.3);
    canvas.drawCircle(
      glowC,
      w * 0.55,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFFC77A).withValues(alpha: 0.5),
          const Color(0xFFFFC77A).withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: glowC, radius: w * 0.55)),
    );

    RRect book(double y, double inset, double bh) => RRect.fromRectAndRadius(
          Rect.fromLTWH(inset, y, w - inset * 2, bh),
          const Radius.circular(5),
        );

    // Three books, a little crooked.
    final books = [
      (h * 0.80, 2.0, h * 0.14, const Color(0xFFE6C48A)),
      (h * 0.66, 8.0, h * 0.14, const Color(0xFFB5532C)),
      (h * 0.52, 4.0, h * 0.14, const Color(0xFFF3E8D6)),
    ];
    for (final (y, inset, bh, color) in books) {
      canvas.drawRRect(book(y, inset, bh), Paint()..color = color);
      canvas.drawRect(
        Rect.fromLTWH(inset + 8, y + bh * 0.4, w - inset * 2 - 24, 2),
        Paint()..color = Colors.black.withValues(alpha: 0.18),
      );
    }

    // Lamp: stem, base on the top book, and the shade.
    final base = Offset(w * 0.68, h * 0.52);
    final dark = Paint()..color = const Color(0xFF3A2314);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx - 9, base.dy - 5, 18, 5),
        const Radius.circular(2.5),
      ),
      dark,
    );
    canvas.drawRect(Rect.fromLTWH(base.dx - 1.5, base.dy - 26, 3, 22), dark);
    final shade = Path()
      ..moveTo(base.dx - 9, base.dy - 48)
      ..lineTo(base.dx + 9, base.dy - 48)
      ..lineTo(base.dx + 17, base.dy - 25)
      ..lineTo(base.dx - 17, base.dy - 25)
      ..close();
    canvas.drawPath(shade, Paint()..color = const Color(0xFFFFD58C));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _dueText(DateTime due) {
  final days = due.difference(DateTime.now()).inDays;
  if (days < 0) return 'Overdue';
  if (days == 0) return 'Due today';
  if (days == 1) return 'Due tomorrow';
  return 'Due in $days days';
}

/// Three numbers worth a glance: free seats, books out, books waiting.
class _GlanceStrip extends StatelessWidget {
  const _GlanceStrip();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final seats = state.seats;
    final free = seats.where((s) => s.status == SeatStatus.available).length;
    final loans = state.activeLoans;
    final overdue = state.overdueLoans.length;
    final waiting = state.activeReservations.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('At a glance'),
        const SizedBox(height: AppSpacing.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _GlanceCard(
                  icon: Icons.event_seat_rounded,
                  tint: AppColors.primary,
                  value: '$free',
                  label: 'Seats free',
                  sub: 'of ${seats.length} today',
                  onTap: () => AppShell.switchTab(context, AppTab.seats),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _GlanceCard(
                  icon: Icons.auto_stories_rounded,
                  tint: AppColors.indigo,
                  value: '${loans.length}',
                  label: 'On loan',
                  sub: overdue > 0
                      ? '$overdue overdue'
                      : loans.isEmpty
                          ? 'None out'
                          : _dueText(loans.first.dueAt),
                  subColor: overdue > 0 ? AppColors.error : null,
                  onTap: () => AppShell.switchTab(context, AppTab.books),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _GlanceCard(
                  icon: Icons.bookmark_added_rounded,
                  tint: AppColors.gold,
                  value: '$waiting',
                  label: 'Reserved',
                  sub: waiting == 0 ? 'Nothing waiting' : 'Ready to collect',
                  onTap: () => AppShell.switchTab(context, AppTab.bookings),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlanceCard extends StatelessWidget {
  const _GlanceCard({
    required this.icon,
    required this.tint,
    required this.value,
    required this.label,
    required this.sub,
    required this.onTap,
    this.subColor,
  });

  final IconData icon;
  final Color tint;
  final String value;
  final String label;
  final String sub;
  final Color? subColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$value $label, $sub',
      excludeSemantics: true,
      child: _HomeCard(
        onTap: onTap,
        radius: AppRadii.lg + 4,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconChip(icon: icon, tint: tint, size: 34),
            const SizedBox(height: 10),
            Text(
              value,
              style: AppText.display(28, w: FontWeight.w800, ls: -1),
            ),
            Text(
              label,
              style: AppText.body(12.5, w: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                11.5,
                w: subColor == null ? FontWeight.w400 : FontWeight.w700,
                color: subColor ?? AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Today's Reading / Focus Goal capsule card, inspired by Image 4.
class _GoalCard extends StatelessWidget {
  const _GoalCard();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final hasLoans = state.activeLoans.isNotEmpty;
    final title = hasLoans ? 'Read 20 pages' : '2h Focus session';
    final sub = hasLoans
        ? state.activeLoans.first.title
        : 'Floor 2 · Quiet Reading Hall';
    const progress = 0.70;
    final isDark = AppColors.isDark;

    return Semantics(
      button: true,
      label: "Today's Goal: $title, 14 of 20 completed",
      child: PressScale(
        onTap: () {
          AppFeedback.tap();
          AppShell.switchTab(context, AppTab.books);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F332D) : const Color(0xFF163832),
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF8EB69B).withValues(alpha: 0.25)
                  : const Color(0xFFDAF1DE).withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : const Color(0xFF163832))
                    .withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8EB69B).withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.adjust_rounded,
                      size: 22,
                      color: Color(0xFFDAF1DE),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Goal",
                          style: AppText.overline(
                            11,
                            ls: 1.0,
                            color: const Color(0xFF8EB69B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: AppText.title(
                            16,
                            w: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD99246).withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(
                        color: const Color(0xFFD99246).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          '5d streak',
                          style: AppText.label(
                            11,
                            w: FontWeight.w800,
                            color: const Color(0xFFFFAA2A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        12,
                        color: const Color(0xFFDAF1DE).withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '14 / 20',
                    style: AppText.label(
                      12,
                      w: FontWeight.w700,
                      color: const Color(0xFFDAF1DE),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.full),
                child: SizedBox(
                  height: 6,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF8EB69B),
                    ),
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

/// Category exploration chips inspired by Images 3 & 4.
class _QuickCategories extends StatelessWidget {
  const _QuickCategories();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Explore'),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _CategoryPill(
                icon: Icons.menu_book_rounded,
                label: 'Read',
                tint: const Color(0xFF163832),
                bgTint: const Color(0xFFDAF1DE),
                onTap: () => AppShell.switchTab(context, AppTab.books),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _CategoryPill(
                icon: Icons.event_seat_rounded,
                label: 'Desks',
                tint: const Color(0xFF235347),
                bgTint: const Color(0xFFE4F0E8),
                onTap: () => AppShell.switchTab(context, AppTab.seats),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _CategoryPill(
                icon: Icons.confirmation_number_rounded,
                label: 'Bookings',
                tint: const Color(0xFF806B59),
                bgTint: const Color(0xFFF0E8DD),
                onTap: () => AppShell.switchTab(context, AppTab.bookings),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _CategoryPill(
                icon: Icons.qr_code_2_rounded,
                label: 'QR Pass',
                tint: const Color(0xFFD99246),
                bgTint: const Color(0xFFFBE4C8),
                onTap: () {
                  final booking = AppScope.read(context).todayBooking;
                  if (booking != null) {
                    AppRoute.push(context, QrTicketScreen(booking: booking));
                  } else {
                    AppShell.switchTab(context, AppTab.bookings);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.icon,
    required this.label,
    required this.tint,
    required this.bgTint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final Color bgTint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    return Semantics(
      button: true,
      label: label,
      child: PressScale(
        onTap: () {
          AppFeedback.tap();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0B2B26) : Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF163832)
                  : const Color(0xFFD8C9B6).withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? tint.withValues(alpha: 0.25) : bgTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isDark ? const Color(0xFF8EB69B) : tint,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: AppText.label(
                      12,
                      w: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
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

/// Artistic Sanctuaries & Studios carousel inspired by the user images.
class _SanctuaryShowcase extends StatelessWidget {
  const _SanctuaryShowcase();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          'Spaces & Sanctuaries',
          trailing: TextButton(
            onPressed: () {
              AppFeedback.tap();
              AppRoute.push(context, const StudyZonesScreen());
            },
            child: const Text('View All'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 190,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              _SanctuaryCard(
                title: 'Glass Study Pods (01-05)',
                subtitle: 'Private tinted deep focus rooms',
                tag: 'PODS 01-05',
                imageAsset: 'assets/images/zone_glass_pods.png',
                accentColor: const Color(0xFFD99246),
                onTap: () =>
                    AppRoute.push(context, const PodBookingScreen()),
              ),
              const SizedBox(width: AppSpacing.md),
              _SanctuaryCard(
                title: 'Design & Project Studio',
                subtitle: 'Creative group tables & idea walls',
                tag: 'TEAM COLLAB',
                imageAsset: 'assets/images/zone_design_project.jpg',
                accentColor: const Color(0xFFE56A2B),
                onTap: () =>
                    AppRoute.push(context, const GroupRoomBookingScreen()),
              ),
              const SizedBox(width: AppSpacing.md),
              _SanctuaryCard(
                title: 'Floor Scout & Deals',
                subtitle: 'Radial seat map with Focus Scores',
                tag: 'DEAL SCORES',
                imageAsset: 'assets/images/zone_quiet_lounge.jpg',
                accentColor: const Color(0xFF0D7EE8),
                onTap: () =>
                    AppRoute.push(context, const SeatScoutScreen()),
              ),
              const SizedBox(width: AppSpacing.md),
              _SanctuaryCard(
                title: 'Startup & Innovation Lab',
                subtitle: 'Workshop tables & agile lounge',
                tag: 'INNOVATION',
                imageAsset: 'assets/images/zone_startup_hub.png',
                accentColor: const Color(0xFF0D7EE8),
                onTap: () =>
                    AppRoute.push(context, const StudyZonesScreen()),
              ),
              const SizedBox(width: AppSpacing.md),
              _SanctuaryCard(
                title: 'Zen Focus Room',
                subtitle: 'Timer & library rain sounds',
                tag: 'DEEP WORK',
                imageAsset: 'assets/images/focus_canyon.png',
                accentColor: const Color(0xFF7EE0C3),
                onTap: () =>
                    AppRoute.push(context, const FocusSanctuaryScreen()),
              ),
              const SizedBox(width: AppSpacing.md),
              _SanctuaryCard(
                title: 'Reading Journal',
                subtitle: 'Quotes & rowboat journey',
                tag: 'JOURNAL',
                imageAsset: 'assets/images/dual_island.png',
                accentColor: const Color(0xFFDAF1DE),
                onTap: () =>
                    AppRoute.push(context, const ReadingJournalScreen()),
              ),
              const SizedBox(width: AppSpacing.md),
              _SanctuaryCard(
                title: 'Night Sanctuary',
                subtitle: 'Open until 02:00 AM • Light lantern',
                tag: 'NIGHT OWL',
                imageAsset: 'assets/images/night_lanterns.png',
                accentColor: const Color(0xFFFFAA2A),
                onTap: () =>
                    AppRoute.push(context, const NightSanctuaryScreen()),
              ),
              const SizedBox(width: AppSpacing.md),
              _SanctuaryCard(
                title: 'Knowledge Line & Code',
                subtitle: 'Quiet zones & campus facilities',
                tag: 'ETIQUETTE',
                imageAsset: 'assets/images/zone_quiet_lounge.jpg',
                accentColor: const Color(0xFFD4A017),
                onTap: () =>
                    AppRoute.push(context, const LibraryGuideScreen()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SanctuaryCard extends StatelessWidget {
  const _SanctuaryCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.imageAsset,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String tag;
  final String imageAsset;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    return PressScale(
      onTap: () {
        AppFeedback.tap();
        onTap();
      },
      child: Container(
        width: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF163832),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      stops: const [0.3, 0.95],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: AppText.overline(
                          10,
                          ls: 1.0,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title(
                        16,
                        w: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        11.5,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// How busy each floor is right now, one row per floor.
class _FloorAvailability extends StatelessWidget {
  const _FloorAvailability({required this.lastSyncedAt});

  final DateTime? lastSyncedAt;

  @override
  Widget build(BuildContext context) {
    final seats = AppScope.of(context).seats;

    final rows = <Widget>[];
    for (final floor in const [1, 2, 3]) {
      final onFloor = seats.where((s) => s.floor == floor).toList();
      if (onFloor.isEmpty) continue;
      final free = onFloor.where((s) => s.status == SeatStatus.available).length;
      final taken =
          onFloor.where((s) => s.status == SeatStatus.occupied).length;
      final ratio = taken / onFloor.length;
      if (rows.isNotEmpty) rows.add(const SizedBox(height: AppSpacing.base));
      rows.add(_FloorRow(floor: floor, free: free, ratio: ratio));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          'Floors right now',
          trailing: LiveFreshness(lastSyncedAt: lastSyncedAt),
        ),
        const SizedBox(height: AppSpacing.md),
        _HomeCard(
          onTap: () => AppShell.switchTab(context, AppTab.seats),
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: rows.isEmpty
              ? Text(
                  'Seat availability will show up here once it loads.',
                  style: AppText.body(13, color: AppColors.textSecondary),
                )
              : Column(children: rows),
        ),
      ],
    );
  }
}

class _FloorRow extends StatelessWidget {
  const _FloorRow({
    required this.floor,
    required this.free,
    required this.ratio,
  });

  final int floor;
  final int free;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (ratio) {
      < 0.5 => ('Quiet', AppColors.success),
      < 0.8 => ('Busy', AppColors.warning),
      _ => ('Full', AppColors.error),
    };
    return Semantics(
      label: 'Floor $floor, $label, $free seats free',
      excludeSemantics: true,
      child: Column(
        children: [
          Row(
            children: [
              Text('Floor $floor',
                  style: AppText.title(15, w: FontWeight.w800)),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(
                  label,
                  style: AppText.label(11, w: FontWeight.w800, color: color),
                ),
              ),
              const Spacer(),
              Text(
                '$free free',
                style: AppText.body(12.5,
                    w: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          MeterBar(value: ratio, color: color),
        ],
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Skeleton(height: 56, radius: AppRadii.card),
        SizedBox(height: 20),
        Skeleton(height: 180, radius: AppRadii.xl),
        SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Skeleton(height: 96, radius: AppRadii.card)),
            SizedBox(width: 12),
            Expanded(child: Skeleton(height: 96, radius: AppRadii.card)),
          ],
        ),
      ],
    );
  }
}
