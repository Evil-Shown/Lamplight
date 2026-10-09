import 'package:flutter/widgets.dart';

enum BookAvailability { available, onLoan, waitlisted }

enum SeatStatus { available, limited, occupied }

enum SeatCategory { quietZone, collaborative, individualPod }

enum WaitlistType { book, seat }

enum NotificationChannel { push, email, sms }

enum UserRole { student, staff }

enum ReservationStatus { ready, active, expiringSoon, completed, cancelled }

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.subject,
    required this.isbn,
    required this.availability,
    required this.shelfLocation,
    required this.copiesAvailable,
    this.description = '',
    this.dueDate,
    this.coverColor,
    this.totalCopies,
    this.createdAt,
  });

  final String id;
  final String title;
  final String author;
  final String subject;
  final String isbn;
  final BookAvailability availability;
  final String shelfLocation;
  final int copiesAvailable;
  final String description;
  final DateTime? dueDate;
  final int? coverColor;

  /// Copies the library owns (staff admin). Null until the document has it.
  final int? totalCopies;

  /// When the catalogue entry was added (used by the "newest" sort).
  final DateTime? createdAt;
}

class Seat {
  const Seat({
    required this.id,
    required this.label,
    required this.floor,
    required this.section,
    required this.status,
    required this.category,
    required this.hasPowerOutlet,
    required this.hasMonitor,
    required this.nearWindow,
    this.standingDesk = false,
    required this.row,
    required this.col,
  });

  final String id;
  final String label;
  final int floor;
  final String section;
  final SeatStatus status;
  final SeatCategory category;
  final bool hasPowerOutlet;
  final bool hasMonitor;
  final bool nearWindow;
  final bool standingDesk;
  final int row;
  final int col;

  Seat copyWith({SeatStatus? status}) => Seat(
        id: id,
        label: label,
        floor: floor,
        section: section,
        status: status ?? this.status,
        category: category,
        hasPowerOutlet: hasPowerOutlet,
        hasMonitor: hasMonitor,
        nearWindow: nearWindow,
        standingDesk: standingDesk,
        row: row,
        col: col,
      );

  /// Short reasons shown on the recommendation card.
  List<String> get matchReasons {
    final reasons = <String>[];
    if (category == SeatCategory.quietZone) reasons.add('Quiet area');
    if (hasPowerOutlet) reasons.add('Power outlet');
    if (nearWindow) reasons.add('Near window');
    if (hasMonitor) reasons.add('Monitor');
    if (standingDesk) reasons.add('Standing desk');
    return reasons;
  }

  String get zoneLabel {
    switch (category) {
      case SeatCategory.quietZone:
        return 'Quiet Zone';
      case SeatCategory.collaborative:
        return 'Collaborative Space';
      case SeatCategory.individualPod:
        return 'Individual Pod';
    }
  }
}

class BookReservation {
  const BookReservation({
    required this.id,
    required this.book,
    required this.reservedAt,
    required this.pickupBy,
    required this.pickupLocation,
    required this.qrCode,
    this.status = ReservationStatus.ready,
  });

  final String id;
  final Book book;
  final DateTime reservedAt;
  final DateTime pickupBy;
  final String pickupLocation;
  final String qrCode;
  final ReservationStatus status;

  BookReservation copyWith({ReservationStatus? status}) => BookReservation(
        id: id,
        book: book,
        reservedAt: reservedAt,
        pickupBy: pickupBy,
        pickupLocation: pickupLocation,
        qrCode: qrCode,
        status: status ?? this.status,
      );
}

class SeatBooking {
  const SeatBooking({
    required this.id,
    required this.seat,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.qrCode,
    this.status = ReservationStatus.active,
    this.checkedInAt,
  });

  final String id;
  final Seat seat;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String qrCode;
  final ReservationStatus status;
  final DateTime? checkedInAt;

  SeatBooking copyWith({
    ReservationStatus? status,
    DateTime? checkedInAt,
  }) =>
      SeatBooking(
        id: id,
        seat: seat,
        date: date,
        startTime: startTime,
        endTime: endTime,
        qrCode: qrCode,
        status: status ?? this.status,
        checkedInAt: checkedInAt ?? this.checkedInAt,
      );
}

class WaitlistEntry {
  const WaitlistEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.position,
    required this.joinedAt,
    this.estimatedWaitMinutes,
    this.seatPreference,
    this.status = WaitlistStatus.waiting,
    this.offerExpiresAt,
    this.resourceId,
  });

  final String id;
  final WaitlistType type;
  final String title;
  final String subtitle;
  final int position;
  final DateTime joinedAt;
  final int? estimatedWaitMinutes;
  final String? seatPreference;
  final WaitlistStatus status;

  /// When a pending offer lapses (server-set). Null unless [status] is
  /// [WaitlistStatus.offered].
  final DateTime? offerExpiresAt;

  /// Book or seat document id this entry waits for, when the server set it.
  final String? resourceId;

  bool get isOffered => status == WaitlistStatus.offered;

  WaitlistEntry copyWith({WaitlistStatus? status, DateTime? offerExpiresAt}) =>
      WaitlistEntry(
        id: id,
        type: type,
        title: title,
        subtitle: subtitle,
        position: position,
        joinedAt: joinedAt,
        estimatedWaitMinutes: estimatedWaitMinutes,
        seatPreference: seatPreference,
        status: status ?? this.status,
        offerExpiresAt: offerExpiresAt ?? this.offerExpiresAt,
        resourceId: resourceId,
      );
}

enum WaitlistStatus { waiting, offered, accepted, declined, expired }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.tone,
    this.icon,
    this.type = NotificationType.info,
    this.targetId,
    this.readAt,
    this.offerExpiresAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final BannerToneKind tone;
  final IconData? icon;
  final NotificationType type;

  /// Id of the related reservation / booking / waitlist entry / loan.
  final String? targetId;

  /// Persisted read marker; null means unread.
  final DateTime? readAt;
  final DateTime? offerExpiresAt;

  bool get isRead => readAt != null;

  AppNotification copyWith({DateTime? readAt}) => AppNotification(
        id: id,
        title: title,
        body: body,
        timestamp: timestamp,
        tone: tone,
        icon: icon,
        type: type,
        targetId: targetId,
        readAt: readAt ?? this.readAt,
        offerExpiresAt: offerExpiresAt,
      );
}

/// What a notification refers to; drives tap navigation.
enum NotificationType { info, reservation, booking, offer, loan }

/// Parsed deep-link for a notification: open [type] item [id].
class NotificationTarget {
  const NotificationTarget(this.type, this.id);
  final NotificationType type;
  final String? id;

  bool get hasTarget => id != null && id!.isNotEmpty;

  /// Reads a notification document. Understands the server's `type`
  /// values (`waitlistOffer`, `seatReminder`, `dueSoon`, ...) and its
  /// `refPath` (e.g. `users/{uid}/waitlist/{id}`), plus the plain
  /// `type` + `targetId` form and legacy `reservationId` / `bookingId` /
  /// `entryId` / `loanId` fields.
  factory NotificationTarget.fromMap(Map<String, dynamic> m) {
    final raw = m['type'] as String?;
    var type = _serverTypes[raw] ??
        NotificationType.values.firstWhere(
          (t) => t.name == raw,
          orElse: () => NotificationType.info,
        );
    String? id = m['targetId'] as String?;
    if (id == null || id.isEmpty) {
      final ref = m['refPath'];
      if (ref is String && ref.isNotEmpty) {
        final parts = ref.split('/');
        id = parts.last;
        if (type == NotificationType.info && parts.length >= 2) {
          type = _collectionTypes[parts[parts.length - 2]] ?? type;
        }
      }
    }
    if (id == null || id.isEmpty) {
      const legacy = {
        'reservationId': NotificationType.reservation,
        'bookingId': NotificationType.booking,
        'entryId': NotificationType.offer,
        'loanId': NotificationType.loan,
      };
      for (final e in legacy.entries) {
        final v = m[e.key];
        if (v is String && v.isNotEmpty) {
          id = v;
          if (type == NotificationType.info) type = e.value;
          break;
        }
      }
    }
    return NotificationTarget(type, id);
  }

  static const _serverTypes = {
    'waitlistOffer': NotificationType.offer,
    'waitlistExpired': NotificationType.offer,
    'seatReminder': NotificationType.booking,
    'seatNoShow': NotificationType.booking,
    'pickupReminder': NotificationType.reservation,
    'reservationExpired': NotificationType.reservation,
    'reservationCancelled': NotificationType.reservation,
    'dueSoon': NotificationType.loan,
    'dueToday': NotificationType.loan,
    'fineAccrued': NotificationType.loan,
    'loanRenewed': NotificationType.loan,
  };

  static const _collectionTypes = {
    'reservations': NotificationType.reservation,
    'bookings': NotificationType.booking,
    'waitlist': NotificationType.offer,
    'loans': NotificationType.loan,
  };
}

/// Mirrors [BannerTone] in the widget layer without importing Flutter there.
enum BannerToneKind { info, success, warning, danger }

class NotificationPreferences {
  const NotificationPreferences({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.smsEnabled = true,
    this.reminderBeforeStart = true,
    this.reminderBeforeExpiry = true,
    this.waitlistUpdates = true,
    this.remindersEnabled = true,
    this.loanReminders = true,
  });

  /// Master switch for on-device reminders.
  final bool remindersEnabled;
  final bool loanReminders;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool reminderBeforeStart;
  final bool reminderBeforeExpiry;
  final bool waitlistUpdates;

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    bool? reminderBeforeStart,
    bool? reminderBeforeExpiry,
    bool? waitlistUpdates,
    bool? remindersEnabled,
    bool? loanReminders,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      reminderBeforeStart: reminderBeforeStart ?? this.reminderBeforeStart,
      reminderBeforeExpiry: reminderBeforeExpiry ?? this.reminderBeforeExpiry,
      waitlistUpdates: waitlistUpdates ?? this.waitlistUpdates,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      loanReminders: loanReminders ?? this.loanReminders,
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.studentId,
    required this.email,
    required this.role,
    this.reservationsVisibleToStaffOnly = true,
    this.phone = '',
    this.photoUrl,
    this.uid,
    this.prefs,
  });

  /// Reminder/notification choices saved on the profile, if any.
  final NotificationPreferences? prefs;
  final String? uid;
  final String phone;
  final String? photoUrl;
  final String name;
  final String studentId;
  final String email;
  final UserRole role;
  final bool reservationsVisibleToStaffOnly;

  String get firstName => name.split(' ').first;

  UserProfile copyWith({
    String? name,
    String? studentId,
    String? email,
    UserRole? role,
    bool? reservationsVisibleToStaffOnly,
    String? phone,
    String? photoUrl,
    String? uid,
    NotificationPreferences? prefs,
  }) =>
      UserProfile(
        name: name ?? this.name,
        studentId: studentId ?? this.studentId,
        email: email ?? this.email,
        role: role ?? this.role,
        reservationsVisibleToStaffOnly: reservationsVisibleToStaffOnly ??
            this.reservationsVisibleToStaffOnly,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        uid: uid ?? this.uid,
        prefs: prefs ?? this.prefs,
      );
}

// ------------------------------------------------------------------ loans

enum LoanStatus { active, overdue, returned }

/// A borrowed book (collection `loans`).
class Loan {
  const Loan({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.title,
    required this.author,
    required this.checkedOutAt,
    required this.dueAt,
    this.returnedAt,
    this.renewals = 0,
    this.fineAccrued = 0,
    this.status = LoanStatus.active,
    this.coverColor,
    this.fineCurrency = 'LKR',
  });

  final String fineCurrency;

  final String id;
  final String userId;
  final String bookId;
  final String title;
  final String author;
  final DateTime checkedOutAt;
  final DateTime dueAt;
  final DateTime? returnedAt;
  final int renewals;

  /// Fine so far, in [fineCurrency].
  final num fineAccrued;
  final LoanStatus status;
  final int? coverColor;

  bool get isReturned => returnedAt != null || status == LoanStatus.returned;

  /// Overdue by the clock, regardless of whether the server has flipped
  /// [status] yet.
  bool isOverdueAt(DateTime now) =>
      !isReturned && (status == LoanStatus.overdue || now.isAfter(dueAt));

  /// Whole days left (negative when overdue).
  int daysLeftAt(DateTime now) => dueAt.difference(now).inDays;
}

// ------------------------------------------------------------ staff admin

/// A book reservation or seat booking of any student (staff view).
class AdminReservation {
  const AdminReservation({
    required this.id,
    required this.ownerUid,
    required this.studentName,
    required this.studentId,
    required this.isSeat,
    required this.itemTitle,
    required this.itemSubtitle,
    required this.reservedAt,
    this.dueAt,
    required this.status,
    this.path = '',
  });

  final String id;
  final String ownerUid;
  final String studentName;
  final String studentId;
  final bool isSeat;
  final String itemTitle;
  final String itemSubtitle;
  final DateTime reservedAt;
  final DateTime? dueAt;
  final ReservationStatus status;

  /// Firestore document path.
  final String path;
}

/// A waitlist entry of any student (staff view).
class AdminWaitlistItem {
  const AdminWaitlistItem({
    required this.id,
    required this.ownerUid,
    required this.studentName,
    required this.studentId,
    required this.entry,
  });

  final String id;
  final String ownerUid;
  final String studentName;
  final String studentId;
  final WaitlistEntry entry;
}

/// Live numbers for the staff dashboard, computed from real documents.
class DashboardStats {
  const DashboardStats({
    this.activeSessions = 0,
    this.reservationsDueToday = 0,
    this.waitingCount = 0,
    this.seatsOccupied = 0,
    this.seatsTotal = 0,
  });

  final int activeSessions;
  final int reservationsDueToday;
  final int waitingCount;
  final int seatsOccupied;
  final int seatsTotal;

  /// 0..100.
  int get seatFillPercent =>
      seatsTotal == 0 ? 0 : (seatsOccupied * 100 / seatsTotal).round();
}

/// A row in the staff queue-dispatch list.
class QueueEntry {
  const QueueEntry({
    required this.id,
    required this.studentName,
    required this.studentId,
    required this.location,
    required this.requestedAt,
    required this.status,
  });

  final String id;
  final String studentName;
  final String studentId;
  final String location;
  final DateTime requestedAt;
  final QueueStatus status;
}

enum QueueStatus { active, pending, expired }

/// Per-floor occupancy shown on the home screen.
class FloorOccupancy {
  const FloorOccupancy({
    required this.name,
    required this.occupied,
    required this.capacity,
  });

  final String name;
  final int occupied;
  final int capacity;

  double get ratio => capacity == 0 ? 0 : occupied / capacity;
}

/// One of the six "system value proposition" cards.
class FeatureHighlight {
  const FeatureHighlight({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}
