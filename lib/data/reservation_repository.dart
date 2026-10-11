import 'package:flutter/foundation.dart';

enum ReservationKind { book, seat }

enum ReservationStatus { active, cancelled }

/// Fine-grained lifecycle shown to the user on top of [ReservationStatus].
enum ReservationStage { confirmed, readyForPickup, waitingList, expired }

/// Unified reservation record covering both book holds and reading-room
/// seat bookings. Designed to map 1:1 onto a future API response.
@immutable
class ReservationRecord {
  const ReservationRecord({
    required this.id,
    required this.kind,
    required this.status,
    required this.title,
    required this.subtitle,
    required this.location,
    required this.reservedOn,
    required this.pickupBy,
    required this.qrPayload,
    this.timeRange,
    this.coverColor,
    this.stage = ReservationStage.confirmed,
  });

  final String id;
  final ReservationKind kind;
  final ReservationStatus status;
  final ReservationStage stage;
  final String title;
  final String subtitle;
  final String location;
  final DateTime reservedOn;
  final DateTime pickupBy;
  final String? timeRange;
  final int? coverColor;
  final String qrPayload;

  bool get isActive => status == ReservationStatus.active;
  ReservationRecord copyWith({ReservationStatus? status}) {
    return ReservationRecord(
      id: id,
      kind: kind,
      status: status ?? this.status,
      title: title,
      subtitle: subtitle,
      location: location,
      reservedOn: reservedOn,
      pickupBy: pickupBy,
      qrPayload: qrPayload,
      timeRange: timeRange,
      coverColor: coverColor,
      stage: stage,
    );
  }
}

/// Mock-backed reservation store. Replace the seed + mutation bodies with
/// API calls when the backend lands — screens only talk to this class.
class ReservationRepository extends ChangeNotifier {
  ReservationRepository._();

  static final ReservationRepository instance = ReservationRepository._();

  static final List<ReservationRecord> _records = _seed();

  static List<ReservationRecord> _seed() {
    final now = DateTime.now();
    return [
      ReservationRecord(
        id: 'BR-2026-045',
        kind: ReservationKind.book,
        status: ReservationStatus.active,
        title: 'Clean Code',
        subtitle: 'Robert C. Martin',
        location: 'Main Library',
        reservedOn: now.subtract(const Duration(days: 7)),
        pickupBy: now.add(const Duration(days: 2)),
        coverColor: 0xFF1B4F72,
        stage: ReservationStage.readyForPickup,
        qrPayload: 'BOOKCHECKIN|BR-2026-045|Clean Code|Main Library',
      ),
      ReservationRecord(
        id: 'BR-2026-046',
        kind: ReservationKind.book,
        status: ReservationStatus.active,
        title: 'Atomic Habits',
        subtitle: 'James Clear',
        location: 'Main Library',
        reservedOn: now.subtract(const Duration(days: 3)),
        pickupBy: now.add(const Duration(days: 4)),
        coverColor: 0xFF784212,
        qrPayload: 'BOOKCHECKIN|BR-2026-046|Atomic Habits|Main Library',
      ),
      ReservationRecord(
        id: 'BR-2026-047',
        kind: ReservationKind.book,
        status: ReservationStatus.active,
        title: 'Introduction to Algorithms',
        subtitle: 'Thomas H. Cormen',
        location: 'Main Library',
        reservedOn: now.subtract(const Duration(days: 2)),
        pickupBy: now.add(const Duration(days: 6)),
        coverColor: 0xFF6C3483,
        stage: ReservationStage.waitingList,
        qrPayload: 'BOOKCHECKIN|BR-2026-047|Introduction to Algorithms|Main Library',
      ),
      ReservationRecord(
        id: 'SR-2026-112',
        kind: ReservationKind.seat,
        status: ReservationStatus.active,
        title: 'Reading Room - F1',
        subtitle: 'Seat S12',
        location: 'Reading Room - Floor 1',
        reservedOn: now.subtract(const Duration(days: 1)),
        pickupBy: now.add(const Duration(hours: 20)),
        timeRange: '09:00 - 11:00 AM',
        stage: ReservationStage.confirmed,
        qrPayload: 'SEATCHECKIN|SR-2026-112|Reading Room F1|Seat S12',
      ),
    ];
  }

  List<ReservationRecord> get records => List.unmodifiable(_records);

  List<ReservationRecord> activeByKind(ReservationKind kind) => _records
      .where((r) => r.kind == kind && r.status == ReservationStatus.active)
      .toList();

  bool get hasActive => _records.any((r) => r.isActive);

  ReservationRecord? byId(String id) {
    for (final r in _records) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Cancels a reservation. Returns true when the record existed and was
  /// still active.
  bool cancel(String id) {
    final index = _records.indexWhere((r) => r.id == id);
    if (index == -1 || !_records[index].isActive) return false;
    _records[index] = _records[index].copyWith(status: ReservationStatus.cancelled);
    notifyListeners();
    return true;
  }
}
