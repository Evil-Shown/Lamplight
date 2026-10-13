import 'package:flutter/material.dart';

import '../../models/models.dart';

/// Seed content shaped to match the prototype frames — the same books,
/// seat grid, staff queue, and student identity the mockups show.
class MockData {
  MockData._();

  // ---------------------------------------------------------------- profile

  static const student = UserProfile(
    name: 'Damitha Samarakoon',
    studentId: 'IT2023-CS-084',
    email: 'damitha.s@sliit.lk',
    role: UserRole.student,
  );

  static const staff = UserProfile(
    name: 'Jordan Lee',
    studentId: 'STF-2026-011',
    email: 'jordan.lee@sliit.lk',
    role: UserRole.staff,
  );

  // ------------------------------------------------------------------ books

  static final List<Book> books = [
    const Book(
      id: 'b1',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      subject: 'Software Engineering',
      isbn: '9780132350884',
      availability: BookAvailability.available,
      shelfLocation: 'B2-14',
      copiesAvailable: 3,
      coverColor: 0xFF7A2E2B,
      coverUrl:
          'https://m.media-amazon.com/images/I/41xShlnTZTL._SX376_BO1,204,203,200_.jpg',
      description:
          'A practical guide to writing clean, readable and maintainable '
          'software. Clean the code, design the principles, and practices '
          'that will help us write clean code with real-world systems.',
    ),
    const Book(
      id: 'b2',
      title: 'The Pragmatic Programmer',
      author: 'David Thomas, Andrew Hunt',
      subject: 'Software Engineering',
      isbn: '978-0135957059',
      availability: BookAvailability.available,
      shelfLocation: 'B1-08',
      copiesAvailable: 1,
      coverColor: 0xFF0E7490,
        coverUrl:
          'https://m.media-amazon.com/images/I/51A8l+FtCEL._SX379_BO1,204,203,200_.jpg',
      description:
          'The Pragmatic Programmer is a book about software development and '
          'is intended to be an easy read, not a reference manual.',
    ),
    const Book(
      id: 'b3',
      title: 'Code Complete',
      author: 'Steve McConnell',
      subject: 'Software Engineering',
      isbn: '978-0078022159',
      availability: BookAvailability.waitlisted,
      shelfLocation: 'B2-09',
      copiesAvailable: 0,
      coverColor: 0xFFB45309,
        coverUrl:
          'https://covers.openlibrary.org/b/isbn/9780078022159-L.jpg?default=false',
      description:
          'A thorough, well-organized guide to constructing maintainable '
          'software. Reading Code Complete will make you a better programmer.',
    ),
    const Book(
      id: 'b4',
      title: 'Atomic Habits',
      author: 'James Clear',
      subject: 'Self Development',
      isbn: '9780735211292',
      availability: BookAvailability.available,
      shelfLocation: 'C3-21',
      copiesAvailable: 5,
      coverColor: 0xFF9D174D,
        coverUrl:
          'https://covers.openlibrary.org/b/isbn/9780735211292-L.jpg?default=false',
      description:
          'Tiny changes, remarkable results. A proven framework for improving '
          'little by little, designing good habits, and mastering the art of '
          'habit building.',
    ),
    const Book(
      id: 'b5',
      title: 'Human-Computer Interaction',
      author: 'Alan Dix, Janet Beale',
      subject: 'Human-Computer Interaction',
      isbn: '9780321500883',
      availability: BookAvailability.onLoan,
      shelfLocation: 'B3-02',
      copiesAvailable: 0,
      coverColor: 0xFF5B21B6,
        coverUrl:
          'https://covers.openlibrary.org/b/isbn/9780321500883-L.jpg?default=false',
      description:
          'A comprehensive introduction to the design and evaluation of '
          'interactive systems, from the ergonomics of a single screen to '
          'the social context of large-scale systems.',
    ),
    const Book(
      id: 'b6',
      title: 'Introduction to Algorithms',
      author: 'Thomas H. Cormen',
      subject: 'Computer Science',
      isbn: '978-0262046305',
      availability: BookAvailability.available,
      shelfLocation: 'A1-03',
      copiesAvailable: 2,
      coverColor: 0xFF155E75,
        coverUrl:
          'https://covers.openlibrary.org/b/isbn/9780262046305-L.jpg?default=false',
      description:
          'A comprehensive introduction to the modern study of computer '
          'algorithms, covering everything from data structures to the '
          'complexity analysis of NP-complete problems.',
    ),
    const Book(
      id: 'b7',
      title: 'The Design of Everyday Things',
      author: 'Don Norman',
      subject: 'Design',
      isbn: '978-0465050659',
      availability: BookAvailability.available,
      shelfLocation: 'C1-11',
      copiesAvailable: 4,
      coverColor: 0xFF9A3412,
        coverUrl:
          'https://covers.openlibrary.org/b/isbn/9780465050659-L.jpg?default=false',
      description:
          'Design is a funny thing. Most people think it is primarily an '
          'aesthetic discipline, but it is really an integral part of '
          'everyday human existence.',
    ),
  ];

  static const popularSearches = [
    'Clean Code',
    'Software Engineering',
    'Human-Computer Interaction',
    'Data Structures',
  ];

  // ------------------------------------------------------------------ seats

  /// 4x4 grid of circular seat badges, matching the P-06 Seat Map frame.
  /// Row 0 = 1A..1D, and so on; 2C is the prototype's recommended seat.
  static final List<Seat> seats = _buildSeats();

  static List<Seat> _buildSeats() {
    const statuses = <List<SeatStatus>>[
      [
        SeatStatus.occupied,
        SeatStatus.limited,
        SeatStatus.occupied,
        SeatStatus.available,
      ],
      [
        SeatStatus.limited,
        SeatStatus.available,
        SeatStatus.available,
        SeatStatus.occupied,
      ],
      [
        SeatStatus.available,
        SeatStatus.occupied,
        SeatStatus.limited,
        SeatStatus.available,
      ],
      [
        SeatStatus.limited,
        SeatStatus.available,
        SeatStatus.available,
        SeatStatus.occupied,
      ],
    ];

    final seats = <Seat>[];
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 4; col++) {
        final label = '${row + 1}${String.fromCharCode(65 + col)}';
        // 2C is the researched recommendation: quiet, power, and a window.
        final featured = label == '2C';
        seats.add(
          Seat(
            id: 's${row}_$col',
            label: label,
            floor: 2,
            section: 'Quiet Wing',
            status: statuses[row][col],
            category: featured || col < 2
                ? SeatCategory.quietZone
                : (col == 2
                    ? SeatCategory.individualPod
                    : SeatCategory.collaborative),
            hasPowerOutlet: featured || col != 1,
            hasMonitor: col == 3,
            nearWindow: featured || col == 3,
            standingDesk: col == 0,
            row: row,
            col: col,
          ),
        );
      }
    }
    return seats;
  }

  /// Generates sample seats for a given floor so multi-floor browsing
  /// provides an interactive floor plan.
  static List<Seat> seatsForFloor(int floor) {
    if (floor == 2) return seats;
    final isFloor1 = floor == 1;
    final section = isFloor1 ? 'Collaborative Commons' : 'Silent Research Pods';
    final category =
        isFloor1 ? SeatCategory.collaborative : SeatCategory.individualPod;
    final list = <Seat>[];
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 4; col++) {
        final label = '${row + 1}${String.fromCharCode(65 + col)}';
        final status = (row * 4 + col) % 3 == 0
            ? SeatStatus.occupied
            : ((row + col) % 5 == 0
                ? SeatStatus.limited
                : SeatStatus.available);
        list.add(
          Seat(
            id: 'f${floor}_s${row}_$col',
            label: label,
            floor: floor,
            section: section,
            status: status,
            category: category,
            hasPowerOutlet: col % 2 == 0 || row == 1,
            hasMonitor: isFloor1 ? (col == 3) : (col >= 2),
            nearWindow: row == 0 || col == 3,
            standingDesk: row == 3 && col == 0,
            row: row,
            col: col,
          ),
        );
      }
    }
    return list;
  }

  static const floors = ['Floor 1', 'Floor 2', 'Floor 3'];

  static const floorOccupancy = <FloorOccupancy>[
    FloorOccupancy(name: 'Floor 1 · Corona', occupied: 56, capacity: 60),
    FloorOccupancy(name: 'Floor 2 · Egei', occupied: 42, capacity: 60),
    FloorOccupancy(name: 'Floor 3 · Staff', occupied: 18, capacity: 30),
  ];

  // ----------------------------------------------------------- reservations

  static List<BookReservation> buildReservations() {
    final now = DateTime.now();
    return [
      BookReservation(
        id: 'BR-2026-045',
        book: books[3],
        reservedAt: now.subtract(const Duration(hours: 6)),
        pickupBy: now.add(const Duration(days: 5)),
        pickupLocation: 'Main Library',
        qrCode: 'LIB-BR-2026-045',
        status: ReservationStatus.ready,
      ),
    ];
  }

  static List<SeatBooking> buildBookings() {
    final now = DateTime.now();
    return [
      SeatBooking(
        id: 'LIB-2026-4851',
        seat: seats.firstWhere((s) => s.label == '2C'),
        date: now,
        startTime: DateTime(now.year, now.month, now.day, 14),
        endTime: DateTime(now.year, now.month, now.day, 17),
        qrCode: 'LIB-2026-4851',
        status: ReservationStatus.active,
      ),
    ];
  }

  static List<WaitlistEntry> buildWaitlist() => [
        WaitlistEntry(
          id: 'w1',
          type: WaitlistType.seat,
          title: 'Seat 2C',
          subtitle: 'Floor 2 · Quiet Wing',
          position: 3,
          joinedAt: DateTime.now().subtract(const Duration(minutes: 12)),
          estimatedWaitMinutes: 45,
          seatPreference: 'Quiet Area + Power Outlet',
        ),
        WaitlistEntry(
          id: 'w2',
          type: WaitlistType.book,
          title: 'Design Patterns',
          subtitle: 'By Erich Gamma',
          position: 1,
          joinedAt: DateTime.now().subtract(const Duration(hours: 3)),
          estimatedWaitMinutes: 120,
          seatPreference: 'Any edition',
        ),
      ];

  static List<AppNotification> buildNotifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'n1',
        title: 'Book Reservation Confirmed',
        body: 'Clean Code has been reserved successfully.',
        timestamp: now.subtract(const Duration(hours: 2)),
        tone: BannerToneKind.success,
        icon: Icons.check_circle_outline_rounded,
      ),
      AppNotification(
        id: 'n2',
        title: 'Seat Reservation Reminder',
        body: 'Your seat reservation is coming up soon. '
            'Reading Room – Floor 1.',
        timestamp: now.subtract(const Duration(hours: 4)),
        tone: BannerToneKind.info,
        icon: Icons.schedule_rounded,
      ),
      AppNotification(
        id: 'n3',
        title: 'Waiting List Available',
        body: 'A seat has become available in the Reading Room. '
            'Join the waiting list now.',
        timestamp: now.subtract(const Duration(days: 2)),
        tone: BannerToneKind.warning,
        icon: Icons.error_outline_rounded,
      ),
      AppNotification(
        id: 'n4',
        title: 'Reservation Expiry Warning',
        body: 'Your book reservation will expire tomorrow.',
        timestamp: now.subtract(const Duration(days: 2, hours: 3)),
        tone: BannerToneKind.danger,
        icon: Icons.timer_outlined,
      ),
    ];
  }

  // ------------------------------------------------------------------ staff

  static List<QueueEntry> buildQueue() {
    final now = DateTime.now();
    return [
      QueueEntry(
        id: 'Q-0512',
        studentName: 'Alex M.',
        studentId: '#0512',
        location: 'Quiet Corner',
        requestedAt: now.subtract(const Duration(minutes: 18)),
        status: QueueStatus.active,
      ),
      QueueEntry(
        id: 'Q-0031',
        studentName: 'Jordan L.',
        studentId: '#0031',
        location: 'Team Room',
        requestedAt: now.subtract(const Duration(minutes: 41)),
        status: QueueStatus.pending,
      ),
      QueueEntry(
        id: 'Q-0520',
        studentName: 'Taylor S.',
        studentId: '#0520',
        location: 'Media Lab',
        requestedAt: now.subtract(const Duration(hours: 1, minutes: 12)),
        status: QueueStatus.expired,
      ),
    ];
  }

  /// Student seat bookings and book reservations as staff see them, placed
  /// relative to now: one active, one in its check-in grace, one upcoming, one
  /// overrun, a later booking that blocks extending the active seat past
  /// three hours, plus a pickup, a finished and a cancelled booking.
  static List<AdminReservation> buildAdminReservations() {
    final now = DateTime.now();
    Seat seat(String id) => seats.firstWhere((s) => s.id == id);
    AdminReservation booking(
      String id,
      String name,
      String studentId,
      String seatId, {
      required Duration start,
      required Duration end,
      Duration? checkedIn,
      ReservationStatus status = ReservationStatus.active,
    }) {
      final s = seat(seatId);
      return AdminReservation(
        id: id,
        ownerUid: 'u-$id',
        studentName: name,
        studentId: studentId,
        isSeat: true,
        itemTitle: 'Seat ${s.label}',
        itemSubtitle: '${s.section} · ${s.zoneLabel}',
        reservedAt: now.add(start),
        dueAt: now.add(end),
        status: status,
        path: 'users/u-$id/bookings/$id',
        resourceId: s.id,
        startAt: now.add(start),
        endAt: now.add(end),
        checkedInAt: checkedIn == null ? null : now.add(checkedIn),
      );
    }

    return [
      booking('B-1001', 'Nimal Perera', 'IT2023-0412', 's1_2',
          start: const Duration(minutes: -42),
          end: const Duration(hours: 1, minutes: 18),
          checkedIn: const Duration(minutes: -40)),
      booking('B-1002', 'Sara Fernando', 'IT2023-0777', 's2_3',
          start: const Duration(minutes: -6),
          end: const Duration(hours: 2, minutes: 54)),
      booking('B-1003', 'Kasun Silva', 'IT2022-0190', 's3_1',
          start: const Duration(hours: 2), end: const Duration(hours: 4)),
      booking('B-1004', 'Amaya Jayasinghe', 'IT2023-0268', 's0_3',
          start: const Duration(hours: -3),
          end: const Duration(minutes: -35),
          checkedIn: const Duration(hours: -2, minutes: -55)),
      booking('B-1005', 'Dilan Wickrama', 'IT2024-0033', 's1_2',
          start: const Duration(hours: 3), end: const Duration(hours: 5)),
      booking('B-1006', 'Tharushi Gomes', 'IT2023-0555', 's2_0',
          start: const Duration(hours: -5),
          end: const Duration(hours: -3),
          checkedIn: const Duration(hours: -5),
          status: ReservationStatus.completed),
      booking('B-1007', 'Ravindu Peris', 'IT2022-0721', 's3_2',
          start: const Duration(hours: 1),
          end: const Duration(hours: 3),
          status: ReservationStatus.cancelled),
      AdminReservation(
        id: 'BR-2001',
        ownerUid: 'u-BR-2001',
        studentName: 'Hiruni Rathnayake',
        studentId: 'IT2023-0309',
        isSeat: false,
        itemTitle: books[3].title,
        itemSubtitle: '${books[3].author} · ${books[3].shelfLocation}',
        reservedAt: now.subtract(const Duration(hours: 5)),
        dueAt: now.add(const Duration(days: 2)),
        status: ReservationStatus.ready,
        path: 'users/u-BR-2001/reservations/BR-2001',
        resourceId: books[3].id,
      ),
    ];
  }

  static const dashboardStats = {
    'reservations': 18,
    'waitlisted': 7,
    'onTime': 94,
    'seatFill': 72,
  };

  /// The student the staff scanner "reads" during verification.
  static const verificationStudent = UserProfile(
    name: 'Damitha Samarakoon',
    studentId: 'IT2023-CS-084',
    email: 'damitha.s@sliit.lk',
    role: UserRole.student,
  );

  // -------------------------------------------------------------- highlights

  static const featureHighlights = <FeatureHighlight>[
    FeatureHighlight(
      title: 'Unified Reservations',
      body: 'Seamless monitoring for both book collections and study room seats.',
    ),
    FeatureHighlight(
      title: 'Dynamic Metadata Tracker',
      body: 'Real-time updates of checkout status, location, strict due dates '
          'and pickup codes.',
    ),
    FeatureHighlight(
      title: 'One-Click Quick Cancellations',
      body: 'Secure cancellation flow with dynamic prompt validation prompts.',
    ),
    FeatureHighlight(
      title: 'Automated System Alerting',
      body: 'Instant reminders for upcoming slots, seat availability, and '
          'expiration times.',
    ),
    FeatureHighlight(
      title: 'Custom Preference Toggles',
      body: 'Select delivery channels instantly: SMS gateway, email servers, '
          'or in-app push.',
    ),
    FeatureHighlight(
      title: 'High-Performance Architecture',
      body: 'Minimal sub-second loading guarantees (INFRA01) and encrypted '
          'token sync (INFRA03).',
    ),
  ];
}
