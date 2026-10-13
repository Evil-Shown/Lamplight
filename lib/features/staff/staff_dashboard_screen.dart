import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app_shell.dart' show AppShell, AppTab;
import '../../core/constants/app_constants.dart' show AppNavInset;
import '../../core/navigation/app_route.dart';
import '../../core/state/app_state.dart';
import '../../core/state/staff_logic.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';
import 'admin/staff_books_screen.dart';
import 'admin/staff_reservations_screen.dart';
import 'admin/staff_seats_screen.dart';
import 'admin/staff_waitlist_screen.dart';
import 'admin/widgets/staff_live_states.dart';
import 'admin/widgets/staff_status_badge.dart';
import 'extend_time_screen.dart';
import 'staff_actions.dart';
import 'staff_scanner_screen.dart';

/// P-13 Staff Dashboard.
///
/// The staff home: a search field over today's seat bookings, four tappable
/// stat tiles, and the dispatch list with per-state actions.
class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen>
    with StaffClockMixin {
  static const _filters = ['All', 'Active', 'Urgent'];

  final _searchController = TextEditingController();
  String _queueFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Open seat bookings whose window touches today, plus any that ran out
  /// and were never released (they still hold the seat, whatever the day).
  List<AdminReservation> _today(List<AdminReservation> all) {
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return all.where((r) {
      if (!r.isSeat) return false;
      final s = staffReservationState(r, now);
      if (s == StaffResState.completed || s == StaffResState.cancelled) {
        return false;
      }
      if (s == StaffResState.expired) return true;
      final start = r.startAt ?? r.reservedAt;
      final end = r.endAt ?? r.dueAt ?? start;
      return end.isAfter(startOfDay) && start.isBefore(endOfDay);
    }).toList();
  }

  /// Expired first, then pending, then active by soonest end.
  int _rank(StaffResState s) => switch (s) {
        StaffResState.expired => 0,
        StaffResState.pending => 1,
        _ => 2,
      };

  List<AdminReservation> _dispatch(List<AdminReservation> all) {
    final q = _searchController.text.trim().toLowerCase();
    final list = _today(all).where((r) {
      final s = staffReservationState(r, now);
      final matchesQuery = q.isEmpty ||
          r.studentName.toLowerCase().contains(q) ||
          r.studentId.toLowerCase().contains(q) ||
          r.itemTitle.toLowerCase().contains(q) ||
          r.itemSubtitle.toLowerCase().contains(q);
      final matchesFilter = switch (_queueFilter) {
        'Active' => s == StaffResState.active,
        'Urgent' => s == StaffResState.pending || s == StaffResState.expired,
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();
    DateTime endOf(AdminReservation r) =>
        r.endAt ?? r.dueAt ?? r.startAt ?? r.reservedAt;
    list.sort((a, b) {
      final byRank = _rank(staffReservationState(a, now))
          .compareTo(_rank(staffReservationState(b, now)));
      return byRank != 0 ? byRank : endOf(a).compareTo(endOf(b));
    });
    return list;
  }

  void _goTab(int tab, Widget fallback) {
    if (!AppShell.switchTab(context, tab)) AppRoute.push(context, fallback);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final loading = staffLoading(state);
    final all = state.adminReservations;
    final failed = staffFailed(state) && all.isEmpty;
    final queue = _dispatch(all);
    final todayCount = _today(all).length;
    needsSecondTicks = queue.any((r) => staffShowsGrace(r, now));

    // Stat figures.
    final open = all.where((r) {
      final s = staffReservationState(r, now);
      return s == StaffResState.active || s == StaffResState.pending;
    }).toList();
    final createdToday = open
        .where((r) =>
            r.reservedAt.year == now.year &&
            r.reservedAt.month == now.month &&
            r.reservedAt.day == now.day)
        .length;
    final waiting = state.adminWaitlist
        .where((w) => w.entry.status == WaitlistStatus.waiting)
        .length;
    final offered = state.adminWaitlist
        .where((w) => w.entry.status == WaitlistStatus.offered)
        .length;
    var copiesFree = 0;
    var copiesTotal = 0;
    for (final b in state.adminBooks) {
      final total = b.totalCopies ?? b.copiesAvailable;
      copiesFree += b.copiesAvailable;
      copiesTotal += total < b.copiesAvailable ? b.copiesAvailable : total;
    }
    final catalogPct =
        copiesTotal == 0 ? 0.0 : (copiesFree / copiesTotal).clamp(0.0, 1.0);
    final seats = state.adminSeats;
    final seatsFree =
        seats.where((s) => s.status == SeatStatus.available).length;
    final seatPct = seats.isEmpty ? 0.0 : seatsFree / seats.length;

    // The staff shell already paints the aurora behind this tab.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: state.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.base,
                AppSpacing.base, AppNavInset.bottom),
            children: [
              // App-level cached-data banner (D-14).
              ConnectivityBanner(lastSyncedAt: state.lastSyncedAt),
              SurfaceCard(
                radius: AppRadii.xl,
                elevated: true,
                color: AppColors.surface,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Staff Dashboard',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.title(18, w: FontWeight.w800),
                          ),
                          Text(
                            'Library Control Hub',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(12.5,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Tooltip(
                      message: 'Scan a pass',
                      child: PressScale(
                        onTap: () =>
                            AppRoute.push(context, const StaffScannerScreen()),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: AppGradients.hero,
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            boxShadow: AppShadows.layered(AppColors.primary),
                          ),
                          child: Icon(Icons.qr_code_scanner_rounded,
                              size: 24, color: AppColors.textInverse),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search students, seats or IDs',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () =>
                              setState(() => _searchController.clear()),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              Row(
                children: [
                  Expanded(
                    child: _DashTile(
                      label: 'Reservations',
                      icon: Icons.confirmation_num_outlined,
                      color: AppColors.primary,
                      value: open.length,
                      word: 'active',
                      pill: '+$createdToday today',
                      pillColor: AppColors.primary,
                      onTap: () => _goTab(AppTab.staffBookings,
                          const StaffReservationsScreen()),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _DashTile(
                      label: 'Waitlist',
                      icon: Icons.hourglass_top_rounded,
                      color: AppColors.warning,
                      value: waiting,
                      word: 'queued',
                      pill: offered > 0 ? '$offered offered' : null,
                      pillColor: AppColors.warning,
                      onTap: () =>
                          AppRoute.push(context, const StaffWaitlistScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _DashTile(
                      label: 'Catalog',
                      icon: Icons.auto_stories_outlined,
                      color: AppColors.accent,
                      value: (catalogPct * 100).round(),
                      suffix: '%',
                      word: 'available',
                      meter: catalogPct,
                      onTap: () =>
                          _goTab(AppTab.staffCatalog, const StaffBooksScreen()),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _DashTile(
                      label: 'Seat Avail',
                      icon: Icons.event_seat_outlined,
                      color: AppColors.success,
                      value: (seatPct * 100).round(),
                      suffix: '%',
                      word: 'free',
                      meter: seatPct,
                      onTap: () =>
                          _goTab(AppTab.staffSeats, const StaffSeatsScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: Text('Queue Dispatch',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title(18, w: FontWeight.w800)),
                  ),
                  StatusPill(
                      label: '${queue.length} items',
                      color: AppColors.primary,
                      compact: true),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SegmentedTabs(
                options: _filters,
                selected: _queueFilter,
                onSelected: (value) => setState(() => _queueFilter = value),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.base),
              if (loading)
                const Column(
                  children: [
                    SkeletonCard(height: 100),
                    SizedBox(height: AppSpacing.md),
                    SkeletonCard(height: 100),
                  ],
                )
              else if (failed)
                ErrorState(
                  message: state.lastError?.message ??
                      'We could not load the dispatch queue.',
                  onRetry: state.refresh,
                )
              else if (queue.isEmpty)
                EmptyState(
                  icon: Icons.inbox_rounded,
                  title: todayCount == 0 ? 'All clear' : 'No matches',
                  message: todayCount == 0
                      ? 'No seat bookings need attention right now.'
                      : 'No bookings match this search or filter.',
                )
              else
                for (var i = 0; i < queue.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  StaggeredEntrance(
                    index: i,
                    child: _DispatchCard(
                        reservation: queue[i], index: i, now: now),
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }

  String _firstName(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? 'Staff' : trimmed.split(RegExp(r'\s+')).first;
  }

  String _dayPart(DateTime value) {
    if (value.hour < 12) return 'morning';
    if (value.hour < 17) return 'afternoon';
    return 'evening';
  }
}

/// A tappable stat tile: figure, word, and either a pill or a meter.
class _DashTile extends StatelessWidget {
  const _DashTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.word,
    required this.onTap,
    this.suffix = '',
    this.pill,
    this.pillColor,
    this.meter,
  });

  final String label;
  final IconData icon;
  final Color color;
  final int value;
  final String suffix;
  final String word;
  final String? pill;
  final Color? pillColor;
  final double? meter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label, $value$suffix $word',
      child: SurfaceCard(
        padding: const EdgeInsets.all(15),
        color: AppColors.surface,
        borderColor: AppColors.border,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label(12.5, w: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:
                        color.withValues(alpha: AppColors.isDark ? 0.20 : 0.10),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(icon, size: 17, color: color),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 6,
              children: [
                CountUp(
                  value: value,
                  suffix: suffix,
                  style: AppText.display(28, w: FontWeight.w800, color: color),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(word, style: AppText.label(12)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (meter != null)
              MeterBar(value: meter!, color: color)
            else if (pill != null)
              StatusPill(label: pill!, color: pillColor ?? color, compact: true)
            else
              // Keeps the tiles in a row the same height.
              const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}

class _DispatchCard extends StatelessWidget {
  const _DispatchCard(
      {required this.reservation, required this.index, required this.now});

  final AdminReservation reservation;
  final int index;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final s = staffReservationState(r, now);
    final color = staffStateColor(s);
    final badge = staffReservationStatusLabel(r, now).toUpperCase();

    final actions = switch (s) {
      StaffResState.active => [
          StaffMiniButton(
            label: 'Monitor',
            tone: ButtonTone.secondary,
            onPressed: () => showStaffReservationDetails(context, r, now: now),
          ),
          StaffMiniButton(
            label: 'Extend',
            onPressed: () =>
                AppRoute.push(context, ExtendTimeScreen(reservation: r)),
          ),
        ],
      StaffResState.pending => [
          StaffMiniButton(
            label: 'Notify',
            tone: ButtonTone.secondary,
            onPressed: () => staffNotifyReservation(context, r, now: now),
          ),
          StaffMiniButton(
            label: 'Check In',
            onPressed: () => staffCheckInAction(context, r),
          ),
        ],
      _ => [
          StaffMiniButton(
            label: 'Alert',
            tone: ButtonTone.secondary,
            onPressed: () => staffNotifyReservation(context, r, now: now),
          ),
          StaffMiniButton(
            label: 'Release Desk',
            tone: ButtonTone.danger,
            onPressed: () => staffReleaseAction(context, r),
          ),
        ],
    };

    return SurfaceCard(
      tint: color.withValues(alpha: 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StaffAvatar(name: r.studentName, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 3,
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
                            style: AppText.title(15, w: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 6),
                        StaffIndexChip(staffIndexLabel(index, pad: 3)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${r.itemTitle} · ${r.itemSubtitle}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(12.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StaffStatusBadge(
                        label: badge, tone: staffStateTone(s), compact: true),
                    const SizedBox(height: 4),
                    Text(
                      staffTimeNote(r, now),
                      textAlign: TextAlign.end,
                      style:
                          AppText.label(12, w: FontWeight.w700, color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: actions,
            ),
          ),
        ],
      ),
    );
  }
}
