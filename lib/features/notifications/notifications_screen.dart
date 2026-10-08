import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../models/models.dart';

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
    final unread = state.unreadNotifications;

    return AppScaffold(
      title: 'Notifications',
      body: notifications.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'Nothing new',
              message:
                  'Reservation updates and reminders will appear here.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
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
                          onPressed: state.markAllNotificationsRead,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 34),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Mark all as read',
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
                for (var i = 0; i < notifications.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  StaggeredEntrance(
                    index: i,
                    child: _NotificationCard(item: notifications[i]),
                  ),
                ],
              ],
            ),
    );
  }
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
    final state = AppScope.of(context);
    final isUnread = !state.isNotificationRead(item.id);

    return Semantics(
      label:
          '${item.title}. ${item.body}. ${_timestamp(item.timestamp)}.'
          '${isUnread ? ' Unread.' : ''}',
      button: true,
      child: SurfaceCard(
        padding: const EdgeInsets.all(14),
        tint: _color.withValues(alpha: 0.20),
        onTap: isUnread
            ? () => AppScope.read(context).markNotificationRead(item.id)
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(
              icon: item.icon ?? Icons.notifications_rounded,
              color: _color,
              background: _color.withValues(alpha: 0.10),
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
                      w: isUnread ? FontWeight.w700 : FontWeight.w600,
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
