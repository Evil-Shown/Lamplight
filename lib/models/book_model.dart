import 'package:cloud_firestore/cloud_firestore.dart';

class BookModel {
  final String id;
  final String title;
  final String author;
  final String isbn;
  final String category;
  final String description;
  final int availableCopies;
  final String shelfLocation;
  final String coverUrl;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.isbn,
    required this.category,
    required this.description,
    required this.availableCopies,
    required this.shelfLocation,
    required this.coverUrl,
  });

  factory BookModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BookModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      author: data['author'] as String? ?? '',
      isbn: data['isbn'] as String? ?? '',
      category: data['category'] as String? ?? '',
      description: data['description'] as String? ?? '',
      availableCopies: (data['availableCopies'] as num?)?.toInt() ?? 0,
      shelfLocation: data['shelfLocation'] as String? ?? '',
      coverUrl: data['coverUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'isbn': isbn,
      'category': category,
      'description': description,
      'availableCopies': availableCopies,
      'shelfLocation': shelfLocation,
      'coverUrl': coverUrl,
    };
  }
}
