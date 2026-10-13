import 'package:flutter/foundation.dart';

enum AppNotificationType {
  reservationConfirmed,
  seatReminder,
  waitlistAvailable,
  pickupDeadline,
  reservationCancelled,
}

/// In-app notification feed entry. Mirrors the shape of a future API
/// response — screens only talk to [NotificationRepository].
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final AppNotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Mock-backed notification store. Swap the seed + mutation bodies for API
/// calls when the backend lands.
class NotificationRepository extends ChangeNotifier {
  NotificationRepository._();

  static final NotificationRepository instance = NotificationRepository._();

  static final List<AppNotification> _items = _seed();

  static List<AppNotification> _seed() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'NT-001',
        type: AppNotificationType.seatReminder,
        title: 'Seat reservation starting soon',
        message: 'Your reading-room seat reservation starts in 30 minutes.',
        createdAt: now.subtract(const Duration(minutes: 12)),
      ),
      AppNotification(
        id: 'NT-002',
        type: AppNotificationType.pickupDeadline,
        title: 'Pickup deadline today',
        message:
            'Your reserved book must be collected before 5:00 PM today.',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: 'NT-003',
        type: AppNotificationType.waitlistAvailable,
        title: 'A copy is available for you',
        message:
            "A copy of 'Atomic Habits' is now available for you. Pick it up "
            'within 48 hours.',
        createdAt: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      AppNotification(
        id: 'NT-004',
        type: AppNotificationType.reservationConfirmed,
        title: 'Reservation confirmed',
        message:
            "Your reservation for 'Clean Code' has been confirmed. Pickup "
            'deadline is in 2 days.',
        createdAt: now.subtract(const Duration(days: 3)),
        isRead: true,
      ),
      AppNotification(
        id: 'NT-005',
        type: AppNotificationType.reservationCancelled,
        title: 'Reservation cancelled',
        message: 'Your reservation has been cancelled successfully.',
        createdAt: now.subtract(const Duration(days: 5)),
        isRead: true,
      ),
    ];
  }

  List<AppNotification> get items => List.unmodifiable(_items);

  int get unreadCount => _items.where((n) => !n.isRead).length;

  bool get hasUnread => unreadCount > 0;

  void markRead(String id) {
    final index = _items.indexWhere((n) => n.id == id);
    if (index == -1 || _items[index].isRead) return;
    _items[index] = _items[index].copyWith(isRead: true);
    notifyListeners();
  }

  void markAllRead() {
    if (!hasUnread) return;
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
    notifyListeners();
  }
}
