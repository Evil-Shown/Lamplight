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
        book: books[0],
        reservedAt: now.subtract(const Duration(hours: 6)),
        pickupBy: now.add(const Duration(days: 5)),
        pickupLocation: 'Main Library',
        qrCode: 'LIB-BR-2026-045',
        status: ReservationStatus.ready,
      ),
      BookReservation(
        id: 'BR-2026-046',
        book: books[3],
        reservedAt: now.subtract(const Duration(days: 1)),
        pickupBy: now.add(const Duration(days: 2)),
        pickupLocation: 'Main Library',
        qrCode: 'LIB-BR-2026-046',
        status: ReservationStatus.active,
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
