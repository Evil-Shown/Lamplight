import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationModel {
  final String id;
  final String bookId;
  final String userId;
  final String bookTitle;
  final String pickupLocation;
  final DateTime reservedAt;
  final DateTime expiresAt;
  final String status;

  ReservationModel({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.bookTitle,
    required this.pickupLocation,
    required this.reservedAt,
    required this.expiresAt,
    required this.status,
  });

  factory ReservationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ReservationModel(
      id: doc.id,
      bookId: data['bookId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      bookTitle: data['bookTitle'] as String? ?? '',
      pickupLocation: data['pickupLocation'] as String? ?? '',
      reservedAt: (data['reservedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'userId': userId,
      'bookTitle': bookTitle,
      'pickupLocation': pickupLocation,
      'reservedAt': Timestamp.fromDate(reservedAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'status': status,
    };
  }
}
