enum BookAvailability { available, onLoan, reserved }

enum SeatStatus { available, occupied, reserved }

enum SeatType { quiet, group, computer }

enum WaitlistType { book, seat }

enum NotificationChannel { push, email, sms }

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.subject,
    required this.isbn,
    required this.availability,
    required this.shelfLocation,
    this.dueDate,
    this.coverColor,
  });

  final String id;
  final String title;
  final String author;
  final String subject;
  final String isbn;
  final BookAvailability availability;
  final String shelfLocation;
  final DateTime? dueDate;
  final int? coverColor;
}

class Seat {
  const Seat({
    required this.id,
    required this.label,
    required this.floor,
    required this.section,
    required this.status,
    required this.hasPowerOutlet,
    required this.type,
    required this.distanceFromEntranceMeters,
    required this.row,
    required this.col,
  });

  final String id;
  final String label;
  final int floor;
  final String section;
  final SeatStatus status;
  final bool hasPowerOutlet;
  final SeatType type;
  final int distanceFromEntranceMeters;
  final int row;
  final int col;
}

class BookReservation {
  const BookReservation({
    required this.id,
    required this.book,
    required this.reservedAt,
    required this.pickupBy,
    required this.qrCode,
  });

  final String id;
  final Book book;
  final DateTime reservedAt;
  final DateTime pickupBy;
  final String qrCode;
}

class SeatBooking {
  const SeatBooking({
    required this.id,
    required this.seat,
    required this.startTime,
    required this.endTime,
    required this.qrCode,
    this.gracePeriodEndsAt,
  });

  final String id;
  final Seat seat;
  final DateTime startTime;
  final DateTime endTime;
  final String qrCode;
  final DateTime? gracePeriodEndsAt;
}

class WaitlistEntry {
  const WaitlistEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.position,
    required this.joinedAt,
    this.estimatedWait,
    this.gracePeriodEndsAt,
  });

  final String id;
  final WaitlistType type;
  final String title;
  final int position;
  final DateTime joinedAt;
  final Duration? estimatedWait;
  final DateTime? gracePeriodEndsAt;
}

class NotificationPreferences {
  const NotificationPreferences({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.smsEnabled = false,
    this.reminderBeforeStart = true,
    this.reminderBeforeExpiry = true,
    this.waitlistUpdates = true,
  });

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
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      reminderBeforeStart: reminderBeforeStart ?? this.reminderBeforeStart,
      reminderBeforeExpiry: reminderBeforeExpiry ?? this.reminderBeforeExpiry,
      waitlistUpdates: waitlistUpdates ?? this.waitlistUpdates,
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.studentId,
    required this.email,
    this.reservationsVisibleToStaffOnly = true,
    this.largeText = false,
    this.highContrast = false,
  });

  final String name;
  final String studentId;
  final String email;
  final bool reservationsVisibleToStaffOnly;
  final bool largeText;
  final bool highContrast;
}
