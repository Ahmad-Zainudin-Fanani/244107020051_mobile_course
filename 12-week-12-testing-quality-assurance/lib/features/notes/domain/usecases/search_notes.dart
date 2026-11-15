import '../entities/note.dart';

/// Menyaring catatan berdasarkan judul.
///
/// Aturan ini tinggal di domain supaya bisa diuji tanpa widget dan dipakai
/// ulang oleh lapisan presentasi.
List<Note> searchNotesByTitle(List<Note> notes, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return notes;
  }
  return notes
      .where((note) => note.title.toLowerCase().contains(normalizedQuery))
      .toList();
}
