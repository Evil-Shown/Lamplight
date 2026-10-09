import '../models/models.dart';

enum BookSort { title, author, newest, availability }

/// One page of catalogue results plus the cursor for the next one.
class BookPage {
  const BookPage({
    required this.books,
    this.cursor,
    this.hasMore = false,
  });

  final List<Book> books;

  /// Pass back as `startAfter` to fetch the next page; null at the end.
  final Object? cursor;
  final bool hasMore;

  static const empty = BookPage(books: []);
}

/// Lower-cased key used for the `titleLower` / `authorLower` prefix fields.
String searchKey(String s) => s.trim().toLowerCase();

/// Client-side match on a loaded page: substring on title, author, ISBN.
bool bookMatchesQuery(Book b, String query) {
  final q = searchKey(query);
  if (q.isEmpty) return true;
  return b.title.toLowerCase().contains(q) ||
      b.author.toLowerCase().contains(q) ||
      b.isbn.toLowerCase().contains(q);
}

int compareBooks(Book a, Book b, BookSort sort) {
  switch (sort) {
    case BookSort.title:
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    case BookSort.author:
      return a.author.toLowerCase().compareTo(b.author.toLowerCase());
    case BookSort.newest:
      final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    case BookSort.availability:
      final c = b.copiesAvailable.compareTo(a.copiesAvailable);
      return c != 0 ? c : a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }
}

/// Filters and sorts [books] in memory. Used for the substring fallback on a
/// loaded page and for demo/test data.
List<Book> filterAndSortBooks(
  Iterable<Book> books, {
  String query = '',
  String? subject,
  bool availableOnly = false,
  BookSort sort = BookSort.title,
}) {
  final out = books.where((b) {
    if (subject != null && subject.isNotEmpty && b.subject != subject) {
      return false;
    }
    if (availableOnly && b.copiesAvailable <= 0) return false;
    return bookMatchesQuery(b, query);
  }).toList()
    ..sort((a, b) => compareBooks(a, b, sort));
  return out;
}
