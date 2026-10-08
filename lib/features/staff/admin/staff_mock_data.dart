import '../../../data/mock/mock_data.dart';
import '../../../models/models.dart';

/// Reservation types a staff member manages.
enum StaffReservationType { book, seat }

/// Lifecycle states for a reservation as seen from the staff desk.
enum StaffReservationStatus { active, pickedUp, expired, cancelled }

/// Waitlist states as seen from the staff desk.
enum StaffWaitlistStatus { waiting, notified, ready }

/// A reservation record shown on the staff admin dashboard.
class StaffReservation {
  const StaffReservation({
    required this.id,
    required this.studentName,
    required this.studentId,
    required this.type,
    required this.itemTitle,
    required this.itemSubtitle,
    required this.reservedAt,
    this.dueAt,
    required this.status,
  });

  final String id;
  final String studentName;
  final String studentId;
  final StaffReservationType type;

  /// Book title, or seat label such as "Seat A3".
  final String itemTitle;

  /// Author line for books, or "Floor 1 · Quiet Zone" for seats.
  final String itemSubtitle;

  final DateTime reservedAt;

  /// Pickup deadline for books, booking end time for seats.
  final DateTime? dueAt;
  final StaffReservationStatus status;
}

/// A waitlist queue entry shown on the staff admin dashboard.
class StaffWaitlistItem {
  const StaffWaitlistItem({
    required this.id,
    required this.studentName,
    required this.studentId,
    required this.type,
    required this.itemTitle,
    required this.position,
    required this.joinedAt,
    required this.status,
  });

  final String id;
  final String studentName;
  final String studentId;
  final WaitlistType type;
  final String itemTitle;
  final int position;
  final DateTime joinedAt;
  final StaffWaitlistStatus status;

  StaffWaitlistItem copyWith({int? position, StaffWaitlistStatus? status}) {
    return StaffWaitlistItem(
      id: id,
      studentName: studentName,
      studentId: studentId,
      type: type,
      itemTitle: itemTitle,
      position: position ?? this.position,
      joinedAt: joinedAt,
      status: status ?? this.status,
    );
  }
}

/// A catalog entry with total copy counts, staff-editable in the demo.
/// ([Book] already tracks available copies via [Book.copiesAvailable].)
class StaffBookEntry {
  const StaffBookEntry({
    required this.book,
    required this.totalCopies,
    required this.availableCopies,
  });

  final Book book;
  final int totalCopies;
  final int availableCopies;

  bool get allOnLoan => availableCopies == 0;

  StaffBookEntry copyWith({int? availableCopies}) {
    return StaffBookEntry(
      book: book,
      totalCopies: totalCopies,
      availableCopies: availableCopies ?? this.availableCopies,
    );
  }
}

/// Local mock data for the staff admin module. Lists are mutable so screens
/// can simulate desk actions (remove from waitlist, adjust copies, change
/// seat status) and keep the dashboard counters in sync. No backend involved.
class StaffMockData {
  static String get staffName => MockData.staff.name;
  static String get staffId => MockData.staff.studentId;
  static const staffRole = 'Library Desk Officer';

  static final _now = DateTime.now();

  // --- Reservations (read-only monitoring) ---------------------------------

  static final List<StaffReservation> reservations = [
    StaffReservation(
      id: 'SR-1001',
      studentName: 'Dilini Rajapaksa',
      studentId: 'STU-2024-1042',
      type: StaffReservationType.book,
      itemTitle: 'Clean Code',
      itemSubtitle: 'Robert C. Martin · Shelf B2-14',
      reservedAt: _now.subtract(const Duration(days: 1, hours: 2)),
      dueAt: _now.add(const Duration(hours: 6)),
      status: StaffReservationStatus.active,
    ),
    StaffReservation(
      id: 'SR-1002',
      studentName: 'Kasun Silva',
      studentId: 'STU-2023-0871',
      type: StaffReservationType.book,
      itemTitle: 'Database System Concepts',
      itemSubtitle: 'Silberschatz, Korth · Shelf B2-21',
      reservedAt: _now.subtract(const Duration(hours: 20)),
      dueAt: _now.add(const Duration(days: 2)),
      status: StaffReservationStatus.active,
    ),
    StaffReservation(
      id: 'SR-1003',
      studentName: 'Tharindu Jayawardena',
      studentId: 'STU-2024-0955',
      type: StaffReservationType.seat,
      itemTitle: 'Seat A3',
      itemSubtitle: 'Floor 1 · Quiet Zone',
      reservedAt: _now.subtract(const Duration(hours: 1)),
      dueAt: _now.add(const Duration(hours: 2, minutes: 30)),
      status: StaffReservationStatus.active,
    ),
    StaffReservation(
      id: 'SR-1004',
      studentName: 'Nuwan Wickramasinghe',
      studentId: 'STU-2023-0664',
      type: StaffReservationType.book,
      itemTitle: 'The Pragmatic Programmer',
      itemSubtitle: 'David Thomas, Andrew Hunt · Shelf B1-08',
      reservedAt: _now.subtract(const Duration(hours: 5)),
      dueAt: _now.add(const Duration(hours: 4)),
      status: StaffReservationStatus.active,
    ),
    StaffReservation(
      id: 'SR-1005',
      studentName: 'Hasini Bandara',
      studentId: 'STU-2024-1408',
      type: StaffReservationType.seat,
      itemTitle: 'Seat D4',
      itemSubtitle: 'Floor 2 · Collaborative Space',
      reservedAt: _now.subtract(const Duration(hours: 3)),
      dueAt: _now.add(const Duration(hours: 5)),
      status: StaffReservationStatus.active,
    ),
    StaffReservation(
      id: 'SR-1006',
      studentName: 'Hiruni Perera',
      studentId: 'STU-2024-1210',
      type: StaffReservationType.book,
      itemTitle: 'Code Complete',
      itemSubtitle: 'Steve McConnell · Shelf B2-09',
      reservedAt: _now.subtract(const Duration(days: 4)),
      dueAt: _now.subtract(const Duration(days: 1)),
      status: StaffReservationStatus.expired,
    ),
    StaffReservation(
      id: 'SR-1007',
      studentName: 'Sanduni Fernando',
      studentId: 'STU-2022-0450',
      type: StaffReservationType.seat,
      itemTitle: 'Seat C2',
      itemSubtitle: 'Floor 2 · Collaborative Space',
      reservedAt: _now.subtract(const Duration(hours: 8)),
      dueAt: _now.subtract(const Duration(hours: 1, minutes: 30)),
      status: StaffReservationStatus.expired,
    ),
    StaffReservation(
      id: 'SR-1008',
      studentName: 'Ishara Gunawardena',
      studentId: 'STU-2024-1333',
      type: StaffReservationType.book,
      itemTitle: 'Atomic Habits',
      itemSubtitle: 'James Clear · Shelf C3-21',
      reservedAt: _now.subtract(const Duration(days: 2)),
      dueAt: _now.subtract(const Duration(hours: 3)),
      status: StaffReservationStatus.pickedUp,
    ),
    StaffReservation(
      id: 'SR-1009',
      studentName: 'Malith Chandrasiri',
      studentId: 'STU-2022-0299',
      type: StaffReservationType.book,
      itemTitle: 'Operating System Concepts',
      itemSubtitle: 'Silberschatz, Galvin · Shelf B2-30',
      reservedAt: _now.subtract(const Duration(days: 1, hours: 6)),
      dueAt: _now.add(const Duration(days: 1)),
      status: StaffReservationStatus.cancelled,
    ),
  ];

  // --- Waitlist (staff can remove / update state) --------------------------

  static final List<StaffWaitlistItem> waitlist = [
    StaffWaitlistItem(
      id: 'SW-201',
      studentName: 'Pasindu Kumarasinghe',
      studentId: 'STU-2024-1502',
      type: WaitlistType.book,
      itemTitle: 'Code Complete',
      position: 1,
      joinedAt: _now.subtract(const Duration(hours: 2)),
      status: StaffWaitlistStatus.notified,
    ),
    StaffWaitlistItem(
      id: 'SW-202',
      studentName: 'Rashmi de Silva',
      studentId: 'STU-2023-0733',
      type: WaitlistType.book,
      itemTitle: 'The Pragmatic Programmer',
      position: 2,
      joinedAt: _now.subtract(const Duration(minutes: 45)),
      status: StaffWaitlistStatus.waiting,
    ),
    StaffWaitlistItem(
      id: 'SW-203',
      studentName: 'Charith Athukorala',
      studentId: 'STU-2024-1188',
      type: WaitlistType.seat,
      itemTitle: 'Quiet Zone · Floor 1',
      position: 1,
      joinedAt: _now.subtract(const Duration(minutes: 20)),
      status: StaffWaitlistStatus.ready,
    ),
    StaffWaitlistItem(
      id: 'SW-204',
      studentName: 'Vithushan Mahendran',
      studentId: 'STU-2022-0341',
      type: WaitlistType.seat,
      itemTitle: 'Collaborative Space · Floor 2',
      position: 3,
      joinedAt: _now.subtract(const Duration(hours: 3)),
      status: StaffWaitlistStatus.waiting,
    ),
    StaffWaitlistItem(
      id: 'SW-205',
      studentName: 'Shanika Alwis',
      studentId: 'STU-2023-0917',
      type: WaitlistType.book,
      itemTitle: 'Database System Concepts',
      position: 1,
      joinedAt: _now.subtract(const Duration(days: 1)),
      status: StaffWaitlistStatus.waiting,
    ),
  ];

  // --- Book catalog with copy counts (staff can adjust) --------------------

  static final List<StaffBookEntry> books = [
    StaffBookEntry(
      book: MockData.books[0],
      totalCopies: 5,
      availableCopies: MockData.books[0].copiesAvailable,
    ),
    StaffBookEntry(
      book: MockData.books[1],
      totalCopies: 4,
      availableCopies: MockData.books[1].copiesAvailable,
    ),
    StaffBookEntry(
      book: MockData.books[2],
      totalCopies: 3,
      availableCopies: MockData.books[2].copiesAvailable,
    ),
    const StaffBookEntry(
      book: Book(
        id: 'b6',
        title: 'Operating System Concepts',
        author: 'Silberschatz, Galvin, Gagne',
        subject: 'Computer Science',
        isbn: '978-1118063330',
        availability: BookAvailability.available,
        shelfLocation: 'B2-30',
        copiesAvailable: 3,
        coverColor: 0xFF1F4E5B,
      ),
      totalCopies: 4,
      availableCopies: 3,
    ),
    const StaffBookEntry(
      book: Book(
        id: 'b7',
        title: 'Human-Computer Interaction',
        author: 'Alan Dix, Janet Finlay',
        subject: 'Design & UX',
        isbn: '978-0130461094',
        availability: BookAvailability.available,
        shelfLocation: 'C1-12',
        copiesAvailable: 3,
        coverColor: 0xFF4A3E72,
      ),
      totalCopies: 3,
      availableCopies: 3,
    ),
  ];

  // --- Seats (copied from the shared mock so desk edits stay admin-side) ---

  static final List<Seat> seats = List<Seat>.from(MockData.seats);

  // --- Derived counters for the dashboard ----------------------------------

  static int get activeReservationCount => reservations
      .where((r) => r.status == StaffReservationStatus.active)
      .length;

  static int get expiredReservationCount => reservations
      .where((r) => r.status == StaffReservationStatus.expired)
      .length;

  static int get waitlistCount => waitlist.length;

  static int get availableSeatCount =>
      seats.where((s) => s.status == SeatStatus.available).length;
}
