import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/feedback/app_feedback.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/navigation/app_route.dart';
import '../../models/models.dart';
import '../books/reservation_detail_screen.dart';
import '../qr/active_session_screen.dart';
import '../qr/qr_ticket_screen.dart';
import '../reservations/live_widgets.dart';
import '../waitlist/offer_screen.dart';

/// P-11 / screen-notifications.
///
/// One notifications feed: the most recent activity as a list of tinted
/// cards, each with an icon, a headline, and a relative timestamp. Read
/// state is client-side this cycle (D-07) — an 8px dot marks unread items
/// and "Mark all as read" clears them.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final notifications = state.notifications;
    final unread = state.unreadCount;

    final Widget body;
    if (syncFailed(state)) {
      body = syncErrorState(state);
    } else if (!state.isHydrated) {
      body = ListView(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        children: const [
          SkeletonCard(),
          SizedBox(height: AppSpacing.md),
          SkeletonCard(),
          SizedBox(height: AppSpacing.md),
          SkeletonCard(),
        ],
      );
    } else if (notifications.isEmpty) {
      // Scrollable so pull-to-refresh works on the empty state too.
      body = refreshable(
        state,
        LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: c.maxHeight,
              child: const EmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'Nothing new',
                message: 'Reservation updates and reminders will appear here.',
              ),
            ),
          ),
        ),
      );
    } else {
      body = refreshable(
        state,
        ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenMargin,
            AppSpacing.sm,
            AppSpacing.screenMargin,
            AppSpacing.xxl,
          ),
          children: [
            ConnectivityBanner(lastSyncedAt: state.lastSyncedAt),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: SectionLabel(
                      unread > 0
                          ? 'Recent activity · $unread unread'
                          : 'Recent activity',
                    ),
                  ),
                  if (unread > 0)
                    TextButton(
                      onPressed: () {
                        AppFeedback.success();
                        state.markAllRead();
                      },
                      style: TextButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(
                        'Mark all read',
                        style: AppText.label(
                          12.5,
                          w: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ..._grouped(notifications),
          ],
        ),
      );
    }

    return AppScaffold(title: 'Notifications', body: body);
  }
}

/// Marks [n] read and opens the item it points at. Loan notifications only
/// mark read (the loans screen is linked from Account).
void openNotification(BuildContext context, AppNotification n) {
  final state = AppScope.read(context);
  state.markRead(n.id);
  final target = state.notificationTarget(n);
  if (!target.hasTarget) return;
  final id = target.id!;
  switch (target.type) {
    case NotificationType.reservation:
      final r = state.reservations.where((r) => r.id == id).firstOrNull;
      if (r != null) {
        AppRoute.push(context, ReservationDetailScreen(reservation: r));
      }
    case NotificationType.booking:
      final b = state.bookings.where((b) => b.id == id).firstOrNull;
      if (b != null) {
        AppRoute.push(
          context,
          b.checkedInAt != null
              ? ActiveSessionScreen(booking: b)
              : QrTicketScreen(booking: b),
        );
      }
    case NotificationType.offer:
      AppRoute.push(context, OfferScreen(entryId: id));
    case NotificationType.loan:
    case NotificationType.info:
      break;
  }
}

/// Day headers ("Today", "Yesterday", date) with their cards, in feed order.
List<Widget> _grouped(List<AppNotification> items) {
  final widgets = <Widget>[];
  String? lastDay;
  var n = 0;
  for (final item in items) {
    final day = _dayLabel(item.timestamp);
    if (day != lastDay) {
      lastDay = day;
      widgets.add(Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xs,
          top: widgets.isEmpty ? 0 : AppSpacing.base,
          bottom: AppSpacing.sm,
        ),
        child: Text(
          day.toUpperCase(),
          style: AppText.overline(11, color: AppColors.textFaint),
        ),
      ));
    }
    widgets.add(Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: StaggeredEntrance(
        index: n++,
        child: _NotificationCard(item: item),
      ),
    ));
  }
  return widgets;
}

String _dayLabel(DateTime t) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(t.year, t.month, t.day);
  final diff = today.difference(d).inDays;
  if (diff <= 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return DateFormat('EEE, MMM d').format(t);
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final AppNotification item;

  Color get _color => switch (item.tone) {
        BannerToneKind.success => AppColors.success,
        BannerToneKind.info => AppColors.primary,
        BannerToneKind.warning => AppColors.warning,
        BannerToneKind.danger => AppColors.error,
      };

  String _timestamp(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    return DateFormat('MMM d, yyyy · h:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !item.isRead;

    return Semantics(
      label: '${item.title}. ${item.body}. ${_timestamp(item.timestamp)}.'
          '${isUnread ? ' Unread.' : ''}',
      button: true,
      child: SurfaceCard(
        padding: const EdgeInsets.all(14),
        tint: isUnread ? _color.withValues(alpha: 0.28) : null,
        borderColor: isUnread ? _color.withValues(alpha: 0.45) : null,
        onTap: () => openNotification(context, item),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(
              icon: item.icon ?? Icons.notifications_rounded,
              color: _color,
              background: _color.withValues(alpha: isUnread ? 0.16 : 0.08),
              size: 40,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppText.title(
                      14.5,
                      w: isUnread ? FontWeight.w800 : FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: AppText.body(
                      13,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _timestamp(item.timestamp),
                    style: AppText.body(11.5, color: AppColors.textFaint),
                  ),
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: 8),
              // The unread indicator — never colour-only, the Semantics
              // label above carries the "Unread" word for screen readers.
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
