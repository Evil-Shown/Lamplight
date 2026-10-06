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
  final int row;
  final int col;

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
  });

  final String id;
  final WaitlistType type;
  final String title;
  final String subtitle;
  final int position;
  final DateTime joinedAt;
  final int? estimatedWaitMinutes;
  final String? seatPreference;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.tone,
    this.icon,
  });

  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final BannerToneKind tone;
  final IconData? icon;
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
    required this.role,
    this.reservationsVisibleToStaffOnly = true,
  });

  final String name;
  final String studentId;
  final String email;
  final UserRole role;
  final bool reservationsVisibleToStaffOnly;

  String get firstName => name.split(' ').first;
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
