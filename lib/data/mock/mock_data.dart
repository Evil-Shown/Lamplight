import '../../models/models.dart';

class MockData {
  static final books = [
    const Book(
      id: 'b1',
      title: 'Introduction to Algorithms',
      author: 'Cormen, Leiserson, Rivest',
      subject: 'Computer Science',
      isbn: '978-0262046305',
      availability: BookAvailability.available,
      shelfLocation: 'Floor 2 · CS-104',
      coverColor: 0xFF0F3D2E,
    ),
    Book(
      id: 'b2',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      subject: 'Software Engineering',
      isbn: '978-0132350884',
      availability: BookAvailability.onLoan,
      shelfLocation: 'Floor 2 · SE-212',
      dueDate: DateTime.now().add(const Duration(days: 5)),
      coverColor: 0xFF1B4F72,
    ),
    const Book(
      id: 'b3',
      title: 'Design of Everyday Things',
      author: 'Don Norman',
      subject: 'Design & UX',
      isbn: '978-0465050659',
      availability: BookAvailability.reserved,
      shelfLocation: 'Floor 1 · DES-087',
      coverColor: 0xFF6C3483,
    ),
    const Book(
      id: 'b4',
      title: 'Database System Concepts',
      author: 'Silberschatz, Korth',
      subject: 'Databases',
      isbn: '978-0078022159',
      availability: BookAvailability.available,
      shelfLocation: 'Floor 2 · DB-331',
      coverColor: 0xFF922B21,
    ),
    Book(
      id: 'b5',
      title: 'The Pragmatic Programmer',
      author: 'Hunt & Thomas',
      subject: 'Software Engineering',
      isbn: '978-0135957059',
      availability: BookAvailability.onLoan,
      shelfLocation: 'Floor 2 · SE-198',
      dueDate: DateTime.now().add(const Duration(days: 12)),
      coverColor: 0xFF784212,
    ),
  ];

  static final seats = [
  for (var row = 0; row < 4; row++)
    for (var col = 0; col < 6; col++)
      Seat(
        id: 's${row}_$col',
        label: '${String.fromCharCode(65 + row)}${col + 1}',
        floor: row < 2 ? 1 : 2,
        section: row < 2 ? 'Quiet Zone' : 'Group Study',
        status: _seatStatus(row, col),
        hasPowerOutlet: col % 2 == 0,
        type: row < 2 ? SeatType.quiet : SeatType.group,
        distanceFromEntranceMeters: 15 + row * 8 + col * 3,
        row: row,
        col: col,
      ),
  ];

  static SeatStatus _seatStatus(int row, int col) {
    if ((row + col) % 5 == 0) return SeatStatus.occupied;
    if ((row + col) % 7 == 0) return SeatStatus.reserved;
    return SeatStatus.available;
  }

  static final activeReservations = [
    BookReservation(
      id: 'r1',
      book: books[2],
      reservedAt: DateTime.now().subtract(const Duration(hours: 2)),
      pickupBy: DateTime.now().add(const Duration(days: 2)),
      qrCode: 'BOOK-R1-8F3A',
    ),
  ];

  static final activeBookings = [
    SeatBooking(
      id: 'sb1',
      seat: seats.firstWhere((s) => s.label == 'A1'),
      startTime: DateTime.now().subtract(const Duration(minutes: 10)),
      endTime: DateTime.now().add(const Duration(hours: 2)),
      qrCode: 'SEAT-SB1-2C9D',
      gracePeriodEndsAt: DateTime.now().add(const Duration(minutes: 5)),
    ),
  ];

  static final waitlistEntries = [
    WaitlistEntry(
      id: 'w1',
      type: WaitlistType.seat,
      title: 'Quiet Zone · Floor 1',
      position: 2,
      joinedAt: DateTime.now().subtract(const Duration(minutes: 25)),
      estimatedWait: const Duration(minutes: 40),
    ),
    WaitlistEntry(
      id: 'w2',
      type: WaitlistType.book,
      title: 'Clean Code',
      position: 1,
      joinedAt: DateTime.now().subtract(const Duration(hours: 1)),
      gracePeriodEndsAt: DateTime.now().add(const Duration(minutes: 18)),
    ),
  ];

  static const userProfile = UserProfile(
    name: 'Alex Student',
    studentId: 'STU-2024-1847',
    email: 'alex.student@university.edu',
    reservationsVisibleToStaffOnly: true,
  );
}
